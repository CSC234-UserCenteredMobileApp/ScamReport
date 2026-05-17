// Unit tests for the eval harness pure helpers + case-file lint. These tests
// must not require a database or any external service — they exercise the
// `eval/metrics.ts` module and validate the shape of `eval/cases.ts`.

import { describe, expect, test } from 'bun:test';
import { EVAL_CASES, type EvalVerdict } from '../eval/cases';
import {
  buildConfusionMatrix,
  groupByType,
  percentile,
  pruneHistory,
  type CaseResult,
} from '../eval/metrics';

const VALID_VERDICTS: EvalVerdict[] = ['scam', 'suspicious', 'safe', 'unknown'];

function fakeResult(over: Partial<CaseResult>): CaseResult {
  return {
    label: 'fake',
    inputType: 'phone',
    expectedVerdict: 'safe',
    actualVerdict: 'safe',
    expectedScammerDisplayName: null,
    actualScammerDisplayName: null,
    rankOfExpected: null,
    verdictHit: true,
    latencyMs: 100,
    tags: [],
    ...over,
  };
}

describe('percentile', () => {
  test('empty array returns 0', () => {
    expect(percentile([], 0.95)).toBe(0);
  });

  test('single value returns that value', () => {
    expect(percentile([42], 0.95)).toBe(42);
  });

  test('uses floor-index convention on 100 elements', () => {
    const values = Array.from({ length: 100 }, (_, i) => i + 1);
    // idx = floor(0.95 * 100) = 95; sorted[95] = 96
    expect(percentile(values, 0.95)).toBe(96);
  });

  test('clamps to last element', () => {
    expect(percentile([1, 2, 3], 1)).toBe(3);
  });
});

describe('groupByType', () => {
  const fixture: CaseResult[] = [
    fakeResult({ inputType: 'phone', verdictHit: true, latencyMs: 50 }),
    fakeResult({ inputType: 'phone', verdictHit: false, latencyMs: 200 }),
    fakeResult({
      inputType: 'url',
      verdictHit: true,
      expectedScammerDisplayName: 'X',
      rankOfExpected: 1,
      latencyMs: 80,
    }),
    fakeResult({
      inputType: 'url',
      verdictHit: true,
      expectedScammerDisplayName: 'Y',
      rankOfExpected: 2,
      latencyMs: 90,
    }),
    fakeResult({ inputType: 'text', verdictHit: true, latencyMs: 300 }),
    fakeResult({ inputType: 'text', verdictHit: true, latencyMs: 400 }),
  ];

  const grouped = groupByType(fixture);

  test('partitions by type and counts', () => {
    expect(grouped.phone.n).toBe(2);
    expect(grouped.url.n).toBe(2);
    expect(grouped.text.n).toBe(2);
  });

  test('per-type verdictAccuracy computed correctly', () => {
    expect(grouped.phone.verdictAccuracy).toBe(0.5);
    expect(grouped.url.verdictAccuracy).toBe(1);
    expect(grouped.text.verdictAccuracy).toBe(1);
  });

  test('per-type recall@1 ignores cases without expected scammer', () => {
    expect(grouped.url.scammerRecallAt1).toBe(0.5);
    expect(grouped.phone.scammerRecallAt1).toBe(0);
  });

  test('per-type mrr', () => {
    // url: ranks [1, 2] → (1 + 1/2) / 2 = 0.75
    expect(grouped.url.mrr).toBe(0.75);
  });

  test('empty type yields zeroed metrics with shape preserved', () => {
    const out = groupByType([]);
    expect(out.phone).toEqual({
      n: 0,
      verdictAccuracy: 0,
      scammerRecallAt1: 0,
      mrr: 0,
      p95LatencyMs: 0,
    });
    expect(out.url.n).toBe(0);
    expect(out.text.n).toBe(0);
  });
});

describe('buildConfusionMatrix', () => {
  test('initializes all 16 cells to 0', () => {
    const m = buildConfusionMatrix([]);
    for (const exp of VALID_VERDICTS) {
      for (const act of VALID_VERDICTS) {
        expect(m[exp][act]).toBe(0);
      }
    }
  });

  test('counts (expected, actual) pairs', () => {
    const m = buildConfusionMatrix([
      fakeResult({ expectedVerdict: 'scam', actualVerdict: 'scam' }),
      fakeResult({ expectedVerdict: 'scam', actualVerdict: 'safe' }),
      fakeResult({ expectedVerdict: 'safe', actualVerdict: 'safe' }),
      fakeResult({ expectedVerdict: 'safe', actualVerdict: 'scam' }),
    ]);
    expect(m.scam.scam).toBe(1);
    expect(m.scam.safe).toBe(1);
    expect(m.safe.safe).toBe(1);
    expect(m.safe.scam).toBe(1);
  });

  test('sum across all cells equals input length', () => {
    const results = [
      fakeResult({ expectedVerdict: 'scam', actualVerdict: 'suspicious' }),
      fakeResult({ expectedVerdict: 'unknown', actualVerdict: 'unknown' }),
      fakeResult({ expectedVerdict: 'safe', actualVerdict: 'scam' }),
    ];
    const m = buildConfusionMatrix(results);
    let sum = 0;
    for (const exp of VALID_VERDICTS) {
      for (const act of VALID_VERDICTS) sum += m[exp][act];
    }
    expect(sum).toBe(results.length);
  });
});

describe('pruneHistory', () => {
  test('returns unchanged when length <= max', () => {
    const input = ['a', 'b', 'c'];
    expect(pruneHistory(input, 5)).toEqual(input);
    expect(pruneHistory(input, 3)).toEqual(input);
  });

  test('trims oldest entries when length > max', () => {
    const input = ['a', 'b', 'c', 'd', 'e'];
    expect(pruneHistory(input, 3)).toEqual(['c', 'd', 'e']);
  });

  test('empty input', () => {
    expect(pruneHistory([], 5)).toEqual([]);
  });
});

describe('case file (cases.ts lint)', () => {
  test('every case has valid verdict', () => {
    for (const c of EVAL_CASES) {
      expect(VALID_VERDICTS).toContain(c.expectedVerdict);
    }
  });

  test('every scam case names an expected scammer (or null when intentional)', () => {
    // Allow null only for paraphrase/adversarial cases where no specific seeded
    // scammer matches — those are tagged. Strict matches must hit a scammer.
    for (const c of EVAL_CASES) {
      if (c.expectedVerdict === 'scam' && !c.tags?.includes('paraphrase')) {
        expect(c.expectedScammerDisplayName).not.toBeNull();
        expect(c.expectedScammerDisplayName).not.toBe(undefined);
      }
    }
  });

  test('case labels are unique', () => {
    const labels = EVAL_CASES.map((c) => c.label);
    expect(new Set(labels).size).toBe(labels.length);
  });

  test('case count is at least 50', () => {
    expect(EVAL_CASES.length).toBeGreaterThanOrEqual(50);
  });

  test('input types are valid', () => {
    const types = ['phone', 'url', 'text'];
    for (const c of EVAL_CASES) {
      expect(types).toContain(c.inputType);
    }
  });
});
