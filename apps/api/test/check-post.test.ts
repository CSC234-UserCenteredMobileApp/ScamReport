import { describe, expect, mock, test } from 'bun:test';
import { app } from '../src/index';

// Mock Firebase (required for authMiddleware derive, even though /check is public)
mock.module('firebase-admin/auth', () => ({
  getAuth: () => ({
    verifyIdToken: async () => { throw new Error('mock: no token'); },
  }),
}));

mock.module('../src/core/firebase/admin', () => ({
  getFirebaseAdmin: () => ({}),
}));

// Mock DB to return proper shapes for both findMany calls in runCheck.
// Also stubs checkLog.create so the log write doesn't throw in tests.
mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    report: {
      findMany: async ({ where }: { where?: Record<string, unknown> }) => {
        // Return a matching verified report when queried by a known identifier
        const knownId = '+66812345678';
        const normalized = where?.targetIdentifierNormalized as string | undefined;
        if (normalized === knownId) {
          return [
            {
              id: 'aaa00000-0000-0000-0000-000000000001',
              title: 'Test scam report',
              scamType: { code: 'phishing_sms' },
              verifiedAt: new Date('2026-04-01T00:00:00Z'),
            },
          ];
        }
        return [];
      },
    },
    checkLog: {
      create: async () => ({}),
    },
    $queryRaw: async () => [],
  }),
}));

// Also mock the Gemini embed so RAG doesn't fail with an unhandled error
mock.module('../src/core/gemini/client', () => ({
  embed: async () => [],
  generateText: async () => '',
}));

function post(path: string, body: unknown) {
  return app.handle(
    new Request(`http://localhost${path}`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(body),
    }),
  );
}

// ---------------------------------------------------------------------------
describe('POST /check — validation', () => {
  test('422 when body is missing type', async () => {
    const res = await post('/check', { payload: '+66812345678' });
    expect(res.status).toBe(422);
  });

  test('422 when type is invalid', async () => {
    const res = await post('/check', { type: 'email', payload: 'foo@bar.com' });
    expect(res.status).toBe(422);
  });

  test('422 when payload is empty string', async () => {
    const res = await post('/check', { type: 'phone', payload: '' });
    expect(res.status).toBe(422);
  });

  test('422 when payload is missing', async () => {
    const res = await post('/check', { type: 'url' });
    expect(res.status).toBe(422);
  });
});

// ---------------------------------------------------------------------------
describe('POST /check — verdict logic', () => {
  test('200 with scam verdict for known phone number', async () => {
    const res = await post('/check', { type: 'phone', payload: '+66812345678' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.verdict).toBe('scam');
    expect(body.matchedCount).toBe(1);
    expect(body.matches).toHaveLength(1);
    expect(body.matches[0]).toHaveProperty('id');
    expect(body.matches[0]).toHaveProperty('title');
    expect(body.matches[0]).toHaveProperty('scamType');
    expect(body.matches[0]).toHaveProperty('verifiedAt');
  });

  test('200 with safe verdict for unknown phone number', async () => {
    const res = await post('/check', { type: 'phone', payload: '+66999999999' });
    expect(res.status).toBe(200);
    const body = await res.json();
    // No identifier match + embed returns [] → safe
    expect(body.verdict).toBe('safe');
    expect(body.matchedCount).toBe(0);
    expect(body.matches).toHaveLength(0);
  });

  test('200 with safe/unknown verdict for text input (no embeddings in test env)', async () => {
    const res = await post('/check', {
      type: 'text',
      payload: 'parcel held SMS from Kerry Express',
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    // embed() returns [] → RAG returns [] → verdict is 'safe' or 'unknown'
    expect(['safe', 'unknown']).toContain(body.verdict);
  });

  test('200 with optional meta field', async () => {
    const res = await post('/check', {
      type: 'url',
      payload: 'http://bit.ly/example',
      meta: { source: 'clipboard', locale: 'th' },
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(['scam', 'suspicious', 'safe', 'unknown']).toContain(body.verdict);
  });

  test('GET /check/phones regression — still returns 200', async () => {
    // Sanity check that adding POST /check did not break the existing GET
    const res = await app.handle(new Request('http://localhost/check/phones'));
    expect(res.status).toBe(200);
  });
});
