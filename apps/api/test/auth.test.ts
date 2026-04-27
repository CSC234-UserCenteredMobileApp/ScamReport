import { describe, expect, test } from 'bun:test';
import { app } from '../src/index';

describe('POST /auth/sync', () => {
  test('rejects request without Authorization header with 401', async () => {
    const response = await app.handle(
      new Request('http://localhost/auth/sync', { method: 'POST' }),
    );
    expect(response.status).toBe(401);
  });

  test('rejects malformed Bearer token with 401', async () => {
    const response = await app.handle(
      new Request('http://localhost/auth/sync', {
        method: 'POST',
        headers: { Authorization: 'Bearer not-a-real-token' },
      }),
    );
    // requireAuth's verifyBearer catches the firebase-admin verifyIdToken
    // failure and returns user=null, which onBeforeHandle then 401s on.
    expect(response.status).toBe(401);
  });
});
