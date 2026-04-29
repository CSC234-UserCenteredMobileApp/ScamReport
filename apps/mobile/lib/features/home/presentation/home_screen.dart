import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/alert_card.dart';
import '../../../core/widgets/report_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card_row.dart';
import '../../../l10n/l10n.dart';
import '../../auth/presentation/auth_providers.dart';
import 'home_providers.dart';

part '_brand_header.dart';
part '_clipboard_banner.dart';

// ---------------------------------------------------------------------------
// Generic skeleton box — shared across the part files.
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// HomeScreen
// ---------------------------------------------------------------------------
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 1. Brand header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 16, left: 16, right: 16),
                child: _BrandHeader(),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 16)),

            // 2. Clipboard banner (conditional)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _ClipboardBanner(),
              ),
            ),

            // 3. Search input + AI search button
            SliverToBoxAdapter(child: _SearchSection()),
            SliverToBoxAdapter(child: SizedBox(height: 16)),

            // 4. This Week stats
            SliverToBoxAdapter(child: _StatsSection()),
            SliverToBoxAdapter(child: SizedBox(height: 16)),

            // 5. Recent Fraud Alerts
            SliverToBoxAdapter(child: _AlertsSection()),
            SliverToBoxAdapter(child: SizedBox(height: 16)),

            // 6. Recently Verified
            SliverToBoxAdapter(child: _ReportsSection()),

            // 7. Bottom padding
            SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error row widget — shown in place of a data section on failure.
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// _SearchSection — search TextField + AI search button
// ---------------------------------------------------------------------------
class _SearchSection extends StatelessWidget {
  const _SearchSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          TextField(
            readOnly: true,
            onTap: () => context.push('/check-input'),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.shield_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              hintText: context.l10n.searchHint,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/search'),
              icon: const Icon(Icons.auto_awesome_outlined, size: 18),
              label: Text(context.l10n.aiSearch),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _StatsSection — "This Week" header + stat cards
// ---------------------------------------------------------------------------
class _StatsSection extends ConsumerWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(homeStatsProvider);
    const px16 = EdgeInsets.symmetric(horizontal: 16);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: px16,
          child: SectionHeader(title: context.l10n.sectionThisWeek),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: px16,
          child: statsAsync.when(
            loading: () => const StatCardRowSkeleton(),
            error: (_, __) => _ErrorRow(
              onRetry: () => ref.invalidate(homeStatsProvider),
            ),
            data: (stats) => StatCardRow(stats: stats),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _AlertsSection — "Recent Fraud Alerts" header + alert cards
// ---------------------------------------------------------------------------
class _AlertsSection extends ConsumerWidget {
  const _AlertsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(recentAlertsProvider);
    const px16 = EdgeInsets.symmetric(horizontal: 16);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: px16,
          child: SectionHeader(
            title: context.l10n.sectionRecentAlerts,
            onSeeAll: () => context.push('/alerts'),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: px16,
          child: alertsAsync.when(
            loading: () => const Column(
              children: [
                _SkeletonBox(height: 96),
                SizedBox(height: 8),
                _SkeletonBox(height: 96),
              ],
            ),
            error: (_, __) => _ErrorRow(
              onRetry: () => ref.invalidate(recentAlertsProvider),
            ),
            data: (alerts) => Column(
              children: [
                for (int i = 0; i < alerts.take(2).length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  AlertCard(alert: alerts[i]),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _ReportsSection — "Recently Verified" header + report cards
// ---------------------------------------------------------------------------
class _ReportsSection extends ConsumerWidget {
  const _ReportsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(recentReportsProvider);
    const px16 = EdgeInsets.symmetric(horizontal: 16);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: px16,
          child: SectionHeader(
            title: context.l10n.sectionRecentlyVerified,
            onSeeAll: () => context.push('/feed'),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: px16,
          child: reportsAsync.when(
            loading: () => const Column(
              children: [
                _SkeletonBox(height: 120),
                SizedBox(height: 8),
                _SkeletonBox(height: 120),
              ],
            ),
            error: (_, __) => _ErrorRow(
              onRetry: () => ref.invalidate(recentReportsProvider),
            ),
            data: (reports) => Column(
              children: [
                for (int i = 0; i < reports.take(2).length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  ReportCard(report: reports[i]),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
