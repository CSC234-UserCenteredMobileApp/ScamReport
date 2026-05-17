// Tests for GET /admin/ai-eval/{latest,history}. File-backed endpoints —
// we mock the `node:fs` reads (existsSync + readFileSync) plus Firebase auth
// and the Prisma role lookup so the suite runs without a database.

import { afterEach, beforeEach, describe, expect, mock, test } from 'bun:test';

let mockDecoded: { uid: string; email: string; role: 'user' | 'admin' } | null = null;

mock.module('firebase-admin/auth', () => ({
  getAuth: () => ({
    verifyIdToken: async () => {
      if (!mockDecoded) throw new Error('no token');
      const { role: _role, ...rest } = mockDecoded;
      return rest;
    },
  }),
}));
mock.module('../src/core/firebase/admin', () => ({
  getFirebaseAdmin: () => ({}),
}));
mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    user: {
      findUnique: async () =>
        mockDecoded?.role ? { role: mockDecoded.role } : null,
      upsert: async () => ({ id: 'u1' }),
    },
  }),
}));

// Filesystem-backed service mock — overrideable per test. We mock the
// service module directly instead of `node:fs` to avoid clobbering the
// dozens of other fs exports the rest of the app depends on.
const mockState = {
  latest: null as unknown,
  history: [] as unknown[],
};
const serviceFactory = () => ({
  getLatestSummary: () => ({ summary: mockState.latest }),
  getHistory: (limit?: number) => {
    const n = Math.min(Math.max(1, limit ?? 30), 365);
    return { entries: mockState.history.slice(-n) };
  },
});
mock.module('../src/features/admin-ai-eval/admin-ai-eval.service', serviceFactory);
mock.module('./admin-ai-eval.service', serviceFactory);

const { app } = await import('../src/index');

function adminToken() {
  mockDecoded = { uid: 'u1', email: 'a@example.com', role: 'admin' };
  return 'Bearer admin-token';
}

function userToken() {
  mockDecoded = { uid: 'u1', email: 'u@example.com', role: 'user' };
  return 'Bearer user-token';
}

beforeEach(() => {
  mockState.latest = null;
  mockState.history = [];
});
afterEach(() => {
  mockDecoded = null;
});

describe('GET /admin/ai-eval/latest', () => {
  test('401 without bearer', async () => {
    const res = await app.handle(new Request('http://localhost/admin/ai-eval/latest'));
    expect([401, 403]).toContain(res.status);
  });

  test('403 for non-admin', async () => {
    const auth = userToken();
    const res = await app.handle(
      new Request('http://localhost/admin/ai-eval/latest', {
        headers: { Authorization: auth },
      }),
    );
    expect(res.status).toBe(403);
  });

  test('returns null when latest.json missing', async () => {
    const auth = adminToken();
    const res = await app.handle(
      new Request('http://localhost/admin/ai-eval/latest', {
        headers: { Authorization: auth },
      }),
    );
    expect(res.status).toBe(200);
    const body = (await res.json()) as { summary: unknown };
    expect(body.summary).toBeNull();
  });

  test('returns parsed summary when latest.json exists', async () => {
    const auth = adminToken();
    mockState.latest = {
      runAt: '2026-05-17T02:00:00.000Z',
      gitSha: 'a'.repeat(40),
      totalCases: 50,
      verdictAccuracy: 0.88,
      scammerRecallAt1: 0.7,
      mrr: 0.75,
      p95LatencyMs: 1200,
      byType: {
        phone: { n: 15, verdictAccuracy: 0.93, scammerRecallAt1: 0.8, mrr: 0.82, p95LatencyMs: 200 },
        url: { n: 15, verdictAccuracy: 0.86, scammerRecallAt1: 0.7, mrr: 0.74, p95LatencyMs: 250 },
        text: { n: 20, verdictAccuracy: 0.85, scammerRecallAt1: 0.6, mrr: 0.7, p95LatencyMs: 1800 },
      },
      confusionMatrix: {
        scam: { scam: 28, suspicious: 1, safe: 1, unknown: 0 },
        suspicious: { scam: 0, suspicious: 0, safe: 0, unknown: 0 },
        safe: { scam: 2, suspicious: 0, safe: 18, unknown: 0 },
        unknown: { scam: 0, suspicious: 0, safe: 0, unknown: 0 },
      },
      threshold: 0.7,
      passed: true,
      results: [],
    };

    const res = await app.handle(
      new Request('http://localhost/admin/ai-eval/latest', {
        headers: { Authorization: auth },
      }),
    );
    expect(res.status).toBe(200);
    const body = (await res.json()) as { summary: { totalCases: number } | null };
    expect(body.summary?.totalCases).toBe(50);
  });
});

describe('GET /admin/ai-eval/history', () => {
  test('403 for non-admin', async () => {
    const auth = userToken();
    const res = await app.handle(
      new Request('http://localhost/admin/ai-eval/history', {
        headers: { Authorization: auth },
      }),
    );
    expect(res.status).toBe(403);
  });

  test('returns empty array when history file missing', async () => {
    const auth = adminToken();
    const res = await app.handle(
      new Request('http://localhost/admin/ai-eval/history', {
        headers: { Authorization: auth },
      }),
    );
    expect(res.status).toBe(200);
    const body = (await res.json()) as { entries: unknown[] };
    expect(body.entries).toEqual([]);
  });

  test('returns entries, newest-bounded by limit', async () => {
    const auth = adminToken();
    mockState.history = Array.from({ length: 5 }, (_, i) => ({
      runAt: `2026-05-${String(i + 10).padStart(2, '0')}T02:00:00.000Z`,
      gitSha: null,
      totalCases: 50,
      verdictAccuracy: 0.8 + i * 0.01,
      byType: { phone: 0.9, url: 0.8, text: 0.75 },
      threshold: 0.7,
      passed: true,
    }));

    const res = await app.handle(
      new Request('http://localhost/admin/ai-eval/history?limit=3', {
        headers: { Authorization: auth },
      }),
    );
    expect(res.status).toBe(200);
    const body = (await res.json()) as { entries: { verdictAccuracy: number }[] };
    expect(body.entries).toHaveLength(3);
    expect(body.entries[0]!.verdictAccuracy).toBeCloseTo(0.82);
    expect(body.entries[2]!.verdictAccuracy).toBeCloseTo(0.84);
  });
});
