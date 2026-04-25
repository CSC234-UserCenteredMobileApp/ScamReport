import { describe, expect, test } from 'bun:test';
import { app } from '../src/index';

describe('GET /examples', () => {
  test('returns the hardcoded list', async () => {
    const response = await app.handle(new Request('http://localhost/examples'));
    expect(response.status).toBe(200);
    const body = (await response.json()) as { items: { id: string; name: string }[] };
    expect(body.items).toHaveLength(3);
    expect(body.items[0]).toMatchObject({ id: '1' });
  });
});
