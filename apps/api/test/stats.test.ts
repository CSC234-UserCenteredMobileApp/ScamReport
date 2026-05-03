import { describe, expect, test } from 'bun:test';
import { app } from '../src/index';

describe('GET /stats', () => {
  test('returns 200 with data object', async () => {
    const response = await app.handle(new Request('http://localhost/stats'));
    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body).toHaveProperty('data');
  });
});
