import { afterAll, beforeAll, describe, expect, mock, test } from 'bun:test';
import { app } from '../src/index';

let mockDecoded: { uid: string; email: string | null; role?: string } | null = null;
let shouldThrow = false;

mock.module('firebase-admin/auth', () => ({
  getAuth: () => ({
    verifyIdToken: async () => {
      if (shouldThrow) throw new Error('mock: invalid token');
      if (!mockDecoded) throw new Error('mock: no decoded token configured');
      return mockDecoded;
    },
  }),
}));

mock.module('../src/core/firebase/admin', () => ({
  getFirebaseAdmin: () => ({}),
}));

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    report: {
      findMany: async () => [],
      findUnique: async () => null,
      count: async () => 0,
    },
  }),
}));

beforeAll(() => {
  mockDecoded = null;
  shouldThrow = false;
});

afterAll(() => {
  mockDecoded = null;
  shouldThrow = false;
});

function req(
  path: string,
  opts?: { method?: string; token?: string; body?: unknown },
) {
  const headers: Record<string, string> = { 'content-type': 'application/json' };
  if (opts?.token) headers['Authorization'] = `Bearer ${opts.token}`;
  return new Request(`http://localhost${path}`, {
    method: opts?.method ?? 'GET',
    headers,
    body: opts?.body ? JSON.stringify(opts.body) : undefined,
  });
}

const VALID_ID = '00000000-0000-0000-0000-000000000000';
const ADMIN = { uid: 'a1', email: 'a@example.com', role: 'admin' };
const USER = { uid: 'u1', email: 'u@example.com', role: 'user' };

// ---------------------------------------------------------------------------
describe('GET /admin/reports/queue', () => {
  test('401 unauthenticated', async () => {
    const res = await app.handle(req('/admin/reports/queue'));
    expect(res.status).toBe(401);
  });

  test('403 regular user', async () => {
    mockDecoded = USER;
    const res = await app.handle(req('/admin/reports/queue', { token: 'tok' }));
    expect(res.status).toBe(403);
    mockDecoded = null;
  });

  test('200 admin returns queue', async () => {
    mockDecoded = ADMIN;
    const res = await app.handle(req('/admin/reports/queue', { token: 'tok' }));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('items');
    expect(body).toHaveProperty('pendingCount');
    expect(body).toHaveProperty('flaggedCount');
    mockDecoded = null;
  });
});

// ---------------------------------------------------------------------------
describe('GET /admin/reports/:id', () => {
  test('401 unauthenticated', async () => {
    const res = await app.handle(req(`/admin/reports/${VALID_ID}`));
    expect(res.status).toBe(401);
  });

  test('403 regular user', async () => {
    mockDecoded = USER;
    const res = await app.handle(req(`/admin/reports/${VALID_ID}`, { token: 'tok' }));
    expect(res.status).toBe(403);
    mockDecoded = null;
  });

  test('422 non-UUID id', async () => {
    mockDecoded = ADMIN;
    const res = await app.handle(req('/admin/reports/not-a-uuid', { token: 'tok' }));
    expect(res.status).toBe(422);
    mockDecoded = null;
  });

  test('404 admin — report not found', async () => {
    mockDecoded = ADMIN;
    const res = await app.handle(req(`/admin/reports/${VALID_ID}`, { token: 'tok' }));
    expect(res.status).toBe(404);
    mockDecoded = null;
  });
});

// ---------------------------------------------------------------------------
describe('POST /admin/reports/:id/approve', () => {
  test('401 unauthenticated', async () => {
    const res = await app.handle(
      req(`/admin/reports/${VALID_ID}/approve`, { method: 'POST', body: { remark: 'ok' } }),
    );
    expect(res.status).toBe(401);
  });

  test('403 regular user', async () => {
    mockDecoded = USER;
    const res = await app.handle(
      req(`/admin/reports/${VALID_ID}/approve`, { method: 'POST', token: 'tok', body: { remark: 'ok' } }),
    );
    expect(res.status).toBe(403);
    mockDecoded = null;
  });

  test('422 empty remark', async () => {
    mockDecoded = ADMIN;
    const res = await app.handle(
      req(`/admin/reports/${VALID_ID}/approve`, { method: 'POST', token: 'tok', body: { remark: '' } }),
    );
    expect(res.status).toBe(422);
    mockDecoded = null;
  });

  test('422 missing remark', async () => {
    mockDecoded = ADMIN;
    const res = await app.handle(
      req(`/admin/reports/${VALID_ID}/approve`, { method: 'POST', token: 'tok', body: {} }),
    );
    expect(res.status).toBe(422);
    mockDecoded = null;
  });

  test('404 admin — report not found', async () => {
    mockDecoded = ADMIN;
    const res = await app.handle(
      req(`/admin/reports/${VALID_ID}/approve`, { method: 'POST', token: 'tok', body: { remark: 'verified' } }),
    );
    expect(res.status).toBe(404);
    mockDecoded = null;
  });
});

// ---------------------------------------------------------------------------
// Spot-check reject / flag / unflag — same auth + validation shape
(['reject', 'flag', 'unflag'] as const).forEach((action) => {
  describe(`POST /admin/reports/:id/${action}`, () => {
    test('401 unauthenticated', async () => {
      const res = await app.handle(
        req(`/admin/reports/${VALID_ID}/${action}`, { method: 'POST', body: { remark: 'reason' } }),
      );
      expect(res.status).toBe(401);
    });

    test('422 empty remark', async () => {
      mockDecoded = ADMIN;
      const res = await app.handle(
        req(`/admin/reports/${VALID_ID}/${action}`, { method: 'POST', token: 'tok', body: { remark: '' } }),
      );
      expect(res.status).toBe(422);
      mockDecoded = null;
    });

    test('422 non-UUID id', async () => {
      mockDecoded = ADMIN;
      const res = await app.handle(
        req(`/admin/reports/bad-id/${action}`, { method: 'POST', token: 'tok', body: { remark: 'reason' } }),
      );
      expect(res.status).toBe(422);
      mockDecoded = null;
    });
  });
});
