// Tests for GET /admin/reports/platform-summary.

import { beforeEach, describe, expect, mock, test } from 'bun:test';

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
      findUnique: async () => (mockDecoded?.role ? { role: mockDecoded.role } : null),
      upsert: async () => ({ id: '11111111-1111-1111-1111-111111111111' }),
    },
    report: {
      count: async ({ where }: { where?: Record<string, unknown> }) => {
        // Distinguish counts by the status filter — keeps the test cheap.
        const status = (where?.status as string | undefined) ?? null;
        if (status === 'verified') return 5;
        if (status === 'pending') return 2;
        if (status === 'flagged') return 1;
        if (status === 'rejected') return 0;
        const ai = (where?.aiConfidence as string | undefined) ?? null;
        if (ai === 'high') return 3;
        if (ai === 'medium') return 2;
        if (ai === 'low') return 1;
        return 8;
      },
      groupBy: async () => [],
    },
    scammer: {
      findMany: async () => [
        {
          id: '22222222-2222-2222-2222-222222222222',
          displayName: 'Revenue Dept Impersonator',
          reportCountCache: 3,
          riskLevel: 'high',
        },
      ],
    },
    scamType: {
      findMany: async () => [],
    },
    checkLog: {
      count: async () => 99,
      groupBy: async () => [
        { verdict: 'scam', _count: { verdict: 50 } },
        { verdict: 'safe', _count: { verdict: 40 } },
        { verdict: 'unknown', _count: { verdict: 9 } },
      ],
    },
    aiEvalRun: {
      findFirst: async () => ({
        id: '33333333-3333-3333-3333-333333333333',
        runAt: new Date('2026-05-10T00:00:00Z'),
        verdictAccuracy: 0.8,
        scammerRecallAt1: 0.7,
        scammerMrr: 0.75,
        missingFactsF1: 0.6,
        p95LatencyMs: 250,
      }),
    },
    $queryRaw: async () => [],
  }),
}));

import { app } from '../src/index';

beforeEach(() => {
  mockDecoded = { uid: 'firebase-admin', email: 'admin@example.com', role: 'admin' };
});

describe('GET /admin/reports/platform-summary', () => {
  test('admin → returns aggregates + latestEval', async () => {
    const res = await app.handle(
      new Request('http://localhost/admin/reports/platform-summary', {
        method: 'GET',
        headers: { authorization: 'Bearer test-token' },
      }),
    );
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.reports.verified).toBe(5);
    expect(body.reports.rejected).toBe(0);
    expect(body.topScammers).toHaveLength(1);
    expect(body.topScammers[0].displayName).toBe('Revenue Dept Impersonator');
    expect(body.checkLogs.total).toBe(99);
    expect(body.checkLogs.verdictMix.scam).toBe(50);
    expect(body.latestEval).not.toBeNull();
    expect(body.latestEval.verdictAccuracy).toBe(0.8);
  });

  test('non-admin → 403', async () => {
    mockDecoded = { uid: 'firebase-user', email: 'u@example.com', role: 'user' };
    const res = await app.handle(
      new Request('http://localhost/admin/reports/platform-summary', {
        method: 'GET',
        headers: { authorization: 'Bearer test-token' },
      }),
    );
    expect(res.status).toBe(403);
  });
});
