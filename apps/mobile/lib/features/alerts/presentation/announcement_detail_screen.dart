import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../home/domain/recent_alert.dart';
import '../domain/alert.dart';
import 'alerts_providers.dart';

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

class _AnnouncementBody extends StatefulWidget {
  const _AnnouncementBody({required this.alert});

  final Alert alert;

  @override
  State<_AnnouncementBody> createState() => _AnnouncementBodyState();
}

class _AnnouncementBodyState extends State<_AnnouncementBody> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verdict = theme.extension<VerdictPalette>()!;
    final alert = widget.alert;

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

    final images = alert.attachments.where((a) => a.kind == 'image').toList();
    final pdfs = alert.attachments.where((a) => a.kind == 'pdf').toList();

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image carousel
            if (images.isNotEmpty) ...[
              SizedBox(
                height: 220,
                child: PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _currentImageIndex = i),
                  itemBuilder: (_, i) {
                    final url = images[i].url;
                    return CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    );
                  },
                ),
              ),
              if (images.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                      (i) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _currentImageIndex
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                ),
            ],

            // Text content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 0),
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

                  // PDF attachments
                  if (pdfs.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Attachments',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final pdf in pdfs)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.picture_as_pdf_outlined),
                        title: Text(
                          pdf.url.split('/').last,
                          style: theme.textTheme.bodyMedium,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy_outlined),
                          tooltip: 'Copy link',
                          onPressed: () => _copyPdfLink(context, pdf.url),
                        ),
                      ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
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

  Future<void> _copyPdfLink(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied')),
    );
  }
}

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
              Expanded(child: Text(line.substring(2), style: paragraphStyle)),
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

String _formatDateFull(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
