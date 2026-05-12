// AI similarity score helper.
//
// Embeds the input text via Gemini, runs a top-K cosine-similarity query
// against `report_embeddings`, and reduces the top matches into an integer
// score (0..100) + confidence tier (high / medium / low / unknown).
//
// Used by the report-submit path to persist a triage hint on each new
// report, and by the admin-reports feature to expose that hint in the
// queue + detail responses.
//
// Scoring formula — top-1 priority:
//   The strongest single match dominates the score. A single high-quality
//   neighbour is a stronger triage signal than three weak neighbours; the
//   old top-3 average diluted obvious matches into 'medium' when one of
//   the top results was a 0.95 hit. Top-3 average is still computed and
//   used as a tie-breaker when the top-1 is ambiguous.

import type { AiConfidence } from '@my-product/shared';
import { searchSimilarReports } from '../rag/retrieval';
import {
  AVG_TOP_K,
  THRESHOLD_HIGH,
  THRESHOLD_MEDIUM,
  THRESHOLD_TOPK_MEDIUM,
  TOP_K,
} from './constants';

export interface AiScoreResult {
  aiScore: number | null;
  aiConfidence: AiConfidence | null;
}

export interface ComputeAiScoreOptions {
  /** Report id for log correlation. Optional — anonymous callers pass nothing. */
  reportId?: string;
}

/**
 * Shape of a report row that can be passed to `canonicalEmbedInput`.
 * Callers usually have a Prisma `Report` partial in hand; this loose type
 * keeps the helper free of a Prisma dependency.
 */
export interface ScorableReport {
  title: string;
  description: string;
  targetIdentifier?: string | null;
  scamType?: { labelEn?: string | null; labelTh?: string | null } | null;
}

/**
 * Build the canonical input string the embedding model sees for a given
 * report. Used at submit time AND at admin-detail backfill so both paths
 * agree on what "this report" embeds to.
 *
 * Includes the target identifier (the strongest scam signal we have) and
 * the scam-type label so similar reports cluster by category, not just by
 * lexical title overlap. Title + description still dominate the embedding.
 */
export function canonicalEmbedInput(report: ScorableReport): string {
  const lines: string[] = [report.title, report.description];
  const target = report.targetIdentifier?.trim();
  if (target) lines.push(`target: ${target}`);
  const category = report.scamType?.labelEn?.trim();
  if (category) lines.push(`category: ${category}`);
  return lines.join('\n');
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

    const top1 = results[0]!.similarity;
    const topK = results.slice(0, AVG_TOP_K);
    const topKAvg =
      topK.reduce((sum, r) => sum + r.similarity, 0) / topK.length;

    // Score uses the dominant signal so a single strong match shows the
    // admin a value reflective of that match's confidence, not a smoothed
    // average that depends on how many neighbours happened to be close.
    const score = Math.round(Math.max(top1, topKAvg) * 100);

    let confidence: AiConfidence;
    if (top1 >= THRESHOLD_HIGH) {
      confidence = 'high';
    } else if (top1 >= THRESHOLD_MEDIUM || topKAvg >= THRESHOLD_TOPK_MEDIUM) {
      confidence = 'medium';
    } else {
      confidence = 'low';
    }

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
