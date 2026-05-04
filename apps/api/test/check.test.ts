import { describe, expect, mock, test } from 'bun:test';
import { app } from '../src/index';

mock.module('../src/core/firebase/admin', () => ({
  getFirebaseAdmin: () => ({ name: '[mock]' }),
}));

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    report: {
      findMany: async () => [
        { targetIdentifierNormalized: '+66812345678' },
        { targetIdentifierNormalized: '+66812345678' },
        { targetIdentifierNormalized: '+66898765432' },
      ],
    },
    checkLog: { create: async () => ({}) },
    $queryRaw: async () => [],
  }),
}));

describe('GET /check/phones', () => {
  test('returns 200 with phones and updatedAt', async () => {
    const response = await app.handle(
      new Request('http://localhost/check/phones'),
    );
    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body).toHaveProperty('phones');
    expect(body).toHaveProperty('updatedAt');
    expect(Array.isArray(body.phones)).toBe(true);
  });

  test('deduplicates phone numbers', async () => {
    const response = await app.handle(
      new Request('http://localhost/check/phones'),
    );
    const body = await response.json();
    const phones: string[] = body.phones;
    const unique = new Set(phones);
    expect(unique.size).toBe(phones.length);
  });

  test('returns verified scam phone numbers', async () => {
    const response = await app.handle(
      new Request('http://localhost/check/phones'),
    );
    const body = await response.json();
    expect(body.phones).toContain('+66812345678');
    expect(body.phones).toContain('+66898765432');
    expect(body.phones).toHaveLength(2);
  });
});
