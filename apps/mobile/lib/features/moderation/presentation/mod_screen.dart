import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(child: _ModControls()),
            ),
            filteredAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    child: _ModEmpty(),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) => _ModQueueRow(item: items[i]),
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

class _ModQueueRow extends StatelessWidget {
  const _ModQueueRow({required this.item});

  final ModQueueItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final age = DateTime.now().difference(item.submittedAt);
    final ageLabel = age.inHours >= 1
        ? '${age.inHours}h'
        : '${age.inMinutes}m';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/ask-ai/review/${item.id}'),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (item.isFlagged)
                  Container(
                    width: 4,
                    color: theme.colorScheme.tertiary,
                  ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _TypeChip(code: item.scamTypeCode),
                          const SizedBox(width: 8),
                          Text(
                            ageLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _HandlePill(handle: item.reporterHandle),
                          const SizedBox(width: 8),
                          Text(
                            l10n.modEvidenceCount(item.evidenceCount),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () =>
                                context.push('/ask-ai/review/${item.id}'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0,
                              ),
                              minimumSize: const Size(0, 32),
                            ),
                            child: Text(l10n.modReview),
                          ),
                        ],
                      ),
                      if (item.isFlagged &&
                          item.lastRemarkByAdmin != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          l10n.modTeamNote(item.lastRemarkByAdmin!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.tertiary,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        code.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HandlePill extends StatelessWidget {
  const _HandlePill({required this.handle});

  final String handle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        handle,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
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
