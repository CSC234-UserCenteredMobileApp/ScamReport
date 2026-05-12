import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/l10n.dart';
import '../../domain/entities/similar_report.dart';

/// Compact card surfaced under an Ask AI assistant bubble for each verified
/// report the AI matched to the user's question. Tap → `/report-detail/:id`.
///
/// Title is the only multi-line element (clamped at 2 lines). Scam-type
/// chip + verified date sit on a row beneath the title so the card is dense
/// but scannable. Reporter identity is intentionally absent (PRD FR-7.4 +
/// FR-7.8 — admin views are anonymous, and Ask AI cards must follow the
/// same rule for user-facing surfaces).
class SimilarReportCard extends StatelessWidget {
  const SimilarReportCard({super.key, required this.report});

  final SimilarReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final scamTypeLabel = locale.languageCode == 'th'
        ? report.scamTypeLabelTh
        : report.scamTypeLabelEn;
    final dateStr = report.verifiedAt != null
        ? DateFormat.yMMMd(locale.toLanguageTag()).format(report.verifiedAt!)
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => context.push('/report-detail/${report.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                report.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      scamTypeLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (dateStr != null)
                    Text(
                      context.l10n.reportDetailVerifiedOn(dateStr),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
