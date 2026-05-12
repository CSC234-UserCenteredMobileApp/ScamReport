// AI similarity score helper.
//
// Embeds the input text via Gemini, runs a top-K cosine-similarity query
// against `report_embeddings` (verified reports only), and reduces the top
// matches into an integer score (0..100) + confidence tier
// (high / medium / low / unknown).
//
// Used by the report-submit path to persist a triage hint on each new
// report, and by the admin-reports feature to expose that hint in the
// queue + detail responses.

import type { AiConfidence } from '@my-product/shared';
import { searchSimilarReports } from '../rag/retrieval';
import { AVG_TOP_K, THRESHOLD_HIGH, THRESHOLD_MEDIUM, TOP_K } from './constants';

export interface AiScoreResult {
  aiScore: number | null;
  aiConfidence: AiConfidence | null;
}

export interface ComputeAiScoreOptions {
  /** Report id for log correlation. Optional — anonymous callers pass nothing. */
  reportId?: string;
}

/**
 * Compute the AI similarity score for a free-text input.
 *
 * Failure modes are surfaced via distinct `console.error` lines so operators
 * can tell "no verified embeddings yet" apart from "Gemini call threw"
 * without exposing internals in the response payload. The response shape is
 * intentionally identical for both failure modes — `{ null, 'unknown' }` —
 * because the UI treats them the same.
 */
export async function computeAiScore(
  text: string,
  opts: ComputeAiScoreOptions = {},
): Promise<AiScoreResult> {
  try {
    const results = await searchSimilarReports(text, TOP_K);
    if (results.length === 0) {
      console.error('[ai-score]', {
        reportId: opts.reportId,
        phase: 'no_embeddings',
      });
      return { aiScore: null, aiConfidence: 'unknown' };
    }

    const top = results.slice(0, AVG_TOP_K);
    const avg = top.reduce((sum, r) => sum + r.similarity, 0) / top.length;
    const score = Math.round(avg * 100);
    const confidence: AiConfidence =
      avg >= THRESHOLD_HIGH ? 'high' : avg >= THRESHOLD_MEDIUM ? 'medium' : 'low';

    return { aiScore: score, aiConfidence: confidence };
  } catch (err) {
    console.error('[ai-score]', {
      reportId: opts.reportId,
      phase: 'embedding_failed',
      err,
    });
    return { aiScore: null, aiConfidence: 'unknown' };
  }
}
