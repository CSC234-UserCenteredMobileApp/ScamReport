import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../domain/report_detail.dart';
import 'report_detail_providers.dart';

class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(reportDetailProvider(id));

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const _SkeletonBody(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
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
                onPressed: () => ref.invalidate(reportDetailProvider(id)),
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      ),
      data: (detail) => _ReportDetailBody(detail: detail),
    );
  }
}

// ---------------------------------------------------------------------------
// _ReportDetailBody — fully loaded scaffold + scrollable content.
// ---------------------------------------------------------------------------
class _ReportDetailBody extends StatelessWidget {
  const _ReportDetailBody({required this.detail});

  final ReportDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<VerdictPalette>()!;
    final locale = Localizations.localeOf(context);
    final scamTypeLabel = locale.languageCode == 'th'
        ? detail.scamTypeLabelTh
        : detail.scamTypeLabelEn;
    final typeColors = _scamTypeColors(detail.scamTypeCode, palette);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _share(context, detail.id),
            tooltip: context.l10n.shareLink,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verified + type chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  icon: Icons.verified_outlined,
                  label: context.l10n.reportDetailVerified,
                  bg: palette.safe.bg,
                  fg: palette.safe.fg,
                ),
                _TypeChip(
                  label: scamTypeLabel,
                  bg: typeColors.bg,
                  fg: typeColors.fg,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              detail.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            // Meta row
            _MetaRow(detail: detail),
            const SizedBox(height: 20),

            // Reported identifier
            if (detail.targetIdentifier != null) ...[
              _IdentifierSection(
                identifier: detail.targetIdentifier!,
                kind: detail.targetIdentifierKind,
              ),
              const SizedBox(height: 20),
            ],

            // What happened
            _SectionLabel(label: context.l10n.reportDetailWhatHappened),
            const SizedBox(height: 8),
            Text(
              detail.description,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 20),

            // Evidence
            if (detail.evidenceFiles.isNotEmpty) ...[
              _SectionLabel(label: context.l10n.reportDetailEvidence),
              const SizedBox(height: 8),
              _EvidenceGrid(files: detail.evidenceFiles),
              const SizedBox(height: 20),
            ],

            // CTA
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(
                  '/submit-report',
                  extra: {'prefill_scam_type': detail.scamTypeCode},
                ),
                icon: const Icon(Icons.flag_outlined),
                label: Text(context.l10n.reportDetailCta),
              ),
            ),
            const SizedBox(height: 16),

            // Privacy footer
            Text(
              context.l10n.reportDetailPrivacyFooter,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context, String id) async {
    await Clipboard.setData(
      ClipboardData(text: 'https://scamreport.app/reports/$id'),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.linkCopied)),
    );
  }
}

// ---------------------------------------------------------------------------
// _MetaRow
// ---------------------------------------------------------------------------
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.detail});

  final ReportDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final style = theme.textTheme.bodySmall?.copyWith(color: muted);

    return Row(
      children: [
        Icon(Icons.calendar_today_outlined, size: 14, color: muted),
        const SizedBox(width: 4),
        Text(
          context.l10n.reportDetailVerifiedOn(_formatDateFull(detail.verifiedAt)),
          style: style,
        ),
        const SizedBox(width: 16),
        Icon(Icons.people_outline, size: 14, color: muted),
        const SizedBox(width: 4),
        Text(
          context.l10n.reportCountLabel(detail.reportCount),
          style: style,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _IdentifierSection
// ---------------------------------------------------------------------------
class _IdentifierSection extends StatelessWidget {
  const _IdentifierSection({required this.identifier, required this.kind});

  final String identifier;
  final String? kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<VerdictPalette>()!;
    final formatted = _formatIdentifier(identifier, kind);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.scam.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.scam.soft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_outlined,
                  size: 14, color: palette.scam.fg),
              const SizedBox(width: 4),
              Text(
                context.l10n.reportDetailIdentifierLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.scam.fg,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            formatted,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.scam.fg,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SectionLabel — uppercase label like "WHAT HAPPENED"
// ---------------------------------------------------------------------------
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _StatusChip — verified pill
// ---------------------------------------------------------------------------
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TypeChip — scam type pill
// ---------------------------------------------------------------------------
class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _EvidenceGrid — 2-column grid of evidence thumbnails
// ---------------------------------------------------------------------------
class _EvidenceGrid extends StatelessWidget {
  const _EvidenceGrid({required this.files});

  final List<EvidenceFileItem> files;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: files.length,
      itemBuilder: (context, i) => _EvidenceTile(file: files[i], index: i),
    );
  }
}

class _EvidenceTile extends StatelessWidget {
  const _EvidenceTile({required this.file, required this.index});

  final EvidenceFileItem file;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = 'Screenshot ${index + 1}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (file.signedUrl != null)
            Image.network(
              file.signedUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _PlaceholderTile(theme: theme),
            )
          else
            _PlaceholderTile(theme: theme),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.black54,
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderTile extends StatelessWidget {
  const _PlaceholderTile({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_outlined,
        size: 36,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SkeletonBody — loading placeholder
// ---------------------------------------------------------------------------
class _SkeletonBody extends StatelessWidget {
  const _SkeletonBody();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    Widget block({double height = 16, double? width}) => Container(
          height: height,
          width: width,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          block(height: 24, width: 140),
          const SizedBox(height: 8),
          block(height: 28, width: double.infinity),
          block(height: 28, width: 200),
          const SizedBox(height: 8),
          block(height: 14, width: 180),
          const SizedBox(height: 20),
          block(height: 80, width: double.infinity),
          const SizedBox(height: 20),
          block(height: 14, width: 120),
          const SizedBox(height: 8),
          block(height: 16, width: double.infinity),
          block(height: 16, width: double.infinity),
          block(height: 16, width: 220),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _formatDateFull(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _formatIdentifier(String raw, String? kind) {
  if (kind == 'phone') {
    final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.startsWith('+66') && digits.length >= 11) {
      final local = digits.substring(3);
      if (local.length == 9) {
        return '+66 ${local.substring(0, 2)} ${local.substring(2, 5)} ${local.substring(5)}';
      }
    }
    return raw;
  }
  if (kind == 'url') {
    return raw.replaceAll('.', '[.]');
  }
  return raw;
}

VerdictColors _scamTypeColors(String code, VerdictPalette palette) {
  switch (code) {
    case 'phone_impersonation':
    case 'phishing_sms':
    case 'ecommerce_fraud':
    case 'romance_scam':
      return palette.scam;
    case 'fake_qr':
    case 'fake_qr_code':
    case 'investment_fraud':
      return palette.suspicious;
    default:
      return palette.unknown;
  }
}
