import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/mod_queue_row.dart';
import '../../../l10n/l10n.dart';
import '../domain/mod_report.dart';
import 'mod_providers.dart';

class ModScreen extends ConsumerWidget {
  const ModScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(modQueueProvider);
    final filteredAsync = ref.watch(modFilteredQueueProvider);

    Future<void> onRefresh() async {
      await HapticFeedback.lightImpact();
      ref.invalidate(modQueueProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.modQueueTitle),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: queueAsync.when(
                  data: (data) => _StatsHeader(data: data),
                  loading: () => const _StatsHeaderSkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _ControlsDelegate(),
            ),
            filteredAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ModEmpty(),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return Hero(
                        tag: 'report-${item.id}',
                        // Hero on Card requires a Material destination; the
                        // detail screen renders in a Scaffold so the default
                        // Material wrap is fine.
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    return Container(width: 1, height: 36, color: color);
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
          style: theme.textTheme.headlineSmall?.copyWith(
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
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sticky controls — segmented filter + sort icon
// ---------------------------------------------------------------------------
class _ControlsDelegate extends SliverPersistentHeaderDelegate {
  static const double _h = 64;

  @override
  double get minExtent => _h;

  @override
  double get maxExtent => _h;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => false;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: const _ModControls(),
    );
  }
}

class _ModControls extends ConsumerWidget {
  const _ModControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segment = ref.watch(modFilterSegmentProvider);
    final newestFirst = ref.watch(modSortNewestFirstProvider);
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          child: SegmentedButton<ModQueueSegment>(
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
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: newestFirst ? l10n.modSortNewest : l10n.modSortOldest,
          child: IconButton.filledTonal(
            onPressed: () => ref
                .read(modSortNewestFirstProvider.notifier)
                .state = !newestFirst,
            icon: Icon(
              newestFirst ? Icons.arrow_downward : Icons.arrow_upward,
            ),
          ),
        ),
      ],
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
// Empty state — uses verdict.safe palette as a positive signal
// ---------------------------------------------------------------------------
class _ModEmpty extends StatelessWidget {
  const _ModEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verdict = theme.extension<VerdictPalette>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: verdict.safe.bg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_rounded,
                size: 44,
                color: verdict.safe.fg,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.modQueueEmpty,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
