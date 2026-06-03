import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import 'widgets/pin_dots.dart';
import 'widgets/pin_pad.dart';

/// Two-step PIN chooser: enter a 6-digit PIN, then re-enter to confirm.
/// Calls [onComplete] with the chosen PIN once both entries match.
class PinSetupView extends StatefulWidget {
  const PinSetupView({super.key, required this.onComplete});

  final ValueChanged<String> onComplete;

  @override
  State<PinSetupView> createState() => _PinSetupViewState();
}

enum _Step { enter, confirm }

class _PinSetupViewState extends State<PinSetupView> {
  _Step _step = _Step.enter;
  String _first = '';
  String _entry = '';
  bool _mismatch = false;

  void _onDigit(String digit) {
    if (_entry.length >= 6) return;
    setState(() {
      _entry += digit;
      _mismatch = false;
    });
    if (_entry.length == 6) _advance();
  }

  void _onBackspace() {
    if (_entry.isEmpty) return;
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  void _advance() {
    if (_step == _Step.enter) {
      setState(() {
        _first = _entry;
        _entry = '';
        _step = _Step.confirm;
      });
      return;
    }
    if (_entry == _first) {
      widget.onComplete(_first);
    } else {
      setState(() {
        _step = _Step.enter;
        _first = '';
        _entry = '';
        _mismatch = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final heading = _step == _Step.enter
        ? l10n.appLockSetupHeading
        : l10n.appLockConfirmHeading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(heading, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            l10n.appLockSetupSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          PinDots(filled: _entry.length, error: _mismatch),
          const SizedBox(height: 12),
          SizedBox(
            height: 20,
            child: _mismatch
                ? Text(
                    l10n.appLockPinMismatch,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.error),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          PinPad(onDigit: _onDigit, onBackspace: _onBackspace),
        ],
      ),
    );
  }
}

/// Opens [PinSetupView] in a modal sheet and resolves with the chosen PIN, or
/// null if the user dismisses it.
Future<String?> showPinSetupSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: PinSetupView(
        onComplete: (pin) => Navigator.of(sheetContext).pop(pin),
      ),
    ),
  );
}
