import 'package:flutter/material.dart';

import '../../features/moderation/domain/mod_report.dart';
import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// One row in the moderation queue.
///
/// Reporter identity is intentionally never rendered (PRD v1.2 FR-7.4 +
/// FR-7.8). The previous demo's masked-handle pill is gone — this widget
/// shows only the scam content the admin needs to act on.
///
/// Flagged variant: 4-px coral-amber left border + a localised "team note"
/// line beneath the row when `lastRemarkByAdmin` is non-null.
class ModQueueRow extends StatelessWidget {
  const ModQueueRow({
    super.key,
    required this.item,
    required this.onTap,
  });

  final ModQueueItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<VerdictPalette>()!;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final scamTypeLabel = locale.languageCode == 'th'
        ? item.scamTypeLabelTh
        : item.scamTypeLabelEn;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (item.isFlagged)
                  Container(width: 4, color: palette.suspicious.fg),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _ScamTypeChip(label: scamTypeLabel),
                            const SizedBox(width: 8),
                            Text(
                              _ageLabel(l10n, item.submittedAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.title,
                          style: theme.textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              l10n.modEvidenceCount(item.evidenceCount),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: onTap,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 0,
                                ),
                                minimumSize: const Size(0, 32),
                              ),
                              child: Text(l10n.modReview),
                            ),
                          ],
                        ),
                        if (item.isFlagged && item.lastRemarkByAdmin != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.modTeamNote(item.lastRemarkByAdmin!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: palette.suspicious.fg,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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

String _ageLabel(AppLocalizations l10n, DateTime submittedAt) {
  final age = DateTime.now().difference(submittedAt);
  if (age.inHours >= 1) return l10n.modAgeHours(age.inHours);
  final minutes = age.inMinutes < 0 ? 0 : age.inMinutes;
  return l10n.modAgeMinutes(minutes);
}
