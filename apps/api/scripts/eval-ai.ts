// Headless AI accuracy harness. Runs every case in `apps/api/eval/cases.ts`
// through `runCheck()`, computes verdict accuracy + scammer recall@1 + MRR,
// prints a JSON report.
//
// Designed to run from a cron (or GitHub Action) — exit code is non-zero
// when verdictAccuracy drops below MIN_VERDICT_ACCURACY so an alert fires.
//
// Run from apps/api:
//   bun run scripts/eval-ai.ts [--threshold=0.7] [--quiet]
//
// Output (stdout):
//   { runAt, totalCases, verdictAccuracy, scammerRecallAt1, mrr,
//     p95LatencyMs, results: [...] }

import { config } from 'dotenv';
import { resolve } from 'path';
config({ path: resolve(import.meta.dirname, '../.env') });

import { runCheck } from '../src/features/check/check.service';
import { getPrisma } from '../src/core/db/client';
import { EVAL_CASES, type EvalCase } from '../eval/cases';

const DEFAULT_THRESHOLD = 0.7;

interface CaseResult {
  label: string;
  inputType: string;
  expectedVerdict: string;
  actualVerdict: string;
  expectedScammerDisplayName: string | null;
  actualScammerDisplayName: string | null;
  rankOfExpected: number | null;
  verdictHit: boolean;
  latencyMs: number;
}

async function resolveExpectedScammerIds(): Promise<Map<string, string>> {
  const prisma = getPrisma();
  const wanted = new Set<string>();
  for (const c of EVAL_CASES) {
    if (c.expectedScammerDisplayName) wanted.add(c.expectedScammerDisplayName);
  }
  if (wanted.size === 0) return new Map();
  const rows = await prisma.scammer.findMany({
    where: { displayName: { in: Array.from(wanted) } },
    select: { id: true, displayName: true },
  });
  return new Map(rows.map((r) => [r.displayName, r.id]));
}

async function runOne(
  c: EvalCase,
  expectedByName: Map<string, string>,
): Promise<CaseResult> {
  const start = Date.now();
  const result = await runCheck(c.inputPayload, c.inputType, null);
  const latencyMs = Date.now() - start;

  const expectedId = c.expectedScammerDisplayName
    ? expectedByName.get(c.expectedScammerDisplayName) ?? null
    : null;
  const actualId = result.matchedScammer?.summary.id ?? null;
  const actualName = result.matchedScammer?.summary.displayName ?? null;

  let rankOfExpected: number | null = null;
  if (expectedId) {
    if (actualId === expectedId) rankOfExpected = 1;
    else if (result.matches.length > 0) {
      // Resolve each matched report's scammerId; if the expected scammer
      // appears further down, record its rank for MRR.
      const prisma = getPrisma();
      const rows = await prisma.report.findMany({
        where: { id: { in: result.matches.map((m) => m.id) } },
        select: { id: true, scammerId: true },
      });
      const idByReport = new Map(rows.map((r) => [r.id, r.scammerId]));
      for (let i = 0; i < result.matches.length; i++) {
        if (idByReport.get(result.matches[i]!.id) === expectedId) {
          rankOfExpected = i + 1;
          break;
        }
      }
    }
  }

  return {
    label: c.label,
    inputType: c.inputType,
    expectedVerdict: c.expectedVerdict,
    actualVerdict: result.verdict,
    expectedScammerDisplayName: c.expectedScammerDisplayName ?? null,
    actualScammerDisplayName: actualName,
    rankOfExpected,
    verdictHit: result.verdict === c.expectedVerdict,
    latencyMs,
  };
}

function percentile(values: number[], p: number): number {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const idx = Math.min(sorted.length - 1, Math.floor(p * sorted.length));
  return sorted[idx]!;
}

async function main() {
  const args = process.argv.slice(2);
  const quiet = args.includes('--quiet');
  const thresholdArg = args.find((a) => a.startsWith('--threshold='));
  const threshold = thresholdArg
    ? Number(thresholdArg.split('=')[1])
    : DEFAULT_THRESHOLD;

  const expectedByName = await resolveExpectedScammerIds();
  const results: CaseResult[] = [];
  for (const c of EVAL_CASES) {
    const r = await runOne(c, expectedByName);
    results.push(r);
    if (!quiet) {
      const tick = r.verdictHit ? '✓' : '✗';
      process.stdout.write(
        `${tick} ${r.label.padEnd(36)} expect=${r.expectedVerdict.padEnd(11)} actual=${r.actualVerdict.padEnd(11)} rank=${r.rankOfExpected ?? '-'}\n`,
      );
    }
  }

  const total = results.length;
  const correctVerdicts = results.filter((r) => r.verdictHit).length;
  const verdictAccuracy = total === 0 ? 0 : correctVerdicts / total;

  const withExpected = results.filter((r) => r.expectedScammerDisplayName !== null);
  const recallAt1 =
    withExpected.length === 0
      ? 0
      : withExpected.filter((r) => r.rankOfExpected === 1).length / withExpected.length;
  const mrr =
    withExpected.length === 0
      ? 0
      : withExpected.reduce(
          (sum, r) => sum + (r.rankOfExpected ? 1 / r.rankOfExpected : 0),
          0,
        ) / withExpected.length;
  const p95LatencyMs = percentile(
    results.map((r) => r.latencyMs),
    0.95,
  );

  const summary = {
    runAt: new Date().toISOString(),
    totalCases: total,
    verdictAccuracy: Number(verdictAccuracy.toFixed(4)),
    scammerRecallAt1: Number(recallAt1.toFixed(4)),
    mrr: Number(mrr.toFixed(4)),
    p95LatencyMs,
    threshold,
    passed: verdictAccuracy >= threshold,
    results,
  };

  console.log('\n' + JSON.stringify(summary, null, 2));

  if (!summary.passed) {
    console.error(
      `\n[eval-ai] verdictAccuracy ${verdictAccuracy.toFixed(3)} below threshold ${threshold} — failing cron.`,
    );
    process.exit(1);
  }
  process.exit(0);
}

main().catch((err) => {
  console.error('[eval-ai] crashed:', err);
  process.exit(2);
});
