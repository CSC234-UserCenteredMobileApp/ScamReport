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
// Scoring formula — top-1 priority + scammer-cluster bump:
//   The strongest single match dominates the score. A single high-quality
//   neighbour is a stronger triage signal than three weak neighbours; the
//   old top-3 average diluted obvious matches into 'medium' when one of
//   the top results was a 0.95 hit. Top-3 average is still computed and
//   used as a tie-breaker when the top-1 is ambiguous.
//
//   When >= THRESHOLD_SCAMMER_CLUSTER of the top-K share the same non-null
//   scammerId, we bump the confidence tier one notch and clamp the score to
//   SCAMMER_CLUSTER_SCORE_FLOOR — multiple cases pointing at the same
//   offender is itself evidence that this submission belongs to a known
//   campaign.

import type { AiConfidence } from '@my-product/shared';
import { searchSimilarReports } from '../rag/retrieval';
import {
  AVG_TOP_K,
  SCAMMER_CLUSTER_SCORE_FLOOR,
  THRESHOLD_HIGH,
  THRESHOLD_MEDIUM,
  THRESHOLD_SCAMMER_CLUSTER,
  THRESHOLD_TOPK_MEDIUM,
  TOP_K,
} from './constants';

export interface AiScoreResult {
  aiScore: number | null;
  aiConfidence: AiConfidence | null;
  /** ScammerId of the cluster that triggered the bump, when one was found. */
  topScammerId: string | null;
  /** Number of top-K rows sharing `topScammerId`. Zero when no cluster. */
  topScammerSiblingCount: number;
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
  scammer?: { displayName?: string | null; aliases?: string[] | null } | null;
}

/**
 * Build the canonical input string the embedding model sees for a given
 * report. Used at submit time AND at admin-detail backfill so both paths
 * agree on what "this report" embeds to.
 *
 * Includes the target identifier (the strongest scam signal we have), the
 * scam-type label so similar reports cluster by category, and the linked
 * scammer's display name / aliases (when present) so embedding space binds
 * by offender, not just lexical title overlap.
 */
export function canonicalEmbedInput(report: ScorableReport): string {
  const lines: string[] = [report.title, report.description];
  const target = report.targetIdentifier?.trim();
  if (target) lines.push(`target: ${target}`);
  const category = report.scamType?.labelEn?.trim();
  if (category) lines.push(`category: ${category}`);
  const scammerName = report.scammer?.displayName?.trim();
  if (scammerName) {
    const aliases = (report.scammer?.aliases ?? [])
      .map((a) => a.trim())
      .filter(Boolean);
    const all = [scammerName, ...aliases];
    lines.push(`scammer: ${all.join(' / ')}`);
  }
  return lines.join('\n');
}

function bumpConfidence(c: AiConfidence): AiConfidence {
  if (c === 'low') return 'medium';
  if (c === 'medium') return 'high';
  return c;
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
      return {
        aiScore: null,
        aiConfidence: 'unknown',
        topScammerId: null,
        topScammerSiblingCount: 0,
      };
    }

    const top1 = results[0]!.similarity;
    const topK = results.slice(0, AVG_TOP_K);
    const topKAvg =
      topK.reduce((sum, r) => sum + r.similarity, 0) / topK.length;

    // Score uses the dominant signal so a single strong match shows the
    // admin a value reflective of that match's confidence, not a smoothed
    // average that depends on how many neighbours happened to be close.
    let score = Math.round(Math.max(top1, topKAvg) * 100);

    let confidence: AiConfidence;
    if (top1 >= THRESHOLD_HIGH) {
      confidence = 'high';
    } else if (top1 >= THRESHOLD_MEDIUM || topKAvg >= THRESHOLD_TOPK_MEDIUM) {
      confidence = 'medium';
    } else {
      confidence = 'low';
    }

    // Scammer cluster signal: 2+ of top-K share the same non-null scammerId.
    const counts = new Map<string, number>();
    for (const r of results) {
      if (!r.scammerId) continue;
      counts.set(r.scammerId, (counts.get(r.scammerId) ?? 0) + 1);
    }
    let topScammerId: string | null = null;
    let topScammerSiblingCount = 0;
    for (const [id, n] of counts) {
      if (n > topScammerSiblingCount) {
        topScammerId = id;
        topScammerSiblingCount = n;
      }
    }
    if (topScammerSiblingCount >= THRESHOLD_SCAMMER_CLUSTER) {
      confidence = bumpConfidence(confidence);
      if (score < SCAMMER_CLUSTER_SCORE_FLOOR) score = SCAMMER_CLUSTER_SCORE_FLOOR;
    } else {
      // Below threshold — not a cluster; don't surface a misleading scammerId.
      topScammerId = null;
      topScammerSiblingCount = 0;
    }

    return { aiScore: score, aiConfidence: confidence, topScammerId, topScammerSiblingCount };
  } catch (err) {
    console.error('[ai-score]', {
      reportId: opts.reportId,
      phase: 'embedding_failed',
      err,
    });
    return {
      aiScore: null,
      aiConfidence: 'unknown',
      topScammerId: null,
      topScammerSiblingCount: 0,
    };
  }
}
