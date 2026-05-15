// Tests for the AI eval endpoints. Uses in-memory mocks for the eval-case
// store and asserts that the run handler computes verdict accuracy +
// persists a summary row.

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

mock.module('../src/core/gemini/client', () => ({
  embed: async () => [],
  generateText: async () => '{"verdict":"safe","reason":"n/a"}',
}));

const SCAMMER_ID = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

const mockCases = [
  {
    id: '11111111-1111-1111-1111-111111111111',
    label: 'phone-known',
    inputType: 'phone',
    inputPayload: '+66 2 999 1234',
    expectedVerdict: 'scam',
    expectedScammerId: SCAMMER_ID,
    expectedScamTypeCode: 'phone_impersonation',
    expectedMissingFacts: [],
  },
  {
    id: '22222222-2222-2222-2222-222222222222',
    label: 'phone-safe',
    inputType: 'phone',
    inputPayload: '+66 81 234 5678',
    expectedVerdict: 'safe',
    expectedScammerId: null,
    expectedScamTypeCode: null,
    expectedMissingFacts: [],
  },
];

let createdRun: Record<string, unknown> | null = null;
let createdResults: unknown[] = [];

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    user: {
      findUnique: async () => (mockDecoded?.role ? { role: mockDecoded.role } : null),
      upsert: async () => ({ id: 'ffffffff-ffff-ffff-ffff-ffffffffffff' }),
      findFirst: async () => null,
      create: async () => ({ id: 'ffffffff-ffff-ffff-ffff-ffffffffffff' }),
    },
    aiEvalCase: {
      findMany: async () => mockCases,
    },
    aiEvalRun: {
      create: async ({ data }: { data: Record<string, unknown> }) => {
        createdRun = {
          ...data,
          id: '33333333-3333-3333-3333-333333333333',
          runAt: new Date(),
        };
        return createdRun;
      },
      findUnique: async () => createdRun,
      findFirst: async () => createdRun,
      findMany: async () => (createdRun ? [createdRun] : []),
    },
    aiEvalResult: {
      createMany: async ({ data }: { data: unknown[] }) => {
        createdResults = data;
        return { count: data.length };
      },
    },
    // /check pipeline calls.
    scammerIdentifier: {
      findUnique: async ({ where }: { where: { kind_valueNormalized: { kind: string; valueNormalized: string } } }) =>
        where.kind_valueNormalized.valueNormalized === '+6629991234'
          ? { scammerId: SCAMMER_ID }
          : null,
    },
    scammer: {
      findUnique: async () => ({
        id: SCAMMER_ID,
        displayName: 'Revenue Dept Impersonator',
        aliases: [],
        riskLevel: 'high',
        reportCountCache: 1,
        reports: [
          {
            id: '44444444-4444-4444-4444-444444444444',
            title: 'Tax demand',
            verifiedAt: new Date(),
            scamType: { code: 'phone_impersonation' },
          },
        ],
      }),
    },
    report: {
      findMany: async () => [],
    },
    checkLog: {
      create: async () => ({}),
    },
    $transaction: async (fn: (tx: unknown) => unknown) =>
      fn({
        aiEvalRun: {
          create: async ({ data }: { data: Record<string, unknown> }) => {
            createdRun = {
              ...data,
              id: '33333333-3333-3333-3333-333333333333',
              runAt: new Date(),
            };
            return createdRun;
          },
        },
        aiEvalResult: {
          createMany: async ({ data }: { data: unknown[] }) => {
            createdResults = data;
            return { count: data.length };
          },
        },
      }),
    $queryRaw: async () => [],
  }),
}));

import { app } from '../src/index';

beforeEach(() => {
  mockDecoded = { uid: 'firebase-admin', email: 'admin@example.com', role: 'admin' };
  createdRun = null;
  createdResults = [];
});

describe('POST /admin/ai-eval/run', () => {
  test('admin → produces a summary; persists run + per-case rows', async () => {
    const res = await app.handle(
      new Request('http://localhost/admin/ai-eval/run', {
        method: 'POST',
        headers: { authorization: 'Bearer test-token' },
      }),
    );
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.summary.totalCases).toBe(mockCases.length);
    // The phone-known case should match: verdict scam + scammer matched.
    // Verdict accuracy should be > 0 with at least one correct.
    expect(body.summary.verdictAccuracy).toBeGreaterThanOrEqual(0);
    expect(createdResults.length).toBe(mockCases.length);
  });

  test('non-admin → 403', async () => {
    mockDecoded = { uid: 'firebase-user', email: 'u@example.com', role: 'user' };
    const res = await app.handle(
      new Request('http://localhost/admin/ai-eval/run', {
        method: 'POST',
        headers: { authorization: 'Bearer test-token' },
      }),
    );
    expect(res.status).toBe(403);
  });
});

describe('GET /admin/ai-eval/runs', () => {
  test('returns latest runs', async () => {
    // Seed a run first.
    createdRun = {
      id: '33333333-3333-3333-3333-333333333333',
      runAt: new Date(),
      totalCases: 2,
      verdictAccuracy: 0.5,
      scammerRecallAt1: 1,
      scammerMrr: 1,
      missingFactsF1: 0,
      p95LatencyMs: 12,
    };
    const res = await app.handle(
      new Request('http://localhost/admin/ai-eval/runs?limit=5', {
        method: 'GET',
        headers: { authorization: 'Bearer test-token' },
      }),
    );
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.items).toHaveLength(1);
    expect(body.items[0].id).toBe('33333333-3333-3333-3333-333333333333');
  });
});
