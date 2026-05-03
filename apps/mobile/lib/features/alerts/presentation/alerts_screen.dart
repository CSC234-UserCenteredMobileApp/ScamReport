import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/filter_chip_bar.dart';
import '../../../l10n/l10n.dart';
import '../../home/domain/recent_alert.dart';
import '../domain/alert.dart';
import 'alerts_providers.dart';

// ---------------------------------------------------------------------------
// AlertsScreen — list of announcements with category filter chips.
// ---------------------------------------------------------------------------
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  static const List<AlertCategory?> _filterOptions = [
    null,
    AlertCategory.fraudAlert,
    AlertCategory.tips,
    AlertCategory.platformUpdate,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);
    final filtered = ref.watch(filteredAlertsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(alertsProvider.future),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                title: Text(context.l10n.alertsTitle),
                centerTitle: true,
                pinned: false,
                floating: true,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: FilterChipBar<AlertCategory?>(
                    options: _filterOptions,
                    selected: selected,
                    onSelected: (option) =>
                        ref.read(selectedCategoryProvider.notifier).state =
                            option,
                    labelBuilder: _filterLabel,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: filtered.when(
                    loading: () => const _AlertsLoading(),
                    error: (_, __) => _AlertsError(
                      onRetry: () => ref.invalidate(alertsProvider),
                    ),
                    data: (alerts) => alerts.isEmpty
                        ? const _AlertsEmpty()
                        : _AlertsList(alerts: alerts),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  static String _filterLabel(BuildContext context, AlertCategory? option) {
    if (option == null) return context.l10n.filterAll;
    switch (option) {
      case AlertCategory.fraudAlert:
        return context.l10n.categoryFraudAlert;
      case AlertCategory.tips:
        return context.l10n.categoryTips;
      case AlertCategory.platformUpdate:
        return context.l10n.categoryPlatformUpdate;
      case AlertCategory.smsAlert:
        return context.l10n.categorySmsAlert;
    }
  }
}

// ---------------------------------------------------------------------------
// Loading state — three skeleton cards.
// ---------------------------------------------------------------------------
class _AlertsLoading extends StatelessWidget {
  const _AlertsLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SkeletonCard(),
        SizedBox(height: 8),
        _SkeletonCard(),
        SizedBox(height: 8),
        _SkeletonCard(),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state.
// ---------------------------------------------------------------------------
class _AlertsError extends StatelessWidget {
  const _AlertsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.loadFailedRetry,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state.
// ---------------------------------------------------------------------------
class _AlertsEmpty extends StatelessWidget {
  const _AlertsEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.alertsEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data state — vertical list of alert cards.
// ---------------------------------------------------------------------------
class _AlertsList extends StatelessWidget {
  const _AlertsList({required this.alerts});

  final List<Alert> alerts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < alerts.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _AlertListItem(alert: alerts[i]),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _AlertListItem — single tappable card showing one Alert.
// ---------------------------------------------------------------------------
class _AlertListItem extends StatelessWidget {
  const _AlertListItem({required this.alert});

  final Alert alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verdict = theme.extension<VerdictPalette>()!;

    final Color iconBg;
    final Color iconFg;
    final IconData iconData;
    final String chipLabel;

    switch (alert.category) {
      case AlertCategory.fraudAlert:
        iconBg = verdict.scam.bg;
        iconFg = verdict.scam.fg;
        iconData = Icons.warning_amber_outlined;
        chipLabel = context.l10n.categoryFraudAlert;
      case AlertCategory.tips:
        iconBg = verdict.safe.bg;
        iconFg = verdict.safe.fg;
        iconData = Icons.shield_outlined;
        chipLabel = context.l10n.categoryTips;
      case AlertCategory.platformUpdate:
        iconBg = verdict.unknown.bg;
        iconFg = verdict.unknown.fg;
        iconData = Icons.info_outline;
        chipLabel = context.l10n.categoryPlatformUpdate;
      case AlertCategory.smsAlert:
        iconBg = verdict.unknown.bg;
        iconFg = verdict.unknown.fg;
        iconData = Icons.info_outline;
        chipLabel = context.l10n.categorySmsAlert;
    }

    return Card(
      child: InkWell(
        onTap: () => context.push('/alerts/${alert.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconFg, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AlertItemBody(
                  alert: alert,
                  chipLabel: chipLabel,
                  iconBg: iconBg,
                  iconFg: iconFg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AlertItemBody — right-hand column inside the alert card.
// ---------------------------------------------------------------------------
class _AlertItemBody extends StatelessWidget {
  const _AlertItemBody({
    required this.alert,
    required this.chipLabel,
    required this.iconBg,
    required this.iconFg,
  });

  final Alert alert;
  final String chipLabel;
  final Color iconBg;
  final Color iconFg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = _formatDateMMDD(alert.publishedAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text(chipLabel),
                  backgroundColor: iconBg,
                  labelStyle: theme.textTheme.labelSmall?.copyWith(
                    color: iconFg,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide.none,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            Text(
              dateStr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          alert.title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          alert.excerpt,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Format DateTime as MM-DD without external package.
String _formatDateMMDD(DateTime dt) {
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$m-$d';
}
