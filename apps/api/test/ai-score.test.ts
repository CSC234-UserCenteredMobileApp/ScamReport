import { afterEach, beforeEach, describe, expect, mock, test } from 'bun:test';

// ---------------------------------------------------------------------------
// Mock retrieval — drives `computeAiScore` behaviour deterministically.
// ---------------------------------------------------------------------------

let mockResults: Array<{ reportId: string; similarity: number; scammerId?: string | null }> = [];
let mockShouldThrow = false;

mock.module('../src/core/rag/retrieval', () => ({
  searchSimilarReports: async () => {
    if (mockShouldThrow) throw new Error('mock: embedding pipeline failed');
    return mockResults;
  },
}));

import { computeAiScore } from '../src/core/ai-score';

const originalError = console.error;
let errorCalls: Array<unknown[]> = [];

beforeEach(() => {
  mockResults = [];
  mockShouldThrow = false;
  errorCalls = [];
  console.error = (...args: unknown[]) => {
    errorCalls.push(args);
  };
});

afterEach(() => {
  console.error = originalError;
});

describe('computeAiScore', () => {
  test('high tier when top-1 similarity ≥ 0.85', async () => {
    mockResults = [
      { reportId: 'r1', similarity: 0.92 },
      { reportId: 'r2', similarity: 0.9 },
      { reportId: 'r3', similarity: 0.88 },
      { reportId: 'r4', similarity: 0.6 },
      { reportId: 'r5', similarity: 0.5 },
    ];
    const result = await computeAiScore('phishing sms about parcel');
    // Score is now max(top1, topKAvg) * 100. top1 = 0.92 → 92.
    expect(result.aiScore).toBe(92);
    expect(result.aiConfidence).toBe('high');
  });

  test('high tier even when neighbours dilute the top-3 average', async () => {
    // Pre-fix this case scored 'medium' (top-3 avg ≈ 0.717). After the
    // top-1 priority change, a 0.95 top-1 stands on its own.
    mockResults = [
      { reportId: 'r1', similarity: 0.95 },
      { reportId: 'r2', similarity: 0.6 },
      { reportId: 'r3', similarity: 0.6 },
    ];
    const result = await computeAiScore('one strong match');
    expect(result.aiScore).toBe(95);
    expect(result.aiConfidence).toBe('high');
  });

  test('medium tier when top-1 ∈ [0.70, 0.85)', async () => {
    mockResults = [
      { reportId: 'r1', similarity: 0.78 },
      { reportId: 'r2', similarity: 0.6 },
      { reportId: 'r3', similarity: 0.55 },
    ];
    const result = await computeAiScore('borderline top-1');
    expect(result.aiConfidence).toBe('medium');
    expect(result.aiScore).toBe(78);
  });

  test('medium tier when top-1 < 0.70 but top-3 avg ≥ 0.75 (cluster signal)', async () => {
    mockResults = [
      { reportId: 'r1', similarity: 0.69 },
      { reportId: 'r2', similarity: 0.78 },
      { reportId: 'r3', similarity: 0.78 },
    ];
    const result = await computeAiScore('weak-top1 strong-cluster');
    // top-1 is sub-medium but the cluster average bumps confidence to medium.
    expect(result.aiConfidence).toBe('medium');
    // Score still uses max(top1, avg) so the displayed number reflects the
    // stronger of the two signals.
    expect(result.aiScore).toBe(75);
  });

  test('low tier when both top-1 and top-3 avg are weak', async () => {
    mockResults = [
      { reportId: 'r1', similarity: 0.5 },
      { reportId: 'r2', similarity: 0.45 },
      { reportId: 'r3', similarity: 0.4 },
    ];
    const result = await computeAiScore('weak match');
    expect(result.aiConfidence).toBe('low');
    expect(result.aiScore).toBeLessThan(70);
  });

  test('returns null + unknown when no embeddings exist; logs no_embeddings phase', async () => {
    mockResults = [];
    const result = await computeAiScore('fresh corpus', { reportId: 'r0' });
    expect(result.aiScore).toBeNull();
    expect(result.aiConfidence).toBe('unknown');
    expect(errorCalls.length).toBe(1);
    const [tag, payload] = errorCalls[0]!;
    expect(tag).toBe('[ai-score]');
    expect(payload).toMatchObject({ phase: 'no_embeddings', reportId: 'r0' });
  });

  test('returns null + unknown when retrieval throws; logs embedding_failed phase', async () => {
    mockShouldThrow = true;
    const result = await computeAiScore('anything', { reportId: 'r9' });
    expect(result.aiScore).toBeNull();
    expect(result.aiConfidence).toBe('unknown');
    expect(errorCalls.length).toBe(1);
    const [tag, payload] = errorCalls[0]!;
    expect(tag).toBe('[ai-score]');
    expect((payload as { phase: string }).phase).toBe('embedding_failed');
  });

  test('2+ top-K share scammerId → confidence bumps + score floor honoured', async () => {
    // top-1 0.72 (medium); without the cluster bump confidence stays
    // medium and the score is 72. With cluster, confidence bumps to 'high'
    // and the SCAMMER_CLUSTER_SCORE_FLOOR floor pulls the score to 75.
    mockResults = [
      { reportId: 'r1', similarity: 0.72, scammerId: 'scam-1' },
      { reportId: 'r2', similarity: 0.62, scammerId: 'scam-1' },
      { reportId: 'r3', similarity: 0.55, scammerId: null },
      { reportId: 'r4', similarity: 0.5, scammerId: null },
      { reportId: 'r5', similarity: 0.4, scammerId: null },
    ];
    const result = await computeAiScore('cluster test');
    expect(result.aiConfidence).toBe('high');
    expect(result.aiScore).toBeGreaterThanOrEqual(75);
    expect(result.topScammerId).toBe('scam-1');
    expect(result.topScammerSiblingCount).toBe(2);
  });

  test('only 1 top-K shares scammerId → no bump, topScammerId is null', async () => {
    mockResults = [
      { reportId: 'r1', similarity: 0.72, scammerId: 'scam-1' },
      { reportId: 'r2', similarity: 0.62, scammerId: 'scam-2' },
      { reportId: 'r3', similarity: 0.55, scammerId: null },
    ];
    const result = await computeAiScore('no cluster');
    expect(result.aiConfidence).toBe('medium');
    expect(result.topScammerId).toBeNull();
    expect(result.topScammerSiblingCount).toBe(0);
  });

  test('cluster never downgrades a high tier', async () => {
    mockResults = [
      { reportId: 'r1', similarity: 0.95, scammerId: 'scam-1' },
      { reportId: 'r2', similarity: 0.5, scammerId: 'scam-1' },
    ];
    const result = await computeAiScore('high stays high');
    expect(result.aiConfidence).toBe('high');
    expect(result.aiScore).toBe(95);
  });

  test('score uses the dominant of (top-1, top-3 avg)', async () => {
    // Top-3 avg = 0.9, top-1 = 0.9 → score = 90.
    mockResults = [
      { reportId: 'r1', similarity: 0.9 },
      { reportId: 'r2', similarity: 0.9 },
      { reportId: 'r3', similarity: 0.9 },
      { reportId: 'r4', similarity: 0.0 },
      { reportId: 'r5', similarity: 0.0 },
    ];
    const result = await computeAiScore('balanced cluster');
    expect(result.aiScore).toBe(90);
    expect(result.aiConfidence).toBe('high');
  });
});

