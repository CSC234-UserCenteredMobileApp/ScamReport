import 'package:flutter/material.dart';

import '../../features/home/domain/home_stats.dart';
import '../../l10n/l10n.dart';

class StatCardRow extends StatelessWidget {
  const StatCardRow({super.key, required this.stats});

  final HomeStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: StatCard(
            value: _formatNumber(stats.verifiedTotal),
            label: context.l10n.statVerifiedReports,
            valueColor: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatCard(
            value: '+${stats.newThisWeek}',
            label: context.l10n.statNewThisWeek,
            valueColor: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatCard(
            value: Localizations.localeOf(context).languageCode == 'th'
                ? stats.topScamTypeLabelTh
                : stats.topScamTypeLabelEn,
            label: context.l10n.statTopScamType,
            valueColor: theme.colorScheme.onSurface,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.valueColor,
    this.maxLines = 1,
  });

  final String value;
  final String label;
  final Color valueColor;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formats an integer with comma thousands separators (e.g. 2184 → "2,184").
/// Avoids pulling in the `intl` package for a single call.
String _formatNumber(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final pos = s.length - i - 1;
    if (i > 0 && i % 3 == 0) buf.write(',');
    buf.write(s[pos]);
  }
  return buf.toString().split('').reversed.join();
}

class StatCardRowSkeleton extends StatelessWidget {
  const StatCardRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _SkeletonBox(height: 88)),
        SizedBox(width: 8),
        Expanded(child: _SkeletonBox(height: 88)),
        SizedBox(width: 8),
        Expanded(child: _SkeletonBox(height: 88)),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
    );
  }
}
