import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/matched_scammer.dart';

/// Shows the known-scammer profile returned by `/check` (name, risk, aliases,
/// linked reports, recent cases). Risk is conveyed by icon + label + colour —
/// never colour alone — consistent with the VerdictPalette accessibility rule.
class MatchedScammerCard extends StatelessWidget {
  const MatchedScammerCard({super.key, required this.scammer});

  final MatchedScammer scammer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final palette = theme.extension<VerdictPalette>()!;
    final s = scammer.summary;
    final risk = _riskColors(palette, s.riskLevel);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: risk.fg.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: label + risk badge
          Row(
            children: [
              Text(
                l.verdictKnownScammer.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              _RiskBadge(colors: risk, label: _riskLabel(l, s.riskLevel)),
            ],
          ),
          const SizedBox(height: 8),
          Text(s.displayName, style: theme.textTheme.titleMedium),
          if (s.suspectedName != null && s.suspectedName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              l.verdictClaimedToBe(s.suspectedName!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (s.aliases.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${l.verdictAlsoKnownAs}: ${s.aliases.join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            l.verdictLinkedReports(s.reportCount),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (s.topScamTypeCodes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final code in s.topScamTypeCodes)
                  Chip(
                    label: Text(code),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ],
          if (scammer.recentCases.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l.verdictRecentCases.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            for (final c in scammer.recentCases)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 6, color: risk.fg),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _caseLine(c),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _caseLine(MatchedScammerCase c) {
    final date = _shortDate(c.verifiedAt);
    return date == null ? c.title : '${c.title} · $date';
  }

  static String? _shortDate(String? iso) {
    if (iso == null) return null;
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return null;
    final m = parsed.month.toString().padLeft(2, '0');
    final d = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$m-$d';
  }

  static VerdictColors _riskColors(VerdictPalette p, String risk) =>
      switch (risk) {
        'high' => p.scam,
        'medium' => p.suspicious,
        'low' => p.safe,
        _ => p.unknown,
      };

  static String _riskLabel(AppLocalizations l, String risk) => switch (risk) {
        'high' => l.verdictRiskHigh,
        'medium' => l.verdictRiskMedium,
        'low' => l.verdictRiskLow,
        _ => l.verdictRiskUnknown,
      };
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.colors, required this.label});

  final VerdictColors colors;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 14, color: colors.fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: colors.fg,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