describe('canonicalEmbedInput', () => {
  test('includes title, description, target identifier, and category', async () => {
    const { canonicalEmbedInput } = await import('../src/core/ai-score');
    const text = canonicalEmbedInput({
      title: 'Kerry parcel SMS',
      description: 'Claim parcel, click link, enter card details.',
      targetIdentifier: 'http://kerry-th.scam',
      scamType: { labelEn: 'Phishing SMS', labelTh: 'ฟิชชิง SMS' },
    });
    expect(text).toContain('Kerry parcel SMS');
    expect(text).toContain('Claim parcel');
    expect(text).toContain('target: http://kerry-th.scam');
    expect(text).toContain('category: Phishing SMS');
  });

  test('omits target / category lines when absent', async () => {
    const { canonicalEmbedInput } = await import('../src/core/ai-score');
    const text = canonicalEmbedInput({
      title: 't',
      description: 'd',
      targetIdentifier: null,
      scamType: null,
    });
    expect(text).toBe('t\nd');
  });

  test('appends person.fullName line when linked scammer carries a person', async () => {
    const { canonicalEmbedInput } = await import('../src/core/ai-score');
    const text = canonicalEmbedInput({
      title: 'Tax scam call',
      description: 'Caller demanded transfer to verification account.',
      targetIdentifier: '+6629991234',
      scamType: { labelEn: 'Phone Impersonation', labelTh: 'การปลอมตัว' },
      scammer: {
        displayName: 'Revenue Dept Impersonator',
        aliases: ['Officer Anan'],
        person: { fullName: 'Khun Somchai Wongchai' },
      },
    });
    expect(text).toContain('scammer: Revenue Dept Impersonator / Officer Anan');
    expect(text).toContain('person: Khun Somchai Wongchai');
  });

  test('skips person line when scammer has no linked person', async () => {
    const { canonicalEmbedInput } = await import('../src/core/ai-score');
    const text = canonicalEmbedInput({
      title: 't',
      description: 'd',
      scammer: { displayName: 'Anon Ring', aliases: [], person: null },
    });
    expect(text).toContain('scammer: Anon Ring');
    expect(text).not.toContain('person:');
  });
});
