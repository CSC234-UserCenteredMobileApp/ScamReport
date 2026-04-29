import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../../features/home/domain/recent_alert.dart';
import '../../l10n/l10n.dart';

class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.alert});

  final RecentAlert alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verdict = Theme.of(context).extension<VerdictPalette>()!;

    final Color iconBg;
    final Color iconFg;
    final IconData iconData;
    final String chipLabel;

    switch (alert.category) {
      case AlertCategory.fraudAlert:
        iconBg = verdict.scam.bg;
        iconFg = verdict.scam.fg;
        iconData = Icons.warning_amber_outlined;
        chipLabel = context.l10n.categoryFraudAlert;
      case AlertCategory.tips:
        iconBg = verdict.safe.bg;
        iconFg = verdict.safe.fg;
        iconData = Icons.shield_outlined;
        chipLabel = context.l10n.categoryTips;
      case AlertCategory.platformUpdate:
        iconBg = verdict.unknown.bg;
        iconFg = verdict.unknown.fg;
        iconData = Icons.info_outline;
        chipLabel = context.l10n.categoryPlatformUpdate;
    }

    final dateStr = _formatDate(alert.publishedAt);

    return Card(
      child: InkWell(
        onTap: () => context.push('/announcement-detail/${alert.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconFg, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Chip(
                      label: Text(chipLabel),
                      backgroundColor: iconBg,
                      labelStyle: theme.textTheme.labelSmall?.copyWith(
                        color: iconFg,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 0),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Format DateTime as yyyy-MM-dd without external package.
String _formatDate(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
