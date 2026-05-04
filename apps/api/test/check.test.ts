import { describe, expect, mock, test } from 'bun:test';
import { app } from '../src/index';

const REPORT_ID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

mock.module('../src/core/rag/retrieval', () => ({
  searchSimilarReports: async (text: string) => {
    if (text.startsWith('scam')) {
      return [{ reportId: REPORT_ID, similarity: 0.92 }];
    }
    if (text.startsWith('suspicious')) {
      return [{ reportId: REPORT_ID, similarity: 0.75 }];
    }
    return [];
  },
}));

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    report: {
      findMany: async (args: any) => {
        // getScamPhones — discriminated by { not: null }
        if (args?.where?.targetIdentifierNormalized?.not !== undefined) {
          return [
            { targetIdentifierNormalized: '+66812345678' },
            { targetIdentifierNormalized: '+66812345678' },
            { targetIdentifierNormalized: '+66898765432' },
          ];
        }
        // checkText — discriminated by id.in
        if (args?.where?.id?.in !== undefined) {
          return [
            {
              id: REPORT_ID,
              title: 'Smishing SMS',
              verifiedAt: new Date('2024-01-01'),
              scamType: { code: 'sms_scam' },
            },
          ];
        }
        // checkPhone — known scam number
        if (args?.where?.targetIdentifierNormalized === '+66812345678') {
          return [
            {
              id: REPORT_ID,
              title: 'Scam call',
              verifiedAt: new Date('2024-01-01'),
              scamType: { code: 'phone_scam' },
            },
          ];
        }
        return [];
      },
    },
    checkLog: {
      create: async () => ({}),
    },
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

describe('POST /check', () => {
  const post = (body: unknown) =>
    app.handle(
      new Request('http://localhost/check', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      }),
    );

  test('text — scam payload returns verdict scam with matches', async () => {
    const res = await post({ type: 'text', payload: 'scam click this link now' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.verdict).toBe('scam');
    expect(body.matchedCount).toBeGreaterThan(0);
    expect(Array.isArray(body.matches)).toBe(true);
    expect(body.matches[0]).toHaveProperty('id');
    expect(body.matches[0]).toHaveProperty('verifiedAt');
  });

  test('text — suspicious payload returns verdict suspicious', async () => {
    const res = await post({ type: 'text', payload: 'suspicious prize winner' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.verdict).toBe('suspicious');
  });

  test('text — benign payload returns verdict unknown with no matches', async () => {
    const res = await post({ type: 'text', payload: 'hello how are you today' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.verdict).toBe('unknown');
    expect(body.matchedCount).toBe(0);
    expect(body.matches).toHaveLength(0);
  });

  test('phone — known scam number returns verdict scam', async () => {
    const res = await post({ type: 'phone', payload: '+66812345678' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.verdict).toBe('scam');
    expect(body.matchedCount).toBe(1);
  });

  test('phone — unknown number returns verdict unknown', async () => {
    const res = await post({ type: 'phone', payload: '+66999999999' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.verdict).toBe('unknown');
    expect(body.matchedCount).toBe(0);
  });

  test('url — unknown URL returns verdict unknown', async () => {
    const res = await post({ type: 'url', payload: 'https://example.com/promo' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.verdict).toBe('unknown');
  });

  test('returns 422 when type is missing', async () => {
    const res = await post({ payload: 'hello' });
    expect(res.status).toBe(422);
  });

  test('returns 422 when payload is empty string', async () => {
    const res = await post({ type: 'text', payload: '' });
    expect(res.status).toBe(422);
  });
});
