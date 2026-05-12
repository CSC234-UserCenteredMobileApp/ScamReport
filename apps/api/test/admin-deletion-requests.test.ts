import { afterEach, beforeEach, describe, expect, mock, test } from 'bun:test';
import { app } from '../src/index';

// ---------------------------------------------------------------------------
// Firebase mocks
// ---------------------------------------------------------------------------
let mockDecoded: { uid: string; email: string | null; role?: 'user' | 'admin' } | null = null;
let mockFirebaseDeleteUser: (() => Promise<void>) = async () => {};

mock.module('firebase-admin/auth', () => ({
  getAuth: () => ({
    verifyIdToken: async () => {
      if (!mockDecoded) throw new Error('mock: no decoded token configured');
      const { role: _role, ...decoded } = mockDecoded!;
      return decoded;
    },
    deleteUser: async (uid: string) => mockFirebaseDeleteUser(),
  }),
}));

mock.module('../src/core/firebase/admin', () => ({
  getFirebaseAdmin: () => ({}),
}));

mock.module('../src/core/firebase/messaging', () => ({
  sendFcmToUser: async () => {},
  sendFcmBroadcast: async () => {},
}));

mock.module('../src/core/gemini/client', () => ({
  embed: async () => Array(768).fill(0.01),
  generateText: async () => '',
}));

// ---------------------------------------------------------------------------
// Prisma mock
// ---------------------------------------------------------------------------
const VALID_ID = '00000000-0000-0000-0000-000000000001';
const USER_ID   = '00000000-0000-0000-0000-000000000002';
const NOW = new Date('2026-01-01T00:00:00Z');
const PURGE_DUE = new Date('2026-01-08T00:00:00Z');

let mockFindUniqueDeletionReq: Record<string, unknown> | null = null;
let mockFindManyDeletionReqs: unknown[] = [];
let mockCountPending = 0;

const MOCK_PENDING_REQ = {
  id: VALID_ID,
  userId: USER_ID,
  requestedAt: NOW,
  purgeDueAt: PURGE_DUE,
  purgedAt: null,
  status: 'pending',
  reviewedAt: null,
  reviewedByAdminId: null,
  rejectionReason: null,
  user: { id: USER_ID, email: 'user@example.com', firebaseUid: 'firebase-uid-abc' },
};

const MOCK_APPROVED_REQ = {
  ...MOCK_PENDING_REQ,
  status: 'approved',
  reviewedAt: NOW,
  reviewedByAdminId: 'admin-uid',
};

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    accountDeletionRequest: {
      findMany: async () => mockFindManyDeletionReqs,
      findUnique: async () => mockFindUniqueDeletionReq,
      count: async () => mockCountPending,
      update: async () => mockFindUniqueDeletionReq ?? MOCK_PENDING_REQ,
    },
    user: {
      findUnique: async () =>
        mockDecoded?.role ? { role: mockDecoded.role } : null,
      upsert: async () => ({ id: USER_ID }),
      delete: async () => ({}),
    },
    fcmDevice: {
      findMany: async () => [],
    },
    report: {
      findMany: async () => [],
      findUnique: async () => null,
      count: async () => 0,
      update: async () => ({}),
    },
    moderationAction: { create: async () => ({}) },
    $transaction: async (ops: Promise<unknown>[]) => Promise.all(ops),
    $queryRaw: async () => [],
  }),
}));

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
const ADMIN = { uid: 'admin-uid', email: 'admin@example.com', role: 'admin' as const };
const USER  = { uid: 'user-uid',  email: 'user@example.com',  role: 'user'  as const };

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
  mockFindUniqueDeletionReq = null;
  mockFindManyDeletionReqs = [];
  mockCountPending = 0;
  mockFirebaseDeleteUser = async () => {};
});

afterEach(() => {
  mockDecoded = null;
});

// ---------------------------------------------------------------------------
describe('GET /admin/deletion-requests — auth gating', () => {
  test('401 without token', async () => {
    const res = await app.handle(req('/admin/deletion-requests'));
    expect(res.status).toBe(401);
  });

  test('403 with user token', async () => {
    mockDecoded = USER;
    const res = await app.handle(req('/admin/deletion-requests', { token: 'tok' }));
    expect(res.status).toBe(403);
  });

  test('200 admin — returns empty list + pendingCount', async () => {
    mockDecoded = ADMIN;
    mockFindManyDeletionReqs = [];
    mockCountPending = 0;
    const res = await app.handle(req('/admin/deletion-requests', { token: 'tok' }));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('items');
    expect(body).toHaveProperty('pendingCount', 0);
    expect(Array.isArray(body.items)).toBe(true);
  });
});

// ---------------------------------------------------------------------------
describe('POST /admin/deletion-requests/:id/approve', () => {
  test('404 for non-existent id', async () => {
    mockDecoded = ADMIN;
    mockFindUniqueDeletionReq = null;
    const res = await app.handle(
      req(`/admin/deletion-requests/${VALID_ID}/approve`, { method: 'POST', token: 'tok' }),
    );
    expect(res.status).toBe(404);
  });

  test('409 if already approved', async () => {
    mockDecoded = ADMIN;
    mockFindUniqueDeletionReq = MOCK_APPROVED_REQ;
    const res = await app.handle(
      req(`/admin/deletion-requests/${VALID_ID}/approve`, { method: 'POST', token: 'tok' }),
    );
    expect(res.status).toBe(409);
  });

  test('200 approve pending request — returns status=approved', async () => {
    mockDecoded = ADMIN;
    mockFindUniqueDeletionReq = MOCK_PENDING_REQ;
    const res = await app.handle(
      req(`/admin/deletion-requests/${VALID_ID}/approve`, { method: 'POST', token: 'tok' }),
    );
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('id', VALID_ID);
    expect(body).toHaveProperty('status', 'approved');
    expect(body).toHaveProperty('reviewedAt');
  });
});

// ---------------------------------------------------------------------------
describe('POST /admin/deletion-requests/:id/reject', () => {
  test('404 for non-existent id', async () => {
    mockDecoded = ADMIN;
    mockFindUniqueDeletionReq = null;
    const res = await app.handle(
      req(`/admin/deletion-requests/${VALID_ID}/reject`, {
        method: 'POST', token: 'tok',
        body: { reason: 'No valid reason provided' },
      }),
    );
    expect(res.status).toBe(404);
  });

  test('409 if already rejected', async () => {
    mockDecoded = ADMIN;
    mockFindUniqueDeletionReq = { ...MOCK_PENDING_REQ, status: 'rejected' };
    const res = await app.handle(
      req(`/admin/deletion-requests/${VALID_ID}/reject`, {
        method: 'POST', token: 'tok',
        body: { reason: 'Too late' },
      }),
    );
    expect(res.status).toBe(409);
  });

  test('200 reject pending request — returns status=rejected', async () => {
    mockDecoded = ADMIN;
    mockFindUniqueDeletionReq = MOCK_PENDING_REQ;
    const res = await app.handle(
      req(`/admin/deletion-requests/${VALID_ID}/reject`, {
        method: 'POST', token: 'tok',
        body: { reason: 'Account flagged for review' },
      }),
    );
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('id', VALID_ID);
    expect(body).toHaveProperty('status', 'rejected');
    expect(body).toHaveProperty('reviewedAt');
  });
});
