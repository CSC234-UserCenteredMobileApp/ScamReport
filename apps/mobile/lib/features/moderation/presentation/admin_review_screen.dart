import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/ai_score_card.dart';
import '../../../core/widgets/audit_trail_row.dart';
import '../../../l10n/l10n.dart';
import '../domain/mod_report.dart';
import '../domain/mod_repository.dart';
import 'mod_providers.dart';

class AdminReviewScreen extends ConsumerWidget {
  const AdminReviewScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(modDetailProvider(reportId));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.adminReviewTitle),
        centerTitle: true,
      ),
      body: detailAsync.when(
        data: (report) => _ReviewBody(report: report, reportId: reportId),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _ReviewBody extends ConsumerWidget {
  const _ReviewBody({required this.report, required this.reportId});

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

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.status.toUpperCase(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ScamTypeChip(label: scamTypeLabel),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      report.title,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Reporter identity is intentionally absent (PRD v1.2 FR-7.4 +
              // FR-7.8). The previous "Submitted by User_xxxx" row is gone;
              // a date-only meta line replaces it.
              Text(
                l10n.adminReviewSubmittedOn(dateStr),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (report.aiScore != null) ...[
                const SizedBox(height: 12),
                AiScoreCard(
                  score: report.aiScore,
                  confidence: report.aiConfidence,
                  variant: AiScoreCardVariant.full,
                ),
              ],
              const SizedBox(height: 16),
              _SectionLabel(label: l10n.adminLabelDescription),
              const SizedBox(height: 4),
              Text(report.description, style: theme.textTheme.bodyMedium),
              if (report.targetIdentifier != null) ...[
                const SizedBox(height: 16),
                _SectionLabel(label: l10n.adminLabelTarget),
                const SizedBox(height: 4),
                Chip(label: Text(report.targetIdentifier!)),
              ],
              const SizedBox(height: 16),
              _SectionLabel(
                label:
                    '${l10n.adminLabelEvidence} (${report.evidenceFiles.length})',
              ),
              const SizedBox(height: 4),
              ...report.evidenceFiles.map((f) => _EvidenceRow(file: f)),
              if (report.evidenceFiles.isEmpty)
                Text(
                  l10n.noEvidence,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 16),
              _SectionLabel(label: l10n.adminLabelAuditTrail),
              const SizedBox(height: 4),
              if (report.auditTrail.isEmpty)
                Text(
                  l10n.auditTrailEmpty,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ...report.auditTrail.map(
                  (a) => AuditTrailRow(
                    action: a.action,
                    at: a.createdAt,
                    remark: a.remark,
                    adminLabel: a.adminId,
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _ActionBar(report: report, reportId: reportId),
        ),
      ],
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.report, required this.reportId});

  final ModReportDetail report;
  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final enabled = report.isPending || report.isFlagged;

    Future<void> doAction(
      String label,
      Future<void> Function(ModRepository repo, String remark) action,
      String toast,
    ) async {
      final remark = await showDialog<String>(
        context: context,
        builder: (_) => _RemarkDialog(actionLabel: label),
      );
      if (remark == null || !context.mounted) return;
      final repo = ref.read(modRepositoryProvider);
      try {
        await action(repo, remark);
        ref.invalidate(modQueueProvider);
        ref.invalidate(modDetailProvider(reportId));
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(toast)));
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: enabled
                  ? () => doAction(
                        l10n.adminReviewReject,
                        (repo, r) => repo.reject(reportId, r),
                        l10n.adminReviewRejected,
                      )
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(
                  color: enabled
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.outline,
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
                        doAction(
                          l10n.adminReviewUnflag,
                          (repo, r) => repo.unflag(reportId, r),
                          l10n.adminReviewUnflagged,
                        );
                      } else {
                        doAction(
                          l10n.adminReviewFlag,
                          (repo, r) => repo.flag(reportId, r),
                          l10n.adminReviewFlagged,
                        );
                      }
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.tertiary,
                side: BorderSide(
                  color: enabled
                      ? Theme.of(context).colorScheme.tertiary
                      : Theme.of(context).colorScheme.outline,
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
                  ? () => doAction(
                        l10n.adminReviewApprove,
                        (repo, r) => repo.approve(reportId, r),
                        l10n.adminReviewApproved,
                      )
                  : null,
              child: Text(l10n.adminReviewApprove),
            ),
          ),
        ],
      ),
    );
  }
}

class _RemarkDialog extends StatefulWidget {
  const _RemarkDialog({required this.actionLabel});

  final String actionLabel;

  @override
  State<_RemarkDialog> createState() => _RemarkDialogState();
}

class _RemarkDialogState extends State<_RemarkDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.adminReviewConfirm(widget.actionLabel)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l10n.adminReviewRemark,
          hintText: l10n.adminReviewRemarkHint,
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) Navigator.of(context).pop(text);
          },
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(6),
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

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({required this.file});

  final EvidenceFile file;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.attach_file_rounded,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${file.kind} — ${file.mimeType} (${(file.sizeBytes / 1024).round()} KB)',
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
