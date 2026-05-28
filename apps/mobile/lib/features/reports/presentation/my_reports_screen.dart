import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/filter_chip_bar.dart';
import '../../../l10n/l10n.dart';
import '../domain/my_report.dart';
import 'my_reports_providers.dart';

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final allAsync = ref.watch(myReportsProvider);
    final filter = ref.watch(myReportsFilterProvider);
    final filtered = ref.watch(filteredMyReportsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(l10n.myReportsTitle),
        centerTitle: true,
      ),
      body: Column(
        children: [
          allAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) => _StatusFilterBar(
              items: items,
              selected: filter,
              onSelected: (s) =>
                  ref.read(myReportsFilterProvider.notifier).state = s,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(myReportsProvider),
              child: filtered.when(
                loading: () => _SkeletonList(),
                error: (e, _) => _ErrorBody(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(myReportsProvider),
                ),
                data: (items) => items.isEmpty
                    ? _EmptyBody(
                        onSubmit: () => context.go('/ask-ai'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ReportRow(
                          report: items[i],
                          onEdit: () =>
                              context.push('/edit-report/${items[i].id}'),
                          onWithdraw: () => _confirmWithdraw(
                            context,
                            ref,
                            items[i].id,
                          ),
                          onTap: () {
                            if (items[i].status == MyReportStatus.verified) {
                              context.push('/report-detail/${items[i].id}');
                            }
                          },
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmWithdraw(
    BuildContext context,
    WidgetRef ref,
    String reportId,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: cs.errorContainer,
          icon: Icon(
            Icons.warning_amber_rounded,
            color: cs.onErrorContainer,
            size: 36,
          ),
          title: Text(
            l10n.myReportsWithdrawTitle,
            style: TextStyle(color: cs.onErrorContainer),
          ),
          content: Text(
            l10n.myReportsWithdrawBody,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onErrorContainer),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.onErrorContainer,
                side: BorderSide(
                    color: cs.onErrorContainer.withValues(alpha: 0.5)),
              ),
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.myReportsWithdrawConfirm),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(reportsRepositoryProvider).withdrawReport(reportId);
      ref.invalidate(myReportsProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.myReportsWithdrawFailed)),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Filter chip bar
// ---------------------------------------------------------------------------
class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  final List<MyReport> items;
  final MyReportStatus? selected;
  final void Function(MyReportStatus?) onSelected;

  int _count(MyReportStatus s) => items.where((r) => r.status == s).length;

  @override
  Widget build(BuildContext context) {
    final pendingCount = _count(MyReportStatus.pending);
    final verifiedCount = _count(MyReportStatus.verified);
    final rejectedCount = _count(MyReportStatus.rejected);

    final options = <MyReportStatus?>[
      null,
      if (pendingCount > 0) MyReportStatus.pending,
      if (verifiedCount > 0) MyReportStatus.verified,
      if (rejectedCount > 0) MyReportStatus.rejected,
    ];

    return FilterChipBar<MyReportStatus?>(
      options: options,
      selected: selected,
      onSelected: onSelected,
      labelBuilder: (context, s) {
        final l = context.l10n;
        if (s == null) return l.myReportsFilterAll;
        if (s == MyReportStatus.pending) {
          return l.myReportsFilterPending(pendingCount);
        }
        if (s == MyReportStatus.verified) {
          return l.myReportsFilterVerified(verifiedCount);
        }
        return l.myReportsFilterRejected(rejectedCount);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Single report row
// ---------------------------------------------------------------------------
class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.report,
    required this.onEdit,
    required this.onWithdraw,
    required this.onTap,
  });

  final MyReport report;
  final VoidCallback onEdit;
  final VoidCallback onWithdraw;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final verdict = theme.extension<VerdictPalette>()!;
    final isPending = report.status == MyReportStatus.pending;
    final isVerified = report.status == MyReportStatus.verified;
    final isRejected = report.status == MyReportStatus.rejected;

    final VerdictColors statusColor;
    final String statusLabel;
    if (isVerified) {
      statusColor = verdict.safe;
      statusLabel = l10n.myReportsStatusVerified;
    } else if (isRejected) {
      statusColor = verdict.scam;
      statusLabel = l10n.myReportsStatusRejected;
    } else {
      statusColor = verdict.suspicious;
      statusLabel = l10n.myReportsStatusPending;
    }

    final dateStr = DateFormat('MM-dd').format(report.updatedAt.toLocal());

    return GestureDetector(
      onTap: isVerified ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusPill(label: statusLabel, colors: statusColor),
                const Spacer(),
                Text(
                  dateStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              report.title,
              style: theme.textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              report.scamTypeLabelEn,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.tonal(
                    onPressed: onEdit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(l10n.myReportsEdit),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onWithdraw,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(l10n.myReportsWithdraw),
                  ),
                ],
              ),
            ],
            if (isRejected && report.rejectionRemark != null) ...[
              const SizedBox(height: 10),
              _NoteCallout(
                text: l10n.myReportsModeratorNote(report.rejectionRemark!),
                color: verdict.scam,
              ),
            ],
            // Flagged → surfaced as pending but show under-review note
            // (flagged reports arrive as status=pending from the server per FR-6.1,
            // but we handle the "under review" callout in the API mirror layer.
            // Nothing extra needed here.)
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.colors});

  final String label;
  final VerdictColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.fg,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _NoteCallout extends StatelessWidget {
  const _NoteCallout({required this.text, required this.color});

  final String text;
  final VerdictColors color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.bg.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton / empty / error states
// ---------------------------------------------------------------------------
class _SkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.myReportsEmpty,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onSubmit,
            child: Text(l10n.myReportsEmptyAction),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  )),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text(context.l10n.retry),
          ),
        ],
      ),
    );
  }
}
