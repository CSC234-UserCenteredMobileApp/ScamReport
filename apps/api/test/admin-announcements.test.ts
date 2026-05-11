import { afterEach, beforeEach, describe, expect, mock, test } from 'bun:test';
import { app } from '../src/index';

// ---------------------------------------------------------------------------
// Firebase mocks
// ---------------------------------------------------------------------------
// `role` here is the role we want `requireRole` to resolve for this caller.
// It's no longer carried on the Firebase token (real tokens don't have a
// `role` claim — see `core/middleware/require_role.ts`); the prisma mock
// below reads from it to fake the `users.role` Postgres lookup.
let mockDecoded: { uid: string; email: string | null; role?: 'user' | 'admin' } | null = null;

mock.module('firebase-admin/auth', () => ({
  getAuth: () => ({
    verifyIdToken: async () => {
      if (!mockDecoded) throw new Error('mock: no decoded token configured');
      // Real tokens have no `role` claim; strip it before returning so the
      // middleware can't accidentally start trusting it again.
      const { role: _role, ...decoded } = mockDecoded;
      return decoded;
    },
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
// Prisma mock — dynamic per test via module-level variables
// ---------------------------------------------------------------------------
let mockFindUniqueAnnouncement: Record<string, unknown> | null = null;
let mockUpdateAnnouncement: Record<string, unknown> | null = null;
let mockFindManyAnnouncements: unknown[] = [];

const VALID_ID = '00000000-0000-0000-0000-000000000001';
const AUTHOR_ID = '00000000-0000-0000-0000-000000000002';

const NOW = new Date('2026-01-01T00:00:00Z');

const MOCK_DRAFT_ROW = {
  id: VALID_ID,
  slug: 'test-announcement-abc123',
  title: 'Test Announcement',
  body: 'This is the body of the announcement.',
  category: 'fraud_alert',
  status: 'draft',
  createdAt: NOW,
  updatedAt: NOW,
  publishedAt: null,
  pushedToFcmAt: null,
  authorId: AUTHOR_ID,
};

const MOCK_PUBLISHED_ROW = {
  ...MOCK_DRAFT_ROW,
  status: 'published',
  publishedAt: NOW,
};

const MOCK_UNPUBLISHED_ROW = {
  ...MOCK_DRAFT_ROW,
  status: 'unpublished',
};

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    announcement: {
      findMany: async () => mockFindManyAnnouncements,
      findUnique: async () => mockFindUniqueAnnouncement,
      create: async () => MOCK_DRAFT_ROW,
      update: async () => {
        // Return explicit update result if set, otherwise fall back to findUnique state
        return mockUpdateAnnouncement ?? mockFindUniqueAnnouncement ?? MOCK_DRAFT_ROW;
      },
      delete: async () => ({}),
    },
    // resolveInternalUserId calls user.upsert to get internal userId from firebaseUid;
    // requireRole calls user.findUnique to resolve the canonical role from Postgres.
    user: {
      findUnique: async () =>
        mockDecoded?.role ? { role: mockDecoded.role } : null,
      upsert: async () => ({ id: AUTHOR_ID }),
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
const ADMIN = { uid: 'a1', email: 'a@example.com', role: 'admin' as const };
const USER = { uid: 'u1', email: 'u@example.com', role: 'user' as const };

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
  mockFindUniqueAnnouncement = null;
  mockUpdateAnnouncement = null;
  mockFindManyAnnouncements = [];
});

afterEach(() => {
  mockDecoded = null;
  mockFindUniqueAnnouncement = null;
  mockUpdateAnnouncement = null;
  mockFindManyAnnouncements = [];
});

// ---------------------------------------------------------------------------
describe('GET /admin/announcements — auth gating', () => {
  test('401 without token', async () => {
    const res = await app.handle(req('/admin/announcements/'));
    expect(res.status).toBe(401);
  });

  test('403 with user-role token', async () => {
    mockDecoded = USER;
    const res = await app.handle(req('/admin/announcements/', { token: 'tok' }));
    expect(res.status).toBe(403);
  });

  test('200 with admin token — returns empty list', async () => {
    mockDecoded = ADMIN;
    const res = await app.handle(req('/admin/announcements/', { token: 'tok' }));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('items');
    expect(Array.isArray(body.items)).toBe(true);
    expect(body.items).toHaveLength(0);
  });
});

// ---------------------------------------------------------------------------
describe('POST /admin/announcements — create', () => {
  test('200 admin — creates draft with expected fields', async () => {
    mockDecoded = ADMIN;
    const res = await app.handle(
      req('/admin/announcements/', {
        method: 'POST',
        token: 'tok',
        body: { title: 'Test Announcement', body: 'This is the body of the announcement.', category: 'fraud_alert' },
      }),
    );
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('item');
    expect(body.item).toHaveProperty('id', VALID_ID);
    expect(body.item).toHaveProperty('status', 'draft');
    expect(body.item).toHaveProperty('title', 'Test Announcement');
    expect(body.item).toHaveProperty('slug');
    expect(body.item).toHaveProperty('createdAt');
    expect(body.item).toHaveProperty('updatedAt');
    expect(body.item.publishedAt).toBeNull();
  });
});

// ---------------------------------------------------------------------------
describe('GET /admin/announcements/:id — detail', () => {
  test('200 admin — returns announcement detail', async () => {
    mockDecoded = ADMIN;
    mockFindUniqueAnnouncement = MOCK_DRAFT_ROW;
    const res = await app.handle(req(`/admin/announcements/${VALID_ID}`, { token: 'tok' }));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('item');
    expect(body.item).toHaveProperty('id', VALID_ID);
    expect(body.item).toHaveProperty('status', 'draft');
  });

  test('404 admin — announcement not found', async () => {
    mockDecoded = ADMIN;
    mockFindUniqueAnnouncement = null;
    const res = await app.handle(req(`/admin/announcements/${VALID_ID}`, { token: 'tok' }));
    expect(res.status).toBe(404);
  });
});

// ---------------------------------------------------------------------------
describe('PUT /admin/announcements/:id — update', () => {
  test('200 admin — updates draft announcement', async () => {
    mockDecoded = ADMIN;
    mockFindUniqueAnnouncement = MOCK_DRAFT_ROW;
    const res = await app.handle(
      req(`/admin/announcements/${VALID_ID}`, {
        method: 'PUT',
        token: 'tok',
        body: { title: 'Updated Title' },
      }),
    );
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('item');
  });

  test('409 admin — cannot edit published announcement', async () => {
    mockDecoded = ADMIN;
    mockFindUniqueAnnouncement = MOCK_PUBLISHED_ROW;
    const res = await app.handle(
      req(`/admin/announcements/${VALID_ID}`, {
        method: 'PUT',
        token: 'tok',
        body: { title: 'Should fail' },
      }),
    );
    expect(res.status).toBe(409);
  });
});

// ---------------------------------------------------------------------------
describe('POST /admin/announcements/:id/publish — publish', () => {
  test('200 admin — publishes announcement', async () => {
    mockDecoded = ADMIN;
    // publishAnnouncement calls update directly (no findUnique); mock the update result
    mockUpdateAnnouncement = MOCK_PUBLISHED_ROW;
    const res = await app.handle(
      req(`/admin/announcements/${VALID_ID}/publish`, {
        method: 'POST',
        token: 'tok',
        body: { pushToFcm: false },
      }),
    );
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('item');
    expect(body.item).toHaveProperty('status', 'published');
  });
});

// ---------------------------------------------------------------------------
describe('POST /admin/announcements/:id/unpublish — unpublish', () => {
  test('200 admin — unpublishes announcement', async () => {
    mockDecoded = ADMIN;
    // findUnique returns published so service proceeds; update returns unpublished row
    mockFindUniqueAnnouncement = MOCK_PUBLISHED_ROW;
    mockUpdateAnnouncement = MOCK_UNPUBLISHED_ROW;
    const res = await app.handle(
      req(`/admin/announcements/${VALID_ID}/unpublish`, {
        method: 'POST',
        token: 'tok',
      }),
    );
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('id');
    expect(body).toHaveProperty('status');
    expect(body).toHaveProperty('updatedAt');
  });
});

// ---------------------------------------------------------------------------
describe('DELETE /admin/announcements/:id — delete', () => {
  test('200 admin — deletes unpublished announcement', async () => {
    mockDecoded = ADMIN;
    mockFindUniqueAnnouncement = MOCK_UNPUBLISHED_ROW;
    const res = await app.handle(
      req(`/admin/announcements/${VALID_ID}`, {
        method: 'DELETE',
        token: 'tok',
      }),
    );
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('id', VALID_ID);
    expect(body).toHaveProperty('status', 'deleted');
    expect(body).toHaveProperty('updatedAt');
  });
});
