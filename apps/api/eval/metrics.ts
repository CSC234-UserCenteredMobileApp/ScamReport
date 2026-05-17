// Pure helpers for the headless AI accuracy harness. No DB, no Gemini, no I/O.
// Anything that needs a real client lives in scripts/eval-ai.ts.

import type { EvalInputType, EvalVerdict } from './cases';

export type { EvalInputType, EvalVerdict } from './cases';

export interface CaseResult {
  label: string;
  inputType: EvalInputType;
  expectedVerdict: EvalVerdict;
  actualVerdict: EvalVerdict;
  expectedScammerDisplayName: string | null;
  actualScammerDisplayName: string | null;
  rankOfExpected: number | null;
  verdictHit: boolean;
  latencyMs: number;
  tags: string[];
}

export interface TypeMetrics {
  n: number;
  verdictAccuracy: number;
  scammerRecallAt1: number;
  mrr: number;
  p95LatencyMs: number;
}

export type ConfusionMatrix = Record<EvalVerdict, Record<EvalVerdict, number>>;

export interface HistoryEntry {
  runAt: string;
  gitSha: string | null;
  totalCases: number;
  verdictAccuracy: number;
  byType: Record<EvalInputType, number>;
  threshold: number;
  passed: boolean;
}

const VERDICTS: readonly EvalVerdict[] = ['scam', 'suspicious', 'safe', 'unknown'];
const INPUT_TYPES: readonly EvalInputType[] = ['phone', 'url', 'text'];

export function percentile(values: number[], p: number): number {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const idx = Math.min(sorted.length - 1, Math.floor(p * sorted.length));
  return sorted[idx]!;
}

function emptyTypeMetrics(): TypeMetrics {
  return {
    n: 0,
    verdictAccuracy: 0,
    scammerRecallAt1: 0,
    mrr: 0,
    p95LatencyMs: 0,
  };
}

function aggregate(results: CaseResult[]): TypeMetrics {
  const n = results.length;
  if (n === 0) return emptyTypeMetrics();
  const correct = results.filter((r) => r.verdictHit).length;
  const withExpected = results.filter(
    (r) => r.expectedScammerDisplayName !== null,
  );
  const recall =
    withExpected.length === 0
      ? 0
      : withExpected.filter((r) => r.rankOfExpected === 1).length /
        withExpected.length;
  const mrr =
    withExpected.length === 0
      ? 0
      : withExpected.reduce(
          (sum, r) => sum + (r.rankOfExpected ? 1 / r.rankOfExpected : 0),
          0,
        ) / withExpected.length;
  return {
    n,
    verdictAccuracy: Number((correct / n).toFixed(4)),
    scammerRecallAt1: Number(recall.toFixed(4)),
    mrr: Number(mrr.toFixed(4)),
    p95LatencyMs: percentile(
      results.map((r) => r.latencyMs),
      0.95,
    ),
  };
}

export function groupByType(
  results: CaseResult[],
): Record<EvalInputType, TypeMetrics> {
  const out = {} as Record<EvalInputType, TypeMetrics>;
  for (const t of INPUT_TYPES) {
    out[t] = aggregate(results.filter((r) => r.inputType === t));
  }
  return out;
}

export function buildConfusionMatrix(results: CaseResult[]): ConfusionMatrix {
  const matrix = {} as ConfusionMatrix;
  for (const exp of VERDICTS) {
    matrix[exp] = {} as Record<EvalVerdict, number>;
    for (const act of VERDICTS) matrix[exp][act] = 0;
  }
  for (const r of results) {
    matrix[r.expectedVerdict][r.actualVerdict]++;
  }
  return matrix;
}

export function buildHistoryEntry(args: {
  runAt: string;
  gitSha: string | null;
  totalCases: number;
  verdictAccuracy: number;
  byType: Record<EvalInputType, TypeMetrics>;
  threshold: number;
  passed: boolean;
}): HistoryEntry {
  return {
    runAt: args.runAt,
    gitSha: args.gitSha,
    totalCases: args.totalCases,
    verdictAccuracy: args.verdictAccuracy,
    byType: {
      phone: args.byType.phone.verdictAccuracy,
      url: args.byType.url.verdictAccuracy,
      text: args.byType.text.verdictAccuracy,
    },
    threshold: args.threshold,
    passed: args.passed,
  };
}

export function pruneHistory(lines: string[], max: number): string[] {
  if (lines.length <= max) return lines;
  return lines.slice(lines.length - max);
}
