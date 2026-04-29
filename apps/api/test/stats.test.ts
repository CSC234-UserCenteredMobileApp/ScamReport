import { describe, expect, test } from 'bun:test';
import { app } from '../src/index';

describe('GET /stats', () => {
  test('returns 500 when DATABASE_URL is not configured', async () => {
    // In the test environment DATABASE_URL is unset, so getPrisma() throws.
    // Elysia converts unhandled errors to 500.
    const response = await app.handle(new Request('http://localhost/stats'));
    expect(response.status).toBe(500);
  });
});
