import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/home_stats.dart';
import '../domain/recent_alert.dart';
import '../domain/recent_report.dart';
import 'home_providers.dart';

part '_brand_header.dart';
part '_clipboard_banner.dart';
part '_stat_card_row.dart';
part '_section_header.dart';
part '_alert_card.dart';
part '_report_card.dart';

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
    final statsAsync = ref.watch(homeStatsProvider);
    final alertsAsync = ref.watch(recentAlertsProvider);
    final reportsAsync = ref.watch(recentReportsProvider);

    const px16 = EdgeInsets.symmetric(horizontal: 16);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ----------------------------------------------------------------
            // 1. Brand header
            // ----------------------------------------------------------------
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 16, left: 16, right: 16),
                child: _BrandHeader(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ----------------------------------------------------------------
            // 2. Clipboard banner (conditional)
            // ----------------------------------------------------------------
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _ClipboardBanner(),
              ),
            ),

            // ----------------------------------------------------------------
            // 3. Search input + AI search button
            // ----------------------------------------------------------------
            SliverToBoxAdapter(
              child: Padding(
                padding: px16,
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
                        hintText: 'Paste a number, link, or message…',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/search'),
                        icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                        label: const Text('AI search'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ----------------------------------------------------------------
            // 4. THIS WEEK stats
            // ----------------------------------------------------------------
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _SectionHeader(title: 'This Week'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: px16,
                child: statsAsync.when(
                  loading: () => const _StatCardRowSkeleton(),
                  error: (_, __) => _ErrorRow(
                    onRetry: () => ref.invalidate(homeStatsProvider),
                  ),
                  data: (stats) => _StatCardRow(stats: stats),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ----------------------------------------------------------------
            // 5. RECENT FRAUD ALERTS
            // ----------------------------------------------------------------
            SliverToBoxAdapter(
              child: Padding(
                padding: px16,
                child: _SectionHeader(
                  title: 'Recent Fraud Alerts',
                  onSeeAll: () => context.push('/alerts'),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Padding(
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
                        _AlertCard(alert: alerts[i]),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ----------------------------------------------------------------
            // 6. RECENTLY VERIFIED
            // ----------------------------------------------------------------
            SliverToBoxAdapter(
              child: Padding(
                padding: px16,
                child: _SectionHeader(
                  title: 'Recently Verified',
                  onSeeAll: () => context.push('/feed'),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Padding(
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
                        _ReportCard(report: reports[i]),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ----------------------------------------------------------------
            // 7. Bottom padding
            // ----------------------------------------------------------------
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
        'Failed to load — tap to retry',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
