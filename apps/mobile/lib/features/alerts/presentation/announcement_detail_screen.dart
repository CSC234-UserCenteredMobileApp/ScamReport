import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../home/domain/recent_alert.dart';
import '../domain/alert.dart';
import 'alerts_providers.dart';

// ---------------------------------------------------------------------------
// AnnouncementDetailScreen — full announcement view with share action.
// ---------------------------------------------------------------------------
class AnnouncementDetailScreen extends ConsumerWidget {
  const AnnouncementDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(alertDetailProvider(id));

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(context.l10n.alertsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.alertsTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.loadFailedRetry,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(alertDetailProvider(id)),
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      ),
      data: (alert) => _AnnouncementBody(alert: alert),
    );
  }
}

// ---------------------------------------------------------------------------
// _AnnouncementBody — fully loaded scaffold + content.
// ---------------------------------------------------------------------------
class _AnnouncementBody extends StatelessWidget {
  const _AnnouncementBody({required this.alert});

  final Alert alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verdict = theme.extension<VerdictPalette>()!;

    final Color chipBg;
    final Color chipFg;
    final String chipLabel;

    switch (alert.category) {
      case AlertCategory.fraudAlert:
        chipBg = verdict.scam.bg;
        chipFg = verdict.scam.fg;
        chipLabel = context.l10n.categoryFraudAlert;
      case AlertCategory.tips:
        chipBg = verdict.safe.bg;
        chipFg = verdict.safe.fg;
        chipLabel = context.l10n.categoryTips;
      case AlertCategory.platformUpdate:
        chipBg = verdict.unknown.bg;
        chipFg = verdict.unknown.fg;
        chipLabel = context.l10n.categoryPlatformUpdate;
      case AlertCategory.smsAlert:
        chipBg = verdict.unknown.bg;
        chipFg = verdict.unknown.fg;
        chipLabel = context.l10n.categorySmsAlert;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(alert.title),
        actions: [
          if (alert.slug.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _shareLink(context, alert.slug),
              tooltip: context.l10n.shareLink,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(chipLabel),
                backgroundColor: chipBg,
                labelStyle: theme.textTheme.labelSmall?.copyWith(
                  color: chipFg,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide.none,
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              alert.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatDateFull(alert.publishedAt)} • ${context.l10n.postedByTeam}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _BodyText(body: alert.body),
          ],
        ),
      ),
    );
  }

  Future<void> _shareLink(BuildContext context, String slug) async {
    await Clipboard.setData(
      ClipboardData(text: 'https://scamreport.app/announcements/$slug'),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.linkCopied)),
    );
  }
}

// ---------------------------------------------------------------------------
// _BodyText — renders newline-separated paragraphs and "• " bullet lines.
// ---------------------------------------------------------------------------
class _BodyText extends StatelessWidget {
  const _BodyText({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = body.split('\n');
    final paragraphStyle = theme.textTheme.bodyMedium?.copyWith(height: 1.5);

    final children = <Widget>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (i > 0) children.add(const SizedBox(height: 8));
      if (line.startsWith('• ')) {
        children.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: paragraphStyle),
              Expanded(
                child: Text(
                  line.substring(2),
                  style: paragraphStyle,
                ),
              ),
            ],
          ),
        );
      } else {
        children.add(Text(line, style: paragraphStyle));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

/// Format DateTime as yyyy-MM-dd without external package.
String _formatDateFull(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
