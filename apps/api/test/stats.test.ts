import { describe, expect, mock, test } from 'bun:test';
import { app } from '../src/index';

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    report: {
      count: async () => 0,
      groupBy: async () => [],
    },
  }),
}));

describe('GET /stats', () => {
  test('returns 200 with data object', async () => {
    const response = await app.handle(new Request('http://localhost/stats'));
    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body).toHaveProperty('data');
  });
});
