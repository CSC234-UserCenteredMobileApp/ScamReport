// Tests for the scammer-aware /check pipeline. Phase 1a (scammer identifier
// lookup) should return matchedScammer + populate matches[] from the
// scammer's recent verified cases.

import { describe, expect, mock, test } from 'bun:test';

mock.module('firebase-admin/auth', () => ({
  getAuth: () => ({
    verifyIdToken: async () => { throw new Error('mock: no token'); },
  }),
}));
mock.module('../src/core/firebase/admin', () => ({
  getFirebaseAdmin: () => ({}),
}));

// Gemini is best-effort in Phase 3; return safe so it doesn't override the
// Phase 1a scam verdict.
mock.module('../src/core/gemini/client', () => ({
  embed: async () => [],
  generateText: async () => '{"verdict":"safe","reason":"normal"}',
}));

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    scammerIdentifier: {
      findUnique: async ({ where }: { where: { kind_valueNormalized: { kind: string; valueNormalized: string } } }) => {
        if (
          where.kind_valueNormalized.kind === 'phone' &&
          where.kind_valueNormalized.valueNormalized === '+6629991234'
        ) {
          return { scammerId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' };
        }
        return null;
      },
    },
    scammer: {
      findUnique: async ({ where }: { where: { id: string } }) => {
        if (where.id === 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') {
          return {
            id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
            displayName: 'Revenue Dept Impersonator',
            suspectedName: 'Khun Somchai Wongchai',
            aliases: ['Khun Anan'],
            riskLevel: 'high',
            reportCountCache: 3,
            reports: [
              {
                id: '11111111-1111-1111-1111-111111111111',
                title: 'Fake tax demand call',
                verifiedAt: new Date('2026-04-01T00:00:00Z'),
                scamType: { code: 'phone_impersonation' },
              },
            ],
          };
        }
        return null;
      },
    },
    report: {
      findMany: async () => [],
    },
    checkLog: {
      create: async () => ({}),
    },
    $queryRaw: async () => [],
  }),
}));

import { app } from '../src/index';

function post(path: string, body: unknown) {
  return app.handle(
    new Request(`http://localhost${path}`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(body),
    }),
  );
}

describe('POST /check — scammer identifier match', () => {
  test('hits scammer profile → verdict scam + matchedScammer payload', async () => {
    const res = await post('/check', { type: 'phone', payload: '+66 2 999 1234' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.verdict).toBe('scam');
    expect(body.matchedCount).toBe(1);
    expect(body.matchedScammer).toBeDefined();
    expect(body.matchedScammer.summary.displayName).toBe('Revenue Dept Impersonator');
    expect(body.matchedScammer.summary.riskLevel).toBe('high');
    expect(body.matchedScammer.summary.reportCount).toBe(3);
    expect(body.matchedScammer.recentCases).toHaveLength(1);
    expect(body.matchedScammer.recentCases[0].title).toBe('Fake tax demand call');
  });

  test('no scammer hit → matchedScammer is null/absent', async () => {
    const res = await post('/check', { type: 'phone', payload: '+66 81 234 5678' });
    expect(res.status).toBe(200);
    const body = await res.json();
    // Phase 1b legacy lookup runs; report.findMany returns empty → no matches.
    expect(body.matchedCount).toBe(0);
    expect(body.matchedScammer ?? null).toBeNull();
  });
});
