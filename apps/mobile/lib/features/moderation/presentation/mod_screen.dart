import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/mod_queue_row.dart';
import '../../../core/widgets/stat_card_row.dart';
import '../../../l10n/l10n.dart';
import '../domain/mod_report.dart';
import 'mod_providers.dart';

class ModScreen extends ConsumerWidget {
  const ModScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(modQueueProvider);
    final filteredAsync = ref.watch(modFilteredQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.modQueueTitle),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(modQueueProvider),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: queueAsync.when(
                  data: (data) => _StatsRow(data: data),
                  loading: () => const StatCardRowSkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(child: _ModControls()),
            ),
            filteredAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return SliverFillRemaining(child: _ModEmpty());
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) => ModQueueRow(
                      item: items[i],
                      onTap: () =>
                          context.push('/ask-ai/review/${items[i].id}'),
                    ),
                  ),
                );
              },
              loading: () => SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList.builder(
                  itemCount: 4,
                  itemBuilder: (_, __) => const _SkeletonRow(),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text(e.toString())),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.data});

  final ModQueueData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final allItems = data.items;
    final avgHours = allItems.isEmpty
        ? 0
        : allItems
                .map((i) => now.difference(i.submittedAt).inHours)
                .reduce((a, b) => a + b) ~/
            allItems.length;

    return Row(
      children: [
        Expanded(
          child: StatCard(
            value: '${data.pendingCount}',
            label: l10n.modStatPending,
            valueColor: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatCard(
            value: '${data.flaggedCount}',
            label: l10n.modStatFlagged,
            valueColor: theme.colorScheme.tertiary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatCard(
            value: l10n.modStatAvgAgeHours(avgHours),
            label: l10n.modStatAvgAge,
            valueColor: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ModControls extends ConsumerWidget {
  const _ModControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newestFirst = ref.watch(modSortNewestFirstProvider);
    final flaggedOnly = ref.watch(modFilterFlaggedProvider);
    final l10n = context.l10n;

    return Row(
      children: [
        DropdownButton<bool>(
          value: newestFirst,
          underline: const SizedBox.shrink(),
          items: [
            DropdownMenuItem(
              value: false,
              child: Text(l10n.modSortOldestFirst),
            ),
            DropdownMenuItem(
              value: true,
              child: Text(l10n.modSortNewestFirst),
            ),
          ],
          onChanged: (v) =>
              ref.read(modSortNewestFirstProvider.notifier).state = v ?? false,
        ),
        const SizedBox(width: 12),
        FilterChip(
          label: Text(l10n.modFilterPriorityFlag),
          selected: flaggedOnly,
          onSelected: (v) =>
              ref.read(modFilterFlaggedProvider.notifier).state = v,
        ),
      ],
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _ModEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        context.l10n.modQueueEmpty,
        style: Theme.of(context).textTheme.bodyLarge,
        textAlign: TextAlign.center,
      ),
    );
  }
}
