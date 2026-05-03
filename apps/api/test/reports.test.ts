import { describe, expect, mock, test } from 'bun:test';
import { app } from '../src/index';

const MOCK_REPORT = {
  id: '00000000-0000-0000-0000-000000000001',
  title: 'Test scam',
  description: 'A scam description long enough to exercise excerpt slicing in the route handler.',
  verifiedAt: new Date('2026-01-01T00:00:00Z'),
  createdAt: new Date('2026-01-01T00:00:00Z'),
  targetIdentifierNormalized: null,
  scamType: { code: 'phone', labelEn: 'Phone Scam', labelTh: 'หลอกลวง' },
};

let mockReports: unknown[] = [];

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    report: {
      findMany: async () => mockReports,
      count: async () => 1,
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

  test('returns 200 with empty items array', async () => {
    mockReports = [];
    const response = await app.handle(new Request('http://localhost/reports'));
    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body).toHaveProperty('items');
    expect(body.items).toHaveLength(0);
  });

  test('returns 200 with mapped report items', async () => {
    mockReports = [MOCK_REPORT];
    const response = await app.handle(new Request('http://localhost/reports'));
    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.items).toHaveLength(1);
    expect(body.items[0]).toHaveProperty('id');
    expect(body.items[0]).toHaveProperty('scamTypeLabelEn');
    mockReports = [];
  });
});
