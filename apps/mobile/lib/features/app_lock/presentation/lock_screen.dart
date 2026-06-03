import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../domain/app_lock_config.dart';
import '../domain/app_lock_runtime.dart';
import 'app_lock_providers.dart';
import 'widgets/pin_dots.dart';
import 'widgets/pin_pad.dart';

/// Full-screen unlock UI shown by [AppLockGate] while the app is locked.
/// Auto-prompts biometric on mount (when enabled), then falls back to the PIN.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _entry = '';
  bool _wrong = false;
  bool _autoBiometricTried = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAutoBiometric();
      if (_lockoutRemaining() > Duration.zero) _startTicker();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  LockoutState get _lockout =>
      ref.read(appLockControllerProvider).valueOrNull?.lockout ??
      LockoutState.none;

  Duration _lockoutRemaining() => _lockout.remainingAt(DateTime.now());

  bool get _lockedOut => _lockoutRemaining() > Duration.zero;

  Future<void> _maybeAutoBiometric() async {
    if (_autoBiometricTried) return;
    final rt = ref.read(appLockControllerProvider).valueOrNull;
    if (rt == null || !rt.config.biometricEnabled || _lockedOut) return;
    _autoBiometricTried = true;
    await _runBiometric();
  }

  Future<void> _runBiometric() async {
    final reason = context.l10n.appLockBiometricReason;
    await ref.read(appLockControllerProvider.notifier).tryBiometric(reason);
    // On success the gate swaps us out; on failure the user falls back to PIN.
  }

  void _onDigit(String digit) {
    if (_lockedOut || _entry.length >= 6) return;
    setState(() {
      _entry += digit;
      _wrong = false;
    });
    if (_entry.length == 6) _submit();
  }

  void _onBackspace() {
    if (_entry.isEmpty) return;
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  Future<void> _submit() async {
    final outcome =
        await ref.read(appLockControllerProvider.notifier).submitPin(_entry);
    if (!mounted) return;
    setState(() {
      _entry = '';
      _wrong = outcome == UnlockOutcome.wrongPin;
    });
    if (outcome == UnlockOutcome.lockedOut) _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_lockedOut) {
        timer.cancel();
        _ticker = null;
      }
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final rt = ref.watch(appLockControllerProvider).valueOrNull;

    if (rt == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final remaining = _lockoutRemaining();
    final lockedOut = remaining > Duration.zero;

    final String? message;
    if (lockedOut) {
      message = l10n.appLockLockedOut(remaining.inSeconds + 1);
    } else if (_wrong) {
      message = l10n.appLockWrongPin;
    } else {
      message = null;
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 48, color: cs.primary),
              const SizedBox(height: 16),
              Text(
                l10n.appLockLockedHeading,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.appLockEnterPinPrompt,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              PinDots(filled: _entry.length, error: _wrong),
              const SizedBox(height: 16),
              SizedBox(
                height: 24,
                child: message == null
                    ? null
                    : Text(
                        message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.error),
                      ),
              ),
              const SizedBox(height: 16),
              PinPad(
                enabled: !lockedOut,
                onDigit: _onDigit,
                onBackspace: _onBackspace,
                showBiometric: rt.config.biometricEnabled,
                onBiometric: _runBiometric,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
