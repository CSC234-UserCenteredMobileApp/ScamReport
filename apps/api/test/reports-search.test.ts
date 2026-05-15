import { describe, expect, mock, test } from 'bun:test';
import { app } from '../src/index';

mock.module('../src/core/firebase/admin', () => ({
  getFirebaseAdmin: () => ({}),
}));

mock.module('../src/core/firebase/messaging', () => ({
  sendFcmToUser: async () => {},
  sendFcmBroadcast: async () => {},
}));

const REPORT_PHONE = {
  id: '00000000-0000-0000-0000-000000000010',
  title: 'Phone scam alert',
  description: 'Someone called asking for OTP.',
  verifiedAt: new Date('2026-01-02T00:00:00Z'),
  createdAt: new Date('2026-01-02T00:00:00Z'),
  targetIdentifierNormalized: '+66811234567',
  targetIdentifier: '+66811234567',
  targetIdentifierKind: 'phone',
  reporterId: '99999999-0000-0000-0000-000000000001',
  scamType: { code: 'phone', labelEn: 'Phone Scam', labelTh: 'หลอกลวงทางโทรศัพท์' },
  evidenceFiles: [],
};

const REPORT_PHISHING = {
  id: '00000000-0000-0000-0000-000000000020',
  title: 'Phishing link',
  description: 'Got a phishing link via LINE.',
  verifiedAt: new Date('2026-01-01T00:00:00Z'),
  createdAt: new Date('2026-01-01T00:00:00Z'),
  targetIdentifierNormalized: 'http://evil.example.com',
  targetIdentifier: 'http://evil.example.com',
  targetIdentifierKind: 'url',
  reporterId: '99999999-0000-0000-0000-000000000002',
  scamType: { code: 'phishing', labelEn: 'Phishing', labelTh: 'ฟิชชิ่ง' },
  evidenceFiles: [],
};

let mockReports: unknown[] = [];
let capturedWhere: unknown = null;
const mockCountMap: Record<string, number> = {};

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    report: {
      findMany: async ({ where }: { where: unknown }) => {
        capturedWhere = where;
        return mockReports;
      },
      findFirst: async () => null,
      count: async ({ where }: { where: { targetIdentifierNormalized?: string } }) => {
        const tid = where.targetIdentifierNormalized;
        return tid !== undefined && mockCountMap[tid] !== undefined
          ? mockCountMap[tid]
          : 1;
      },
    },
    scamType: {
      findMany: async () => [],
    },
  }),
}));

mock.module('../src/core/supabase/storage', () => ({
  getSignedUrl: async () => 'https://example.com/signed',
}));

describe('GET /reports — text search', () => {
  test('returns 200 with items when q matches title', async () => {
    mockReports = [REPORT_PHONE];
    const res = await app.handle(new Request('http://localhost/reports?q=phone'));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.items).toHaveLength(1);
    expect(body.items[0].id).toBe(REPORT_PHONE.id);
    mockReports = [];
  });

  test('builds OR clause covering title, description, and scam type labels', async () => {
    mockReports = [];
    capturedWhere = null;
    await app.handle(new Request('http://localhost/reports?q=scam'));
    const w = capturedWhere as Record<string, unknown>;
    expect(Array.isArray(w['OR'])).toBe(true);
    const or = w['OR'] as Array<Record<string, unknown>>;
    expect(or).toHaveLength(4);
    // each branch targets a different field
    const fields = or.map((c) => Object.keys(c)[0]);
    expect(fields).toContain('title');
    expect(fields).toContain('description');
    const scamTypeBranches = or.filter((c) => c['scamType']);
    expect(scamTypeBranches).toHaveLength(2);
  });

  test('no q param produces no OR clause', async () => {
    mockReports = [];
    capturedWhere = null;
    await app.handle(new Request('http://localhost/reports'));
    const w = capturedWhere as Record<string, unknown>;
    expect(w).not.toHaveProperty('OR');
  });
});

describe('GET /reports — scamTypeCodes filter', () => {
  test('single code builds scamType.code.in filter', async () => {
    mockReports = [];
    capturedWhere = null;
    await app.handle(new Request('http://localhost/reports?scamTypeCodes=phone'));
    const w = capturedWhere as Record<string, unknown>;
    expect(w).toHaveProperty('scamType');
    const st = w['scamType'] as Record<string, unknown>;
    const code = st['code'] as Record<string, unknown>;
    expect(code['in']).toEqual(['phone']);
  });

  test('multiple codes are split on comma', async () => {
    mockReports = [];
    capturedWhere = null;
    await app.handle(new Request('http://localhost/reports?scamTypeCodes=phone,phishing'));
    const w = capturedWhere as Record<string, unknown>;
    const st = w['scamType'] as Record<string, unknown>;
    const code = st['code'] as Record<string, unknown>;
    expect(code['in']).toEqual(['phone', 'phishing']);
  });

  test('returns items filtered to requested scam type', async () => {
    mockReports = [REPORT_PHONE];
    const res = await app.handle(
      new Request('http://localhost/reports?scamTypeCodes=phone'),
    );
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.items[0].scamTypeCode).toBe('phone');
    mockReports = [];
  });
});

describe('GET /reports — sortBy=reportCount', () => {
  test('items sorted by reportCount descending', async () => {
    // REPORT_PHISHING has 5 reports, REPORT_PHONE has 2
    // findMany returns phone first (newer verifiedAt), expect phishing first after sort
    mockReports = [REPORT_PHONE, REPORT_PHISHING];
    mockCountMap['+66811234567'] = 2;
    mockCountMap['http://evil.example.com'] = 5;

    const res = await app.handle(
      new Request('http://localhost/reports?sortBy=reportCount'),
    );
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.items).toHaveLength(2);
    expect(body.items[0].id).toBe(REPORT_PHISHING.id);
    expect(body.items[1].id).toBe(REPORT_PHONE.id);

    delete mockCountMap['+66811234567'];
    delete mockCountMap['http://evil.example.com'];
    mockReports = [];
  });

  test('reportCount field reflects count value', async () => {
    mockReports = [REPORT_PHONE];
    mockCountMap['+66811234567'] = 7;

    const res = await app.handle(
      new Request('http://localhost/reports?sortBy=reportCount'),
    );
    const body = await res.json();
    expect(body.items[0].reportCount).toBe(7);

    delete mockCountMap['+66811234567'];
    mockReports = [];
  });

  test('invalid sortBy value returns 422', async () => {
    const res = await app.handle(
      new Request('http://localhost/reports?sortBy=invalid'),
    );
    expect(res.status).toBe(422);
  });
});

describe('GET /reports — no params', () => {
  test('returns all verified reports with default sort', async () => {
    mockReports = [REPORT_PHONE, REPORT_PHISHING];
    const res = await app.handle(new Request('http://localhost/reports'));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.items).toHaveLength(2);
    mockReports = [];
  });
});
