import { describe, expect, mock, test } from 'bun:test';
import { app } from '../src/index';

let mockFirebaseUser: { uid: string; email: string | null } | null = null;

mock.module('firebase-admin/auth', () => ({
  getAuth: () => ({
    verifyIdToken: async () => {
      if (!mockFirebaseUser) throw new Error('mock: token invalid');
      return mockFirebaseUser;
    },
  }),
}));

mock.module('../src/core/firebase/admin', () => ({
  getFirebaseAdmin: () => ({}),
}));

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    user: {
      upsert: async () => ({
        id: '00000000-0000-0000-0000-000000000001',
        firebaseUid: 'test-uid',
        email: 'test@example.com',
        displayName: null,
        role: 'user',
        preferredLanguage: 'th',
      }),
    },
  }),
}));

describe('POST /auth/sync', () => {
  test('rejects request without Authorization header with 401', async () => {
    const response = await app.handle(
      new Request('http://localhost/auth/sync', { method: 'POST' }),
    );
    expect(response.status).toBe(401);
  });

  test('rejects malformed Bearer token with 401', async () => {
    mockFirebaseUser = null;
    const response = await app.handle(
      new Request('http://localhost/auth/sync', {
        method: 'POST',
        headers: { Authorization: 'Bearer not-a-real-token' },
      }),
    );
    expect(response.status).toBe(401);
  });

  test('returns 200 with synced user for valid token', async () => {
    mockFirebaseUser = { uid: 'test-uid', email: 'test@example.com' };
    const response = await app.handle(
      new Request('http://localhost/auth/sync', {
        method: 'POST',
        headers: { Authorization: 'Bearer valid-token' },
      }),
    );
    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body).toHaveProperty('user');
    expect(body.user).toHaveProperty('id');
    expect(body.user).toHaveProperty('role');
    mockFirebaseUser = null;
  });
});
