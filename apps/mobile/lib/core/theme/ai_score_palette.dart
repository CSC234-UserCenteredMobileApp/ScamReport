// AI confidence → VerdictPalette mapping used by AiScoreCard.
//
// Backend is palette-agnostic — it only emits the tier label ('high' /
// 'medium' / 'low' / 'unknown' / null). This helper centralises the
// design decision documented in the refactor plan:
//
//   high    → safe        (green tones — strong RAG match)
//   medium  → suspicious  (amber tones — partial match)
//   low     → unknown     (slate tones — weak match, treat with caution)
//   unknown → unknown     (slate tones — no embeddings or Gemini failure)
//   null    → caller should render nothing
//
// Keeping the mapping mobile-side means a copy change ("rename medium →
// borderline") never needs a server release.

import 'package:flutter/material.dart';

import 'app_theme.dart';

class AiScorePalette {
  AiScorePalette._();

  /// Resolves the tier label to the `VerdictColors` bundle. Returns `null`
  /// when the caller should render no badge (no score available).
  static VerdictColors? forConfidence(BuildContext context, String? confidence) {
    if (confidence == null) return null;
    final palette = Theme.of(context).extension<VerdictPalette>();
    if (palette == null) return null;
    switch (confidence) {
      case 'high':
        return palette.safe;
      case 'medium':
        return palette.suspicious;
      case 'low':
      case 'unknown':
        return palette.unknown;
      default:
        return palette.unknown;
    }
  }
}
