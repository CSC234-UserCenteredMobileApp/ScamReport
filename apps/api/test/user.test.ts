import { afterEach, beforeEach, describe, expect, mock, test } from 'bun:test';
import { app } from '../src/index';

// ---------------------------------------------------------------------------
// Firebase mocks
// ---------------------------------------------------------------------------
let mockDecoded: { uid: string; email: string | null; role?: string } | null = null;

mock.module('firebase-admin/auth', () => ({
  getAuth: () => ({
    verifyIdToken: async () => {
      if (!mockDecoded) throw new Error('mock: no decoded token configured');
      return mockDecoded;
    },
  }),
}));

mock.module('../src/core/firebase/admin', () => ({
  getFirebaseAdmin: () => ({}),
}));

mock.module('../src/core/firebase/messaging', () => ({
  sendFcmToUser: async () => {},
}));

mock.module('../src/core/gemini/client', () => ({
  embed: async () => Array(768).fill(0.01),
  generateText: async () => '',
}));

// ---------------------------------------------------------------------------
// Prisma mock
// ---------------------------------------------------------------------------
const INTERNAL_USER_ID = 'aaaaaaaa-0000-0000-0000-000000000001';

// Stable timestamps so idempotency test can assert same values
const FIXED_REQUESTED_AT = new Date('2026-01-01T00:00:00.000Z');
const FIXED_PURGE_DUE_AT = new Date('2026-01-08T00:00:00.000Z');

let mockDeletionRow: { requestedAt: Date; purgeDueAt: Date } = {
  requestedAt: FIXED_REQUESTED_AT,
  purgeDueAt: FIXED_PURGE_DUE_AT,
};
let mockDeleteManyCount = 1;

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    user: {
      upsert: async () => ({ id: INTERNAL_USER_ID }),
    },
    accountDeletionRequest: {
      upsert: async () => mockDeletionRow,
      deleteMany: async () => ({ count: mockDeleteManyCount }),
    },
    report: {
      findMany: async () => [],
      findUnique: async () => null,
      count: async () => 0,
      update: async () => ({}),
    },
    moderationAction: {
      create: async () => ({}),
    },
    $transaction: async (ops: Promise<unknown>[]) => Promise.all(ops),
    $queryRaw: async () => [],
  }),
}));

// ---------------------------------------------------------------------------
// Constants / helpers
// ---------------------------------------------------------------------------
const USER = { uid: 'u1', email: 'u@example.com', role: 'user' };

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

beforeEach(() => {
  mockDecoded = null;
  mockDeletionRow = { requestedAt: FIXED_REQUESTED_AT, purgeDueAt: FIXED_PURGE_DUE_AT };
  mockDeleteManyCount = 1;
});

afterEach(() => {
  mockDecoded = null;
});

// ---------------------------------------------------------------------------
describe('POST /user/delete-account', () => {
  test('401 without token', async () => {
    const res = await app.handle(req('/user/delete-account', { method: 'POST' }));
    expect(res.status).toBe(401);
  });

  test('200 with valid token — returns requestedAt and purgeDueAt', async () => {
    mockDecoded = USER;
    const res = await app.handle(req('/user/delete-account', { method: 'POST', token: 'tok' }));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('requestedAt');
    expect(body).toHaveProperty('purgeDueAt');
    expect(body.requestedAt).toBe(FIXED_REQUESTED_AT.toISOString());
    expect(body.purgeDueAt).toBe(FIXED_PURGE_DUE_AT.toISOString());
  });

  test('200 idempotent — second call returns same timestamps', async () => {
    mockDecoded = USER;

    const res1 = await app.handle(req('/user/delete-account', { method: 'POST', token: 'tok' }));
    expect(res1.status).toBe(200);
    const body1 = await res1.json();

    // Second call — mock returns same stable row (upsert no-op)
    const res2 = await app.handle(req('/user/delete-account', { method: 'POST', token: 'tok' }));
    expect(res2.status).toBe(200);
    const body2 = await res2.json();

    expect(body1.requestedAt).toBe(body2.requestedAt);
    expect(body1.purgeDueAt).toBe(body2.purgeDueAt);
  });
});

// ---------------------------------------------------------------------------
describe('DELETE /user/delete-account', () => {
  test('401 without token', async () => {
    const res = await app.handle(req('/user/delete-account', { method: 'DELETE' }));
    expect(res.status).toBe(401);
  });

  test('200 with pending request — cancels deletion', async () => {
    mockDecoded = USER;
    mockDeleteManyCount = 1;
    const res = await app.handle(req('/user/delete-account', { method: 'DELETE', token: 'tok' }));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('message');
    expect(body.message).toBe('Account deletion request cancelled.');
  });

  test('404 with no pending request', async () => {
    mockDecoded = USER;
    mockDeleteManyCount = 0;
    const res = await app.handle(req('/user/delete-account', { method: 'DELETE', token: 'tok' }));
    expect(res.status).toBe(404);
    const body = await res.json();
    expect(body).toHaveProperty('error');
  });
});
