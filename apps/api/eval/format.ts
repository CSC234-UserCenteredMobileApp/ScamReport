// Pretty-print renderer for the AI eval summary. ASCII only; lines kept under
// ~100 cols so terminals and CI logs render cleanly.

import type {
  CaseResult,
  ConfusionMatrix,
  EvalInputType,
  EvalVerdict,
  TypeMetrics,
} from './metrics';

export interface FormatSummary {
  runAt: string;
  gitSha: string | null;
  totalCases: number;
  verdictAccuracy: number;
  scammerRecallAt1: number;
  mrr: number;
  p95LatencyMs: number;
  byType: Record<EvalInputType, TypeMetrics>;
  confusionMatrix: ConfusionMatrix;
  threshold: number;
  passed: boolean;
  results: CaseResult[];
}

const VERDICTS: EvalVerdict[] = ['scam', 'suspicious', 'safe', 'unknown'];
const TYPES: EvalInputType[] = ['phone', 'url', 'text'];

function pct(n: number): string {
  return (n * 100).toFixed(1) + '%';
}

function pad(s: string, n: number): string {
  return s.length >= n ? s.slice(0, n) : s + ' '.repeat(n - s.length);
}

export function formatTableReport(s: FormatSummary): string {
  const lines: string[] = [];
  const sha = s.gitSha ? s.gitSha.slice(0, 7) : '-';
  const status = s.passed ? 'PASS' : 'FAIL';
  lines.push(
    `AI eval — ${s.runAt} sha=${sha} n=${s.totalCases} acc=${pct(s.verdictAccuracy)} ` +
      `recall@1=${pct(s.scammerRecallAt1)} mrr=${s.mrr.toFixed(3)} p95=${s.p95LatencyMs}ms ` +
      `[${status} @ threshold=${pct(s.threshold)}]`,
  );
  lines.push('');

  lines.push('Per-type metrics:');
  lines.push(
    '  ' +
      pad('type', 8) +
      pad('n', 5) +
      pad('verdict', 11) +
      pad('recall@1', 11) +
      pad('mrr', 8) +
      'p95ms',
  );
  for (const t of TYPES) {
    const m = s.byType[t];
    lines.push(
      '  ' +
        pad(t, 8) +
        pad(String(m.n), 5) +
        pad(pct(m.verdictAccuracy), 11) +
        pad(pct(m.scammerRecallAt1), 11) +
        pad(m.mrr.toFixed(3), 8) +
        String(m.p95LatencyMs),
    );
  }
  lines.push('');

  lines.push('Confusion matrix (rows=expected, cols=actual; * = diagonal):');
  lines.push('  ' + pad('', 12) + VERDICTS.map((v) => pad(v, 12)).join(''));
  for (const exp of VERDICTS) {
    const cells = VERDICTS.map((act) => {
      const n = s.confusionMatrix[exp][act];
      const marker = exp === act && n > 0 ? '*' : ' ';
      return pad(`${marker}${n}`, 12);
    }).join('');
    lines.push('  ' + pad(exp, 12) + cells);
  }
  lines.push('');

  const fails = s.results.filter((r) => !r.verdictHit);
  if (fails.length === 0) {
    lines.push('No failing cases.');
  } else {
    lines.push(`Failing cases (${fails.length}):`);
    for (const r of fails) {
      lines.push(
        `  x ${pad(r.label, 36)} type=${pad(r.inputType, 6)} ` +
          `exp=${pad(r.expectedVerdict, 11)} got=${r.actualVerdict}`,
      );
    }
  }

  return lines.join('\n');
}
