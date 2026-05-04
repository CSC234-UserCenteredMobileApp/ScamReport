import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';

class VerdictPill extends StatelessWidget {
  const VerdictPill({super.key, required this.verdict});

  final String verdict; // 'scam' | 'suspicious' | 'safe' | 'unknown'

  static const _icons = {
    'scam': Icons.warning_rounded,
    'suspicious': Icons.help_outline,
    'safe': Icons.check_circle,
    'unknown': Icons.remove_circle_outline,
  };

  VerdictColors _colors(BuildContext context) {
    final palette = Theme.of(context).extension<VerdictPalette>()!;
    return switch (verdict) {
      'scam' => palette.scam,
      'suspicious' => palette.suspicious,
      'safe' => palette.safe,
      _ => palette.unknown,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors(context);
    final icon = _icons[verdict] ?? Icons.remove_circle_outline;

    return Container(
      width: double.infinity,
      color: colors.bg,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: colors.fg),
          const SizedBox(height: 16),
          Text(
            _label(context),
            style: Theme.of(context)
                .textTheme
                .headlineLarge
                ?.copyWith(color: colors.fg, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _label(BuildContext context) {
    final l = context.l10n;
    return switch (verdict) {
      'scam' => l.verdictScam,
      'suspicious' => l.verdictSuspicious,
      'safe' => l.verdictSafe,
      _ => l.verdictUnknown,
    };
  }
}
