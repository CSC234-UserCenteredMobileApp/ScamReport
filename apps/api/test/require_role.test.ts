import { afterAll, beforeAll, describe, expect, mock, test } from 'bun:test';
import { Elysia } from 'elysia';

// Mock the firebase-admin auth surface our middleware uses. The mock has to
// be installed before requireRole imports the real module, hence the dynamic
// import inside beforeAll.
let mockDecoded: { uid: string; email: string | null; role?: string } | null =
  null;
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

let userApp: ReturnType<typeof makeUserApp>;
let adminApp: ReturnType<typeof makeAdminApp>;
let requireRole: typeof import('../src/core/middleware/require_role').requireRole;

function makeUserApp(
  rr: typeof import('../src/core/middleware/require_role').requireRole,
) {
  return new Elysia()
    .use(rr('user'))
    .get('/user-only', ({ user }) => ({ uid: user!.uid, role: user!.role }));
}

function makeAdminApp(
  rr: typeof import('../src/core/middleware/require_role').requireRole,
) {
  return new Elysia()
    .use(rr('admin'))
    .get('/admin-only', ({ user }) => ({ uid: user!.uid, role: user!.role }));
}

beforeAll(async () => {
  ({ requireRole } = await import('../src/core/middleware/require_role'));
  userApp = makeUserApp(requireRole);
  adminApp = makeAdminApp(requireRole);
});

afterAll(() => {
  mockDecoded = null;
  shouldThrow = false;
});

function callUser(path: string, token?: string) {
  const headers: Record<string, string> = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  return userApp.handle(new Request(`http://localhost${path}`, { headers }));
}

function callAdmin(path: string, token?: string) {
  const headers: Record<string, string> = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  return adminApp.handle(new Request(`http://localhost${path}`, { headers }));
}

describe('requireRole middleware', () => {
  test('401 when Authorization header is missing', async () => {
    const res = await callUser('/user-only');
    expect(res.status).toBe(401);
    expect(await res.json()).toEqual({ error: 'Unauthorized' });
  });

  test('401 when Bearer token verification throws', async () => {
    shouldThrow = true;
    const res = await callUser('/user-only', 'broken-token');
    expect(res.status).toBe(401);
    shouldThrow = false;
  });

  test('200 when verified user hits a user-required route', async () => {
    mockDecoded = { uid: 'u1', email: 'u1@example.com', role: 'user' };
    const res = await callUser('/user-only', 'valid-token');
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ uid: 'u1', role: 'user' });
  });

  test('200 when admin hits a user-required route (admin is superset)', async () => {
    mockDecoded = { uid: 'a1', email: 'a1@example.com', role: 'admin' };
    const res = await callUser('/user-only', 'valid-token');
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ uid: 'a1', role: 'admin' });
  });

  test('403 when non-admin hits an admin-required route', async () => {
    mockDecoded = { uid: 'u1', email: 'u1@example.com', role: 'user' };
    const res = await callAdmin('/admin-only', 'valid-token');
    expect(res.status).toBe(403);
    expect(await res.json()).toEqual({ error: 'Forbidden' });
  });

  test('200 when admin hits an admin-required route', async () => {
    mockDecoded = { uid: 'a1', email: 'a1@example.com', role: 'admin' };
    const res = await callAdmin('/admin-only', 'valid-token');
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ uid: 'a1', role: 'admin' });
  });

  test('defaults to user role when custom claim is missing', async () => {
    mockDecoded = { uid: 'u2', email: null };
    const res = await callUser('/user-only', 'valid-token');
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ uid: 'u2', role: 'user' });
  });
});
