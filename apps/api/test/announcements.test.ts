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

  test('returns 200 with items array', async () => {
    const response = await app.handle(
      new Request('http://localhost/announcements'),
    );
    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body).toHaveProperty('items');
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

  test('returns 404 for non-existent announcement', async () => {
    const response = await app.handle(
      new Request(
        'http://localhost/announcements/00000000-0000-0000-0000-000000000000',
      ),
    );
    expect(response.status).toBe(404);
  });
});
