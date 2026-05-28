// AiScoreCard — renders the backend AI similarity-score triage hint.
//
// Two variants:
//   - compact: small circular badge for queue rows ("94 / AI").
//   - full: detail-card with a score ring + RISK label + AI verdict chip.
//
// When `score` is null:
//   - full variant renders a muted "AI score pending" chip so the admin
//     knows the system has not yet attached a similarity hint to this
//     report (legacy row pre-migration, Gemini outage, or empty corpus).
//   - compact variant hides itself — queue rows are space-constrained and
//     a placeholder there would add noise.
//
// Per PRD §6.4 — colour is never the only differentiator: every variant
// renders the score as a number AND the verdict as text.

import 'package:flutter/material.dart';

import '../theme/ai_score_palette.dart';
import '../theme/app_theme.dart';
import 'package:mobile/l10n/l10n.dart';

enum AiScoreCardVariant { compact, full }

class AiScoreCard extends StatelessWidget {
  const AiScoreCard({
    super.key,
    required this.score,
    required this.confidence,
    this.variant = AiScoreCardVariant.full,
  });

  final int? score;
  final String? confidence;
  final AiScoreCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (score == null) {
      if (variant == AiScoreCardVariant.compact) return const SizedBox.shrink();
      return _PendingCard(label: l10n.aiScorePending);
    }
    final colors = AiScorePalette.forConfidence(context, confidence);
    if (colors == null) return const SizedBox.shrink();

    final a11y = l10n.aiScoreA11yLabel(confidence ?? 'unknown', score!);

    return Semantics(
      label: a11y,
      container: true,
      child: variant == AiScoreCardVariant.compact
          ? _CompactBadge(
              score: score!, colors: colors, badgeLabel: l10n.aiScoreBadgeLabel)
          : _FullCard(
              score: score!,
              colors: colors,
              riskLabel: l10n.aiScoreRiskLabel,
              verdictLabel: l10n.aiScoreVerdictLabel,
              verdictText: _verdictText(l10n, confidence),
            ),
    );
  }

  String _verdictText(dynamic l10n, String? c) {
    switch (c) {
      case 'high':
        return l10n.aiVerdictHigh;
      case 'medium':
        return l10n.aiVerdictMedium;
      case 'low':
        return l10n.aiVerdictLow;
      default:
        return l10n.aiVerdictUnknown;
    }
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactBadge extends StatelessWidget {
  const _CompactBadge({
    required this.score,
    required this.colors,
    required this.badgeLabel,
  });

  final int score;
  final VerdictColors colors;
  final String badgeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors.soft,
        shape: BoxShape.circle,
        border: Border.all(color: colors.accent, width: 2),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$score',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colors.fg,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          Text(
            badgeLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.fg,
              fontSize: 9,
              height: 1.0,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullCard extends StatelessWidget {
  const _FullCard({
    required this.score,
    required this.colors,
    required this.riskLabel,
    required this.verdictLabel,
    required this.verdictText,
  });

  final int score;
  final VerdictColors colors;
  final String riskLabel;
  final String verdictLabel;
  final String verdictText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.soft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          _ScoreRing(score: score, colors: colors),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  verdictLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.fg,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  verdictText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.colors});

  final int score;
  final VerdictColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: score.clamp(0, 100) / 100,
              strokeWidth: 5,
              backgroundColor: colors.accent.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
            ),
          ),
          Text(
            '$score',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colors.fg,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
