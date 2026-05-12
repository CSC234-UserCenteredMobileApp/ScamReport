import { afterEach, beforeEach, describe, expect, mock, test } from 'bun:test';

// ---------------------------------------------------------------------------
// Mock retrieval — drives `computeAiScore` behaviour deterministically.
// ---------------------------------------------------------------------------

let mockResults: Array<{ reportId: string; similarity: number }> = [];
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
  test('high tier when avg similarity ≥ 0.85', async () => {
    mockResults = [
      { reportId: 'r1', similarity: 0.92 },
      { reportId: 'r2', similarity: 0.9 },
      { reportId: 'r3', similarity: 0.88 },
      { reportId: 'r4', similarity: 0.6 },
      { reportId: 'r5', similarity: 0.5 },
    ];
    const result = await computeAiScore('phishing sms about parcel');
    expect(result.aiScore).toBe(90);
    expect(result.aiConfidence).toBe('high');
  });

  test('medium tier when avg similarity in [0.70, 0.85)', async () => {
    mockResults = [
      { reportId: 'r1', similarity: 0.78 },
      { reportId: 'r2', similarity: 0.74 },
      { reportId: 'r3', similarity: 0.7 },
    ];
    const result = await computeAiScore('borderline match');
    expect(result.aiConfidence).toBe('medium');
    expect(result.aiScore).toBeGreaterThanOrEqual(70);
    expect(result.aiScore).toBeLessThan(85);
  });

  test('low tier when avg similarity < 0.70', async () => {
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

  test('averages only top-3 even when more results are supplied', async () => {
    mockResults = [
      { reportId: 'r1', similarity: 0.9 },
      { reportId: 'r2', similarity: 0.9 },
      { reportId: 'r3', similarity: 0.9 },
      { reportId: 'r4', similarity: 0.0 },
      { reportId: 'r5', similarity: 0.0 },
    ];
    const result = await computeAiScore('top-3 only');
    expect(result.aiScore).toBe(90);
    expect(result.aiConfidence).toBe('high');
  });
});
