// AI evaluation orchestrator. Runs every labelled case in `ai_eval_cases`
// through the verdict + AI score pipelines, compares against expected
// values, and persists a summary plus per-case results.
//
// Metrics:
//   - verdictAccuracy   = exact-match verdicts / total
//   - scammerRecallAt1  = matched scammer at top result / cases-with-expected
//   - scammerMrr        = mean reciprocal rank over the matches list
//                         (only available when /check returned matches[])
//   - missingFactsF1    = F1 against expectedMissingFacts (text cases only)
//   - p95LatencyMs      = 95th percentile per-case latency
//
// Ask AI is only consulted for text cases (where missing-facts apply); the
// service constructs a synthetic conversation per case so transient chats
// don't leak into a real user's history.

import { getPrisma } from '../../core/db/client';
import { runCheck } from '../check/check.service';
import { findById as findScammerById } from '../admin-scammers/admin-scammers.repo';
import { computeAiScore, canonicalEmbedInput } from '../../core/ai-score';
import { handleTurn } from '../ask-ai/ask-ai.service';
import type { AiEvalSummary } from '@my-product/shared';
import * as repo from './admin-ai-eval.repo';

const ASK_AI_USER_ID_LABEL = 'ai-eval-synthetic';

export async function runEvaluation(): Promise<AiEvalSummary> {
  const cases = await repo.listCases();
  if (cases.length === 0) {
    throw new Error('No eval cases seeded — run `bun run prisma/seed-ai-eval.ts` first.');
  }

  const askAiUserId = await ensureSyntheticUser();

  const perCase: Array<{
    caseId: string;
    actualVerdict: import('../../generated/prisma/client').VerdictLabel;
    actualScammerId: string | null;
    actualMissingFacts: string[];
    scammerMatched: boolean;
    latencyMs: number;
    expectedVerdict: import('../../generated/prisma/client').VerdictLabel;
    expectedScammerId: string | null;
    expectedMissingFacts: string[];
    inputType: string;
    rankOfExpectedScammer: number | null;
  }> = [];

  for (const c of cases) {
    const start = Date.now();
    let actualVerdict: import('../../generated/prisma/client').VerdictLabel = 'unknown';
    let actualScammerId: string | null = null;
    let rankOfExpected: number | null = null;
    let actualMissingFacts: string[] = [];

    try {
      const result = await runCheck(c.inputPayload, c.inputType, null);
      actualVerdict = result.verdict;
      actualScammerId = result.matchedScammer?.summary.id ?? null;
      if (c.expectedScammerId && result.matchedScammer) {
        // Recall@1 — the top result *is* the matched scammer profile.
        if (result.matchedScammer.summary.id === c.expectedScammerId) {
          rankOfExpected = 1;
        }
      }
      // Fall back to scanning result.matches for the expected scammer in
      // case the scammer is implied via a sibling case. We resolve each
      // matched report's scammer once. For 5 matches this is at most 5
      // queries — acceptable for eval.
      if (
        rankOfExpected === null &&
        c.expectedScammerId &&
        result.matches.length > 0
      ) {
        const prisma = getPrisma();
        const reportRows = await prisma.report.findMany({
          where: { id: { in: result.matches.map((m) => m.id) } },
          select: { id: true, scammerId: true },
        });
        const byId = new Map(reportRows.map((r) => [r.id, r.scammerId]));
        for (let i = 0; i < result.matches.length; i++) {
          const sid = byId.get(result.matches[i]!.id);
          if (sid === c.expectedScammerId) {
            rankOfExpected = i + 1;
            break;
          }
        }
      }
    } catch (err) {
      console.error('[ai-eval] /check failed for case', { caseId: c.id, label: c.label, err });
    }

    // Ask AI synthetic single-turn — text cases only.
    if (c.inputType === 'text' && askAiUserId) {
      try {
        const prisma = getPrisma();
        const conv = await prisma.aiConversation.create({
          data: { userId: askAiUserId },
        });
        const turn = await handleTurn(askAiUserId, conv.id, c.inputPayload);
        actualMissingFacts = turn.missingFacts;
        // Clean up the synthetic conversation immediately.
        await prisma.aiConversation.delete({ where: { id: conv.id } });
      } catch (err) {
        console.error('[ai-eval] Ask AI turn failed', { caseId: c.id, err });
      }
    }

    const latencyMs = Date.now() - start;
    perCase.push({
      caseId: c.id,
      actualVerdict,
      actualScammerId,
      actualMissingFacts,
      scammerMatched: rankOfExpected !== null,
      latencyMs,
      expectedVerdict: c.expectedVerdict,
      expectedScammerId: c.expectedScammerId,
      expectedMissingFacts: c.expectedMissingFacts,
      inputType: c.inputType,
      rankOfExpectedScammer: rankOfExpected,
    });
  }

  const metrics = computeMetrics(perCase);

  const runId = await repo.persistRun({
    totalCases: cases.length,
    verdictAccuracy: metrics.verdictAccuracy,
    scammerRecallAt1: metrics.scammerRecallAt1,
    scammerMrr: metrics.scammerMrr,
    missingFactsF1: metrics.missingFactsF1,
    p95LatencyMs: metrics.p95LatencyMs,
    results: perCase.map((p) => ({
      caseId: p.caseId,
      actualVerdict: p.actualVerdict,
      actualScammerId: p.actualScammerId,
      actualMissingFacts: p.actualMissingFacts,
      scammerMatched: p.scammerMatched,
      latencyMs: p.latencyMs,
    })),
  });

  const run = await repo.findRun(runId);
  if (!run) throw new Error('eval run not persisted');
  return toSummary(run);
}

