import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ai_score_card.dart';
import '../../../l10n/l10n.dart';
import '../data/mod_action_failure.dart';
import '../domain/mod_report.dart';
import '../domain/mod_repository.dart';
import 'mod_providers.dart';

class AdminReviewScreen extends ConsumerWidget {
  const AdminReviewScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(modDetailProvider(reportId));

    return detailAsync.when(
      data: (report) => _ReviewScaffold(report: report, reportId: reportId),
      loading: () => Scaffold(
        appBar: AppBar(title: Text(context.l10n.adminReviewTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.adminReviewTitle)),
        body: Center(child: Text(e.toString())),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main scaffold — SliverAppBar header + content slivers + sticky action bar
// ---------------------------------------------------------------------------
class _ReviewScaffold extends ConsumerWidget {
  const _ReviewScaffold({required this.report, required this.reportId});

  final ModReportDetail report;
  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final scamTypeLabel = locale.languageCode == 'th'
        ? report.scamTypeLabelTh
        : report.scamTypeLabelEn;
    final dateStr = DateFormat.yMMMd().format(report.submittedAt);

    return Scaffold(
      body: Hero(
        tag: 'report-${report.id}',
        flightShuttleBuilder: (_, animation, __, ___, ____) => Material(
          color: Colors.transparent,
          child: FadeTransition(
            opacity: animation,
            child: Container(color: theme.colorScheme.surface),
          ),
        ),
        child: CustomScrollView(
          slivers: [
            _HeaderSliver(
              report: report,
              scamTypeLabel: scamTypeLabel,
              dateStr: dateStr,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: AiScoreCard(
                  score: report.aiScore,
                  confidence: report.aiConfidence,
                  variant: AiScoreCardVariant.full,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionCard(
                  label: l10n.adminLabelDescription,
                  child: Text(
                    report.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
            if (report.targetIdentifier != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _SectionCard(
                    label: l10n.adminLabelTarget,
                    child: Chip(label: Text(report.targetIdentifier!)),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _EvidenceSection(files: report.evidenceFiles),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverToBoxAdapter(
                child: _TimelineSection(trail: report.auditTrail),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: _ActionBar(report: report, reportId: reportId),
      ),
    );
  }
}

class _HeaderSliver extends ConsumerWidget {
  const _HeaderSliver({
    required this.report,
    required this.scamTypeLabel,
    required this.dateStr,
  });

  final ModReportDetail report;
  final String scamTypeLabel;
  final String dateStr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 180,
      title: Text(l10n.adminReviewTitle),
      centerTitle: true,
      actions: [
        IconButton(
          tooltip: l10n.adminReviewExportPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          onPressed: () async {
            final repo = ref.read(modRepositoryProvider);
            final bytes = Uint8List.fromList(
              await repo.fetchReportPdf(report.id),
            );
            await Printing.layoutPdf(
              name: 'scamreport-report-${report.id.substring(0, 8)}',
              onLayout: (_) async => bytes,
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                theme.colorScheme.surface,
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  _StatusPill(status: report.status),
                  const SizedBox(width: 8),
                  _ScamTypeChip(label: scamTypeLabel),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.adminReviewSubmittedOn(dateStr),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verdict = theme.extension<VerdictPalette>()!;
    final VerdictColors c;
    switch (status) {
      case 'verified':
        c = verdict.safe;
        break;
      case 'rejected':
        c = verdict.scam;
        break;
      case 'flagged':
        c = verdict.suspicious;
        break;
      default:
        c = verdict.unknown;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.fg.withValues(alpha: 0.25)),
      ),
      child: Text(
        status.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: c.fg,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _ScamTypeChip extends StatelessWidget {
  const _ScamTypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section card with coral hairline accent
// ---------------------------------------------------------------------------
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Evidence gallery — horizontal scroll of tiles, tap → fullscreen viewer
// ---------------------------------------------------------------------------
class _EvidenceSection extends StatelessWidget {
  const _EvidenceSection({required this.files});

  final List<EvidenceFile> files;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    if (files.isEmpty) {
      return _SectionCard(
        label: '${l10n.adminLabelEvidence} (0)',
        child: Text(
          l10n.noEvidence,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return _SectionCard(
      label: '${l10n.adminLabelEvidence} (${files.length})',
      child: SizedBox(
        height: 120,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: files.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) => _EvidenceTile(file: files[i]),
        ),
      ),
    );
  }
}

class _EvidenceTile extends StatelessWidget {
  const _EvidenceTile({required this.file});

  final EvidenceFile file;

  bool get _isImage => file.kind == 'image';
  bool get _canPreview => _isImage && file.signedUrl != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = file.signedUrl;
    return InkWell(
      onTap: _canPreview
          ? () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _ImageViewer(url: url!),
                ),
              )
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: _canPreview
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _FilePlaceholder(file: file),
                placeholder: (_, __) => Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              )
            : _FilePlaceholder(file: file),
      ),
    );
  }
}

class _FilePlaceholder extends StatelessWidget {
  const _FilePlaceholder({required this.file});

  final EvidenceFile file;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconData = file.kind == 'pdf'
        ? Icons.picture_as_pdf_rounded
        : Icons.attach_file_rounded;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, size: 36, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 6),
          Text(
            file.kind.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${(file.sizeBytes / 1024).round()} KB',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: CachedNetworkImage(
            imageUrl: url,
            errorWidget: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Audit trail — vertical timeline with verdict-colored nodes
// ---------------------------------------------------------------------------
class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.trail});

  final List<ModerationAction> trail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    if (trail.isEmpty) {
      return _SectionCard(
        label: l10n.adminReviewTimelineTitle,
        child: Text(
          l10n.auditTrailEmpty,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return _SectionCard(
      label: l10n.adminReviewTimelineTitle,
      child: Column(
        children: List.generate(trail.length, (i) {
          return _TimelineNode(
            action: trail[i],
            isLast: i == trail.length - 1,
          );
        }),
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({required this.action, required this.isLast});

  final ModerationAction action;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verdict = theme.extension<VerdictPalette>()!;
    final VerdictColors c;
    switch (action.action) {
      case 'approve':
        c = verdict.safe;
        break;
      case 'reject':
        c = verdict.scam;
        break;
      case 'flag':
        c = verdict.suspicious;
        break;
      default:
        c = verdict.unknown;
    }
    final muted = theme.colorScheme.onSurfaceVariant;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: c.fg,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.bg, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.action.toUpperCase() +
                        (action.adminId != null
                            ? '  ·  ${action.adminId}'
                            : ''),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: c.fg,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    DateFormat.yMMMd().add_jm().format(action.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                  if (action.remark.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(action.remark, style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action bar — sticky bottom, AnimatedSwitcher between idle / submitting
// ---------------------------------------------------------------------------
class _ActionBar extends ConsumerStatefulWidget {
  const _ActionBar({required this.report, required this.reportId});

  final ModReportDetail report;
  final String reportId;

  @override
  ConsumerState<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends ConsumerState<_ActionBar> {
  bool _isSubmitting = false;

  Future<void> _doAction(
    String label,
    Future<void> Function(ModRepository repo, String remark) action,
    String toast,
  ) async {
    final remark = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RemarkSheet(actionLabel: label),
    );
    if (remark == null || !mounted) return;
    setState(() => _isSubmitting = true);
    final repo = ref.read(modRepositoryProvider);
    try {
      await action(repo, remark);
      if (!mounted) return;
      ref.invalidate(modQueueProvider);
      ref.invalidate(modDetailProvider(widget.reportId));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(toast)));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final message = _formatActionError(context, e);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final l10n = context.l10n;
    final enabled = (report.isPending || report.isFlagged) && !_isSubmitting;
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: enabled
                  ? () => _doAction(
                        l10n.adminReviewReject,
                        (repo, r) => repo.reject(widget.reportId, r),
                        l10n.adminReviewRejected,
                      )
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(
                  color: enabled
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline,
                ),
              ),
              child: Text(l10n.adminReviewReject),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: enabled
                  ? () {
                      if (report.isFlagged) {
                        _doAction(
                          l10n.adminReviewUnflag,
                          (repo, r) => repo.unflag(widget.reportId, r),
                          l10n.adminReviewUnflagged,
                        );
                      } else {
                        _doAction(
                          l10n.adminReviewFlag,
                          (repo, r) => repo.flag(widget.reportId, r),
                          l10n.adminReviewFlagged,
                        );
                      }
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.tertiary,
                side: BorderSide(
                  color: enabled
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.outline,
                ),
              ),
              child: Text(
                report.isFlagged
                    ? l10n.adminReviewUnflag
                    : l10n.adminReviewFlag,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              onPressed: enabled
                  ? () => _doAction(
                        l10n.adminReviewApprove,
                        (repo, r) => repo.approve(widget.reportId, r),
                        l10n.adminReviewApproved,
                      )
                  : null,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _isSubmitting
                    ? const SizedBox(
                        key: ValueKey('progress'),
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        l10n.adminReviewApprove,
                        key: const ValueKey('label'),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatActionError(BuildContext context, Object error) {
  final l10n = context.l10n;
  if (error is ModActionFailure) {
    switch (error.statusCode) {
      case 401:
        return l10n.modErrorUnauthorized;
      case 403:
        return l10n.modErrorForbidden;
      case 404:
        return l10n.modErrorNotFound;
      case 422:
        return l10n.modErrorInvalidRemark;
      default:
        return l10n.modErrorGeneric(
          error.statusCode,
          error.serverMessage.isEmpty ? '—' : error.serverMessage,
        );
    }
  }
  return l10n.modErrorGeneric(0, error.toString());
}

// ---------------------------------------------------------------------------
// Remark bottom sheet with template chips
// ---------------------------------------------------------------------------
class _RemarkSheet extends StatefulWidget {
  const _RemarkSheet({required this.actionLabel});

  final String actionLabel;

  @override
  State<_RemarkSheet> createState() => _RemarkSheetState();
}

class _RemarkSheetState extends State<_RemarkSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyTemplate(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.adminReviewConfirm(widget.actionLabel),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: Text(l10n.adminReviewRemarkTemplateSpam),
                onPressed: () =>
                    _applyTemplate(l10n.adminReviewRemarkTemplateSpam),
              ),
              ActionChip(
                label: Text(l10n.adminReviewRemarkTemplateNotEnough),
                onPressed: () =>
                    _applyTemplate(l10n.adminReviewRemarkTemplateNotEnough),
              ),
              ActionChip(
                label: Text(l10n.adminReviewRemarkTemplateConfirmed),
                onPressed: () =>
                    _applyTemplate(l10n.adminReviewRemarkTemplateConfirmed),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.adminReviewRemark,
              hintText: l10n.adminReviewRemarkHint,
              border: const OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) Navigator.of(context).pop(text);
                  },
                  child: Text(widget.actionLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
