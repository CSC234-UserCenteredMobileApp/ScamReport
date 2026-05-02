import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/report_card.dart';
import '../../../core/widgets/stat_card_row.dart';
import '../../../l10n/l10n.dart';
import '../../home/domain/recent_report.dart';
import '../../home/presentation/home_providers.dart';
import 'feed_providers.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.feedTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/check-input'),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {},
          ),
        ],
      ),
      body: const _FeedBody(),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------
class _FeedBody extends ConsumerWidget {
  const _FeedBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(feedReportsProvider);
    final statsAsync = ref.watch(homeStatsProvider);
    final selectedFilter = ref.watch(feedFilterProvider);

    return CustomScrollView(
      slivers: [
        // Stats row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: statsAsync.when(
              loading: () => const StatCardRowSkeleton(),
              error: (_, __) => _ErrorRow(
                onRetry: () => ref.invalidate(homeStatsProvider),
              ),
              data: (stats) => Row(
                children: [
                  Expanded(
                    child: StatCard(
                      value: _formatNumber(stats.verifiedTotal),
                      label: context.l10n.feedStatTotal,
                      valueColor: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCard(
                      value: '+${stats.newThisWeek}',
                      label: context.l10n.feedStatThisWeek,
                      valueColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCard(
                      value: stats.topScamType,
                      label: context.l10n.feedStatTopType,
                      valueColor: Theme.of(context).colorScheme.onSurface,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Filter chip bar — shown only when reports are loaded
        reportsAsync.maybeWhen(
          data: (reports) => SliverToBoxAdapter(
            child: _FilterChipBar(
              reports: reports,
              selected: selectedFilter,
              onSelected: (code) =>
                  ref.read(feedFilterProvider.notifier).state = code,
            ),
          ),
          orElse: () =>
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Report list
        reportsAsync.when(
          loading: () => SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, i < 2 ? 8 : 0),
                child: const _SkeletonCard(),
              ),
              childCount: 3,
            ),
          ),
          error: (_, __) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _ErrorRow(
                onRetry: () => ref.invalidate(feedReportsProvider),
              ),
            ),
          ),
          data: (reports) {
            final filtered = selectedFilter == null
                ? reports
                : reports
                    .where((r) => r.scamTypeCode == selectedFilter)
                    .toList();

            if (filtered.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.l10n.feedNoReports,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => ReportCard(report: filtered[i]),
              ),
            );
          },
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chip bar
// ---------------------------------------------------------------------------
class _FilterChipBar extends StatelessWidget {
  const _FilterChipBar({
    required this.reports,
    required this.selected,
    required this.onSelected,
  });

  final List<RecentReport> reports;
  final String? selected;
  final void Function(String?) onSelected;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);

    // Unique scam types in order of first appearance
    final seen = <String>{};
    final types = <({String code, String label})>[];
    for (final r in reports) {
      if (seen.add(r.scamTypeCode)) {
        types.add((
          code: r.scamTypeCode,
          label: locale.languageCode == 'th'
              ? r.scamTypeLabelTh
              : r.scamTypeLabelEn,
        ));
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _FilterChip(
            label: context.l10n.feedFilterAll,
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          ...types.map(
            (t) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _FilterChip(
                label: t.label,
                selected: selected == t.code,
                onTap: () =>
                    onSelected(selected == t.code ? null : t.code),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRetry,
      child: Text(
        context.l10n.loadFailedRetry,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

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
