import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';

/// Numeric keypad for PIN entry. Buttons carry `ValueKey('pinpad-<digit>')`
/// and `ValueKey('pinpad-back')` for deterministic widget testing.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
    this.showBiometric = false,
    this.onBiometric,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;
  final bool showBiometric;
  final VoidCallback? onBiometric;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (final d in row) _DigitKey(d, enabled, onDigit)],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LeadingKey(
              showBiometric: showBiometric,
              enabled: enabled,
              onBiometric: onBiometric,
            ),
            _DigitKey('0', enabled, onDigit),
            _ActionKey(
              keyValue: 'pinpad-back',
              icon: Icons.backspace_outlined,
              semanticLabel: context.l10n.appLockDeleteKey,
              onTap: enabled ? onBackspace : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _DigitKey extends StatelessWidget {
  const _DigitKey(this.digit, this.enabled, this.onDigit);

  final String digit;
  final bool enabled;
  final ValueChanged<String> onDigit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      key: ValueKey('pinpad-$digit'),
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Material(
          color: cs.surfaceContainerHighest,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? () => onDigit(digit) : null,
            child: Center(
              child: Text(
                digit,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionKey extends StatelessWidget {
  const _ActionKey({
    required this.keyValue,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final String keyValue;
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      key: ValueKey(keyValue),
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Semantics(
          button: true,
          label: semanticLabel,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Icon(icon, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

/// Bottom-left key: either a biometric shortcut or an empty spacer.
class _LeadingKey extends StatelessWidget {
  const _LeadingKey({
    required this.showBiometric,
    required this.enabled,
    required this.onBiometric,
  });

  final bool showBiometric;
  final bool enabled;
  final VoidCallback? onBiometric;

  @override
  Widget build(BuildContext context) {
    if (!showBiometric) {
      return const SizedBox(width: 88, height: 88);
    }
    return _ActionKey(
      keyValue: 'pinpad-biometric',
      icon: Icons.fingerprint,
      semanticLabel: context.l10n.appLockUseBiometricButton,
      onTap: enabled ? onBiometric : null,
    );
  }
}
