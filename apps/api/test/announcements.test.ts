import { describe, expect, test } from 'bun:test';
import { app } from '../src/index';

describe('GET /announcements', () => {
  test('returns 422 for limit below minimum', async () => {
    const response = await app.handle(
      new Request('http://localhost/announcements?limit=0'),
    );
    expect(response.status).toBe(422);
  });

  test('returns 422 for limit above maximum', async () => {
    const response = await app.handle(
      new Request('http://localhost/announcements?limit=51'),
    );
    expect(response.status).toBe(422);
  });

  test('returns 500 when DATABASE_URL is not configured', async () => {
    // In the test environment DATABASE_URL is unset, so getPrisma() throws.
    // Elysia converts unhandled errors to 500.
    const response = await app.handle(
      new Request('http://localhost/announcements'),
    );
    expect(response.status).toBe(500);
  });
});

describe('GET /announcements/:id', () => {
  test('returns 422 for non-UUID id', async () => {
    const response = await app.handle(
      new Request('http://localhost/announcements/not-a-uuid'),
    );
    expect(response.status).toBe(422);
  });

  test('returns 422 for malformed UUID', async () => {
    const response = await app.handle(
      new Request('http://localhost/announcements/12345678-bad'),
    );
    expect(response.status).toBe(422);
  });

  test('returns 500 when DATABASE_URL is not configured', async () => {
    // Valid UUID format passes validation but DB is unavailable in tests.
    const response = await app.handle(
      new Request(
        'http://localhost/announcements/00000000-0000-0000-0000-000000000000',
      ),
    );
    expect(response.status).toBe(500);
  });
});
