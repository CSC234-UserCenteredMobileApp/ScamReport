import { describe, expect, mock, test } from 'bun:test';
import { app } from '../src/index';

const MOCK_REPORT = {
  id: '00000000-0000-0000-0000-000000000001',
  title: 'Test scam',
  description: 'A scam description long enough to exercise excerpt slicing in the route handler.',
  verifiedAt: new Date('2026-01-01T00:00:00Z'),
  createdAt: new Date('2026-01-01T00:00:00Z'),
  targetIdentifierNormalized: null,
  targetIdentifier: null,
  targetIdentifierKind: null,
  reporterId: '99999999-0000-0000-0000-000000000001',
  scamType: { code: 'phone', labelEn: 'Phone Scam', labelTh: 'หลอกลวง' },
  evidenceFiles: [],
};

let mockReports: unknown[] = [];
let mockFindFirst: unknown = null;

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    report: {
      findMany: async () => mockReports,
      findFirst: async () => mockFindFirst,
      count: async () => 1,
    },
  }),
}));

mock.module('../src/core/supabase/storage', () => ({
  getSignedUrl: async () => 'https://example.com/signed-url',
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

describe('GET /reports/:id', () => {
  test('returns 404 for unknown id', async () => {
    mockFindFirst = null;
    const response = await app.handle(
      new Request('http://localhost/reports/00000000-0000-0000-0000-000000000099'),
    );
    expect(response.status).toBe(404);
    const body = await response.json();
    expect(body).toHaveProperty('error');
  });

  test('returns 200 with report detail', async () => {
    mockFindFirst = MOCK_REPORT;
    const response = await app.handle(
      new Request(`http://localhost/reports/${MOCK_REPORT.id}`),
    );
    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.id).toBe(MOCK_REPORT.id);
    expect(body.title).toBe(MOCK_REPORT.title);
    expect(body.description).toBe(MOCK_REPORT.description);
    expect(body.scamTypeLabelEn).toBe('Phone Scam');
    expect(body.evidenceFiles).toEqual([]);
    mockFindFirst = null;
  });

  test('response never contains reporter identity fields', async () => {
    mockFindFirst = MOCK_REPORT;
    const response = await app.handle(
      new Request(`http://localhost/reports/${MOCK_REPORT.id}`),
    );
    const body = await response.json();
    expect(body).not.toHaveProperty('reporterId');
    expect(body).not.toHaveProperty('reporter_id');
    expect(body).not.toHaveProperty('reporter');
    mockFindFirst = null;
  });

  test('returns evidence files with signed urls', async () => {
    mockFindFirst = {
      ...MOCK_REPORT,
      evidenceFiles: [
        {
          id: 'aaaaaaaa-0000-0000-0000-000000000001',
          storagePath: 'evidence/test.jpg',
          kind: 'image',
          mimeType: 'image/jpeg',
        },
      ],
    };
    const response = await app.handle(
      new Request(`http://localhost/reports/${MOCK_REPORT.id}`),
    );
    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.evidenceFiles).toHaveLength(1);
    expect(body.evidenceFiles[0].signedUrl).toBe('https://example.com/signed-url');
    mockFindFirst = null;
  });
});
