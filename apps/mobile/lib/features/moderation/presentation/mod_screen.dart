import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/mod_queue_row.dart';
import '../../../l10n/l10n.dart';
import '../domain/mod_report.dart';
import 'mod_filter_sheet.dart';
import 'mod_providers.dart';
import 'mod_scam_type_chip_rail.dart';
import 'mod_search_field.dart';

class ModScreen extends ConsumerWidget {
  const ModScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(modQueueProvider);
    final filteredAsync = ref.watch(modFilteredQueueProvider);
    final filtersActive = ref.watch(modAnyFilterActiveProvider);

    Future<void> onRefresh() async {
      await HapticFeedback.lightImpact();
      ref.invalidate(modQueueProvider);
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              centerTitle: false,
              title: Text(
                context.l10n.modQueueTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              actions: const [_FilterAction()],
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: ModSearchField(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: queueAsync.when(
                  data: (data) => _StatsHeader(data: data),
                  loading: () => const _StatsHeaderSkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _SegmentControl(),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: ModScamTypeChipRail(),
              ),
            ),
            filteredAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ModEmpty(filtersActive: filtersActive),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return Hero(
                        tag: 'report-${item.id}',
                        child: ModQueueRow(
                          item: item,
                          onTap: () =>
                              context.push('/ask-ai/review/${item.id}'),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList.builder(
                  itemCount: 4,
                  itemBuilder: (_, __) => const _ShimmerRow(),
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

// ---------------------------------------------------------------------------
// Filter action — IconButton with active-filter count badge
// ---------------------------------------------------------------------------
class _FilterAction extends ConsumerWidget {
  const _FilterAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCount = _activeFilterCount(ref);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: context.l10n.modFilterTitle,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: () => showModFilterSheet(context),
            ),
            if (activeCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 16),
                  child: Text(
                    '$activeCount',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _activeFilterCount(WidgetRef ref) {
    var n = 0;
    if (ref.watch(modSearchQueryProvider).isNotEmpty) n++;
    if (ref.watch(modScamTypeFilterProvider).isNotEmpty) n++;
    if (ref.watch(modAiConfidenceFilterProvider).isNotEmpty) n++;
    if (ref.watch(modPriorityOnlyProvider)) n++;
    if (ref.watch(modHasEvidenceOnlyProvider)) n++;
    return n;
  }
}

// ---------------------------------------------------------------------------
// Stats header — coral-tinted card with pending / flagged / avg-age
// ---------------------------------------------------------------------------
class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.data});

  final ModQueueData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verdict = theme.extension<VerdictPalette>()!;
    final l10n = context.l10n;
    final now = DateTime.now();
    final allItems = data.items;
    final avgHours = allItems.isEmpty
        ? 0
        : allItems
                .map((i) => now.difference(i.submittedAt).inHours)
                .reduce((a, b) => a + b) ~/
            allItems.length;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: _StatPill(
                value: '${data.pendingCount}',
                label: l10n.modStatPending,
                color: theme.colorScheme.primary,
              ),
            ),
            _VerticalRule(color: theme.colorScheme.outlineVariant),
            Expanded(
              child: _StatPill(
                value: '${data.flaggedCount}',
                label: l10n.modStatFlagged,
                color: verdict.suspicious.fg,
              ),
            ),
            _VerticalRule(color: theme.colorScheme.outlineVariant),
            Expanded(
              child: _StatPill(
                value: l10n.modStatAvgAgeHours(avgHours),
                label: l10n.modStatAvgAge,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalRule extends StatelessWidget {
  const _VerticalRule({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: color);
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.6,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _StatsHeaderSkeleton extends StatelessWidget {
  const _StatsHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Segment control — All / Pending / Flagged
// ---------------------------------------------------------------------------
class _SegmentControl extends ConsumerWidget {
  const _SegmentControl();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segment = ref.watch(modFilterSegmentProvider);
    final l10n = context.l10n;
    return SegmentedButton<ModQueueSegment>(
      segments: [
        ButtonSegment(
          value: ModQueueSegment.all,
          label: Text(l10n.modSegmentAll),
        ),
        ButtonSegment(
          value: ModQueueSegment.pending,
          label: Text(l10n.modSegmentPending),
        ),
        ButtonSegment(
          value: ModQueueSegment.flagged,
          label: Text(l10n.modSegmentFlagged),
        ),
      ],
      selected: {segment},
      showSelectedIcon: false,
      onSelectionChanged: (s) =>
          ref.read(modFilterSegmentProvider.notifier).state = s.first,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer skeleton row for the queue loading state
// ---------------------------------------------------------------------------
class _ShimmerRow extends StatefulWidget {
  const _ShimmerRow();

  @override
  State<_ShimmerRow> createState() => _ShimmerRowState();
}

class _ShimmerRowState extends State<_ShimmerRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlight = Theme.of(context).colorScheme.surfaceContainerHigh;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Container(
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1 + 2 * _ctrl.value, 0),
                end: Alignment(1 + 2 * _ctrl.value, 0),
                colors: [base, highlight, base],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state — different copy when filters are the reason
// ---------------------------------------------------------------------------
class _ModEmpty extends ConsumerWidget {
  const _ModEmpty({required this.filtersActive});

  final bool filtersActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final verdict = theme.extension<VerdictPalette>()!;
    final l10n = context.l10n;

    final palette = filtersActive ? verdict.unknown : verdict.safe;
    final icon = filtersActive ? Icons.filter_alt_off_outlined : Icons.inbox_rounded;
    final title =
        filtersActive ? l10n.modEmptyFilteredTitle : l10n.modQueueEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: palette.bg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: palette.fg),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (filtersActive) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => resetModFilters(ref),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n.modEmptyFilteredAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
