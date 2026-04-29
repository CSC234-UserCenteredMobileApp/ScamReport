part of 'home_screen.dart';

/// Format DateTime as MM-dd without external package.
String _formatMonthDay(DateTime dt) {
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$m-$d';
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final RecentReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipBg = theme.colorScheme.surfaceContainerHighest;
    final chipFg = theme.colorScheme.onSurfaceVariant;

    return Card(
      child: InkWell(
        onTap: () => context.push('/report-detail/${report.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(report.scamTypeLabelEn),
                    backgroundColor: chipBg,
                    labelStyle: theme.textTheme.labelSmall?.copyWith(
                      color: chipFg,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 0),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    _formatMonthDay(report.verifiedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                report.title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                report.excerpt,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${report.reportCount} reports',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
