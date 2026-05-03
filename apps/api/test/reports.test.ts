import { describe, expect, mock, test } from 'bun:test';
import { app } from '../src/index';

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    report: {
      findMany: async () => [],
      count: async () => 0,
    },
  }),
}));

describe('GET /reports', () => {
  test('returns 422 for limit below minimum', async () => {
    const response = await app.handle(
      new Request('http://localhost/reports?limit=0'),
    );
    expect(response.status).toBe(422);
  });

  test('returns 422 for limit above maximum', async () => {
    const response = await app.handle(
      new Request('http://localhost/reports?limit=51'),
    );
    expect(response.status).toBe(422);
  });

  test('returns 200 with items array', async () => {
    const response = await app.handle(new Request('http://localhost/reports'));
    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body).toHaveProperty('items');
  });
});
