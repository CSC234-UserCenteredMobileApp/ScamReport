import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import 'app_lock_providers.dart';
import 'widgets/pin_dots.dart';
import 'widgets/pin_pad.dart';

/// Single-entry PIN check used to re-authenticate before sensitive settings
/// changes (e.g. turning the lock off). Reports `true` once the PIN verifies.
class PinVerifyView extends ConsumerStatefulWidget {
  const PinVerifyView({super.key, required this.onVerified, this.heading});

  final VoidCallback onVerified;
  final String? heading;

  @override
  ConsumerState<PinVerifyView> createState() => _PinVerifyViewState();
}

class _PinVerifyViewState extends ConsumerState<PinVerifyView> {
  String _entry = '';
  bool _wrong = false;
  bool _checking = false;

  void _onDigit(String digit) {
    if (_checking || _entry.length >= 6) return;
    setState(() {
      _entry += digit;
      _wrong = false;
    });
    if (_entry.length == 6) _verify();
  }

  void _onBackspace() {
    if (_entry.isEmpty) return;
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  Future<void> _verify() async {
    setState(() => _checking = true);
    final ok = await ref
        .read(appLockControllerProvider.notifier)
        .verifyPinValue(_entry);
    if (!mounted) return;
    setState(() {
      _entry = '';
      _wrong = !ok;
      _checking = false;
    });
    if (ok) widget.onVerified();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.heading ?? l10n.appLockEnterPinPrompt,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          PinDots(filled: _entry.length, error: _wrong),
          const SizedBox(height: 12),
          SizedBox(
            height: 20,
            child: _wrong
                ? Text(
                    l10n.appLockWrongPin,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.error),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          PinPad(
            enabled: !_checking,
            onDigit: _onDigit,
            onBackspace: _onBackspace,
          ),
        ],
      ),
    );
  }
}

/// Shows [PinVerifyView] in a modal sheet; resolves true once the PIN verifies,
/// or null if dismissed.
Future<bool?> showPinVerifySheet(BuildContext context, {String? heading}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: PinVerifyView(
        heading: heading,
        onVerified: () => Navigator.of(sheetContext).pop(true),
      ),
    ),
  );
}