export async function listRuns(limit = 20) {
  const rows = await repo.listRuns(limit);
  return { items: rows.map(toSummary) };
}

function toSummary(run: Awaited<ReturnType<typeof repo.findRun>>): AiEvalSummary {
  if (!run) throw new Error('null run');
  return {
    id: run.id,
    runAt: run.runAt.toISOString(),
    totalCases: run.totalCases,
    verdictAccuracy: run.verdictAccuracy,
    scammerRecallAt1: run.scammerRecallAt1,
    scammerMrr: run.scammerMrr,
    missingFactsF1: run.missingFactsF1,
    p95LatencyMs: run.p95LatencyMs,
  };
}

function computeMetrics(perCase: Array<{
  actualVerdict: string;
  expectedVerdict: string;
  expectedScammerId: string | null;
  scammerMatched: boolean;
  rankOfExpectedScammer: number | null;
  actualMissingFacts: string[];
  expectedMissingFacts: string[];
  inputType: string;
  latencyMs: number;
}>): {
  verdictAccuracy: number;
  scammerRecallAt1: number;
  scammerMrr: number;
  missingFactsF1: number;
  p95LatencyMs: number;
} {
  const total = perCase.length;
  const correctVerdicts = perCase.filter((p) => p.actualVerdict === p.expectedVerdict).length;
  const verdictAccuracy = total === 0 ? 0 : correctVerdicts / total;

  // Recall@1 + MRR only over cases that have an expected scammer.
  const withExpected = perCase.filter((p) => p.expectedScammerId !== null);
  const recallAt1 = withExpected.length === 0
    ? 0
    : withExpected.filter((p) => p.rankOfExpectedScammer === 1).length / withExpected.length;
  const mrr = withExpected.length === 0
    ? 0
    : withExpected.reduce(
        (sum, p) => sum + (p.rankOfExpectedScammer ? 1 / p.rankOfExpectedScammer : 0),
        0,
      ) / withExpected.length;

  // F1 over the union of expected + actual missing-facts on text cases.
  const textCases = perCase.filter((p) => p.inputType === 'text');
  let tp = 0;
  let fp = 0;
  let fn = 0;
  for (const p of textCases) {
    const expected = new Set(p.expectedMissingFacts);
    const actual = new Set(p.actualMissingFacts);
    for (const f of actual) {
      if (expected.has(f)) tp++;
      else fp++;
    }
    for (const f of expected) {
      if (!actual.has(f)) fn++;
    }
  }
  const precision = tp + fp === 0 ? 0 : tp / (tp + fp);
  const recall = tp + fn === 0 ? 0 : tp / (tp + fn);
  const missingFactsF1 = precision + recall === 0
    ? 0
    : (2 * precision * recall) / (precision + recall);

  // p95 latency.
  const sorted = perCase.map((p) => p.latencyMs).sort((a, b) => a - b);
  const p95Index = Math.min(sorted.length - 1, Math.floor(0.95 * sorted.length));
  const p95LatencyMs = sorted.length === 0 ? 0 : sorted[p95Index]!;

  return {
    verdictAccuracy,
    scammerRecallAt1: recallAt1,
    scammerMrr: mrr,
    missingFactsF1,
    p95LatencyMs,
  };
}

// Ensure a system "synthetic" user row exists for Ask AI evaluation calls.
// Returns its internal id, or null if creation failed (tests may run without
// a writable users table — Ask AI is then skipped for text cases).
async function ensureSyntheticUser(): Promise<string | null> {
  const prisma = getPrisma();
  try {
    const existing = await prisma.user.findFirst({
      where: { firebaseUid: ASK_AI_USER_ID_LABEL },
      select: { id: true },
    });
    if (existing) return existing.id;
    const created = await prisma.user.create({
      data: {
        firebaseUid: ASK_AI_USER_ID_LABEL,
        displayName: 'AI Eval Synthetic',
        role: 'user',
      },
      select: { id: true },
    });
    return created.id;
  } catch (err) {
    console.error('[ai-eval] could not create synthetic user', { err });
    return null;
  }
}

// Re-exports used in tests / dev.
export { computeAiScore, canonicalEmbedInput, findScammerById };
