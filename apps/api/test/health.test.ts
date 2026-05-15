import { describe, expect, test } from 'bun:test';
import { app } from '../src/index';

describe('GET /health', () => {
  test('returns { ok: true }', async () => {
    const response = await app.handle(new Request('http://localhost/health'));
    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body).toEqual({ ok: true });
  });
});
