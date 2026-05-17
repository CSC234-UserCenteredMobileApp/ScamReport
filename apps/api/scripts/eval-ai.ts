// Headless AI accuracy harness. Runs every case in `apps/api/eval/cases.ts`
// through `runCheck()`, computes verdict accuracy + per-type breakdown +
// confusion matrix + scammer recall@1 + MRR, and appends a one-line summary
// to `apps/api/eval/history.jsonl` for longitudinal drift tracking.
//
// Designed to run from a cron (or GitHub Action) — exit code is non-zero
// when verdictAccuracy drops below the configured threshold so an alert fires.
//
// Run from apps/api:
//   bun run scripts/eval-ai.ts \
//     [--threshold=0.7] [--quiet] [--format=json|table] [--no-history]
//
// Output (stdout):
//   --format=json  → full JSON summary
//   --format=table → human-readable report
//
// Exit codes: 0 pass, 1 threshold fail, 2 crash.

import { config } from 'dotenv';
import { readFileSync, existsSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

config({ path: resolve(import.meta.dirname, '../.env') });

import { runCheck } from '../src/features/check/check.service';
import { getPrisma } from '../src/core/db/client';
import { EVAL_CASES, type EvalCase } from '../eval/cases';
import {
  buildConfusionMatrix,
  buildHistoryEntry,
  groupByType,
  percentile,
  pruneHistory,
  type CaseResult,
} from '../eval/metrics';
import { formatTableReport } from '../eval/format';

const DEFAULT_THRESHOLD = 0.7;
const HISTORY_MAX_LINES = 365;
const HISTORY_PATH = resolve(import.meta.dirname, '../eval/history.jsonl');
const LATEST_PATH = resolve(import.meta.dirname, '../eval/latest.json');
const REPO_ROOT = resolve(import.meta.dirname, '../../..');

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
    tags: c.tags ?? [],
  };
}

// Resolve git sha without shelling out. Prefers GITHUB_SHA (set by Actions),
// falls back to reading .git/HEAD and its referenced ref file directly.
function resolveGitSha(): string | null {
  const env = process.env.GITHUB_SHA;
  if (env && /^[0-9a-f]{40}$/i.test(env)) return env;
  try {
    const headPath = resolve(REPO_ROOT, '.git/HEAD');
    if (!existsSync(headPath)) return null;
    const head = readFileSync(headPath, 'utf8').trim();
    if (head.startsWith('ref: ')) {
      const ref = head.slice(5).trim();
      const refPath = resolve(REPO_ROOT, '.git', ref);
      if (!existsSync(refPath)) return null;
      const sha = readFileSync(refPath, 'utf8').trim();
      return /^[0-9a-f]{40}$/i.test(sha) ? sha : null;
    }
    return /^[0-9a-f]{40}$/i.test(head) ? head : null;
  } catch {
    return null;
  }
}

function appendHistoryLine(entry: object): void {
  const lines = existsSync(HISTORY_PATH)
    ? readFileSync(HISTORY_PATH, 'utf8')
        .split('\n')
        .filter((l) => l.length > 0)
    : [];
  lines.push(JSON.stringify(entry));
  const pruned = pruneHistory(lines, HISTORY_MAX_LINES);
  writeFileSync(HISTORY_PATH, pruned.join('\n') + '\n');
}

interface CliFlags {
  threshold: number;
  quiet: boolean;
  format: 'json' | 'table';
  noHistory: boolean;
}

function parseFlags(argv: string[]): CliFlags {
  const quiet = argv.includes('--quiet');
  const noHistory = argv.includes('--no-history');
  const thresholdArg = argv.find((a) => a.startsWith('--threshold='));
  const threshold = thresholdArg
    ? Number(thresholdArg.split('=')[1])
    : DEFAULT_THRESHOLD;
  const formatArg = argv.find((a) => a.startsWith('--format='));
  const formatVal = formatArg ? formatArg.split('=')[1] : 'json';
  const format: 'json' | 'table' = formatVal === 'table' ? 'table' : 'json';
  return { threshold, quiet, format, noHistory };
}

async function main() {
  const flags = parseFlags(process.argv.slice(2));

  const expectedByName = await resolveExpectedScammerIds();
  const results: CaseResult[] = [];
  for (const c of EVAL_CASES) {
    const r = await runOne(c, expectedByName);
    results.push(r);
    if (!flags.quiet && flags.format !== 'table') {
      const tick = r.verdictHit ? 'ok' : 'XX';
      process.stdout.write(
        `${tick} ${r.label.padEnd(36)} expect=${r.expectedVerdict.padEnd(11)} ` +
          `actual=${r.actualVerdict.padEnd(11)} rank=${r.rankOfExpected ?? '-'}\n`,
      );
    }
  }

  const total = results.length;
  const correctVerdicts = results.filter((r) => r.verdictHit).length;
  const verdictAccuracy = total === 0 ? 0 : correctVerdicts / total;

  const withExpected = results.filter(
    (r) => r.expectedScammerDisplayName !== null,
  );
  const recallAt1 =
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
  const p95LatencyMs = percentile(
    results.map((r) => r.latencyMs),
    0.95,
  );

  const byType = groupByType(results);
  const confusionMatrix = buildConfusionMatrix(results);
  const gitSha = resolveGitSha();
  const runAt = new Date().toISOString();
  const passed = verdictAccuracy >= flags.threshold;

  const summary = {
    runAt,
    gitSha,
    totalCases: total,
    verdictAccuracy: Number(verdictAccuracy.toFixed(4)),
    scammerRecallAt1: Number(recallAt1.toFixed(4)),
    mrr: Number(mrr.toFixed(4)),
    p95LatencyMs,
    byType,
    confusionMatrix,
    threshold: flags.threshold,
    passed,
    results,
  };

  if (flags.format === 'table') {
    console.log('\n' + formatTableReport(summary));
  } else {
    console.log('\n' + JSON.stringify(summary, null, 2));
  }

  if (!flags.noHistory) {
    try {
      appendHistoryLine(
        buildHistoryEntry({
          runAt,
          gitSha,
          totalCases: total,
          verdictAccuracy: summary.verdictAccuracy,
          byType,
          threshold: flags.threshold,
          passed,
        }),
      );
    } catch (err) {
      console.error('[eval-ai] failed to append history line:', err);
    }
    try {
      writeFileSync(LATEST_PATH, JSON.stringify(summary, null, 2));
    } catch (err) {
      console.error('[eval-ai] failed to write latest.json:', err);
    }
  }

  if (!passed) {
    console.error(
      `\n[eval-ai] verdictAccuracy ${verdictAccuracy.toFixed(3)} below threshold ${flags.threshold} — failing cron.`,
    );
    process.exit(1);
  }
  process.exit(0);
}

main().catch((err) => {
  console.error('[eval-ai] crashed:', err);
  process.exit(2);
});
