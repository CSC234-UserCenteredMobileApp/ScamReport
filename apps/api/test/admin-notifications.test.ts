import { afterEach, beforeEach, describe, expect, mock, test } from 'bun:test';
import { app } from '../src/index';

// ---------------------------------------------------------------------------
// Firebase mocks
// ---------------------------------------------------------------------------
let mockDecoded: { uid: string; email: string | null; role?: 'user' | 'admin' } | null = null;

mock.module('firebase-admin/auth', () => ({
  getAuth: () => ({
    verifyIdToken: async () => {
      if (!mockDecoded) throw new Error('mock: no decoded token configured');
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

// ---------------------------------------------------------------------------
// Prisma mock
// ---------------------------------------------------------------------------
let mockSubscriberRows: Array<{ userId: string }> = [];

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    user: {
      findUnique: async () =>
        mockDecoded?.role ? { role: mockDecoded.role } : null,
    },
    fcmDevice: {
      findMany: async (args: { distinct?: string[]; select?: unknown }) => {
        // Honour distinct: dedupe the stub rows by userId so tests can supply
        // a realistic many-rows-per-user fixture and still assert distinct
        // count semantics.
        if (args?.distinct?.includes('userId')) {
          const seen = new Set<string>();
          return mockSubscriberRows.filter((r) => {
            if (seen.has(r.userId)) return false;
            seen.add(r.userId);
            return true;
          });
        }
        return mockSubscriberRows;
      },
    },
  }),
}));

// ---------------------------------------------------------------------------
// Constants / helpers
// ---------------------------------------------------------------------------
const ADMIN = { uid: 'a1', email: 'a@example.com', role: 'admin' as const };
const USER = { uid: 'u1', email: 'u@example.com', role: 'user' as const };

function req(path: string, opts?: { token?: string }) {
  const headers: Record<string, string> = {};
  if (opts?.token) headers['Authorization'] = `Bearer ${opts.token}`;
  return new Request(`http://localhost${path}`, { method: 'GET', headers });
}

beforeEach(() => {
  mockDecoded = null;
  mockSubscriberRows = [];
});

afterEach(() => {
  mockDecoded = null;
  mockSubscriberRows = [];
});

// ---------------------------------------------------------------------------
describe('GET /admin/notifications/subscribers/count — auth gating', () => {
  test('401 without token', async () => {
    const res = await app.handle(req('/admin/notifications/subscribers/count'));
    expect(res.status).toBe(401);
  });

  test('403 with user-role token', async () => {
    mockDecoded = USER;
    const res = await app.handle(
      req('/admin/notifications/subscribers/count', { token: 'tok' }),
    );
    expect(res.status).toBe(403);
  });
});

describe('GET /admin/notifications/subscribers/count — body shape', () => {
  test('200 admin with zero devices', async () => {
    mockDecoded = ADMIN;
    const res = await app.handle(
      req('/admin/notifications/subscribers/count', { token: 'tok' }),
    );
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toEqual({ count: 0 });
  });

  test('200 admin counts distinct userIds (3 devices, 2 users)', async () => {
    mockDecoded = ADMIN;
    mockSubscriberRows = [
      { userId: 'u1' },
      { userId: 'u1' },
      { userId: 'u2' },
    ];
    const res = await app.handle(
      req('/admin/notifications/subscribers/count', { token: 'tok' }),
    );
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toEqual({ count: 2 });
  });
});
