import { afterEach, beforeEach, describe, expect, mock, test } from 'bun:test';
import { app } from '../src/index';

// ---------------------------------------------------------------------------
// Firebase mocks
// ---------------------------------------------------------------------------
let mockDecoded: { uid: string; email: string | null; role?: string } | null = null;

mock.module('firebase-admin/auth', () => ({
  getAuth: () => ({
    verifyIdToken: async () => {
      if (!mockDecoded) throw new Error('mock: no decoded token configured');
      return mockDecoded;
    },
  }),
}));

mock.module('../src/core/firebase/admin', () => ({
  getFirebaseAdmin: () => ({}),
}));

mock.module('../src/core/firebase/messaging', () => ({
  sendFcmToUser: async () => {},
}));

mock.module('../src/core/gemini/client', () => ({
  embed: async () => Array(768).fill(0.01),
  generateText: async () => '',
}));

// ---------------------------------------------------------------------------
// Prisma mock — dynamic per test via module-level variables
// ---------------------------------------------------------------------------
let mockFindUniqueReport: Record<string, unknown> | null = null;
let mockFindManyReports: unknown[] = [];
let mockQueryRawResults: unknown[] = [];

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    report: {
      findMany: async () => mockFindManyReports,
      findUnique: async () => mockFindUniqueReport,
      count: async () => 0,
      update: async () => ({ id: VALID_ID, status: 'verified', updatedAt: new Date() }),
    },
    moderationAction: {
      create: async () => ({}),
    },
    $transaction: async (ops: Promise<unknown>[]) => Promise.all(ops),
    $queryRaw: async () => mockQueryRawResults,
  }),
}));

// ---------------------------------------------------------------------------
// Constants / helpers
// ---------------------------------------------------------------------------
const VALID_ID = '00000000-0000-0000-0000-000000000000';
const ADMIN = { uid: 'a1', email: 'a@example.com', role: 'admin' };
const USER = { uid: 'u1', email: 'u@example.com', role: 'user' };

const MOCK_QUEUE_REPORT = {
  id: VALID_ID,
  title: 'Test scam',
  status: 'pending',
  priorityFlag: false,
  createdAt: new Date('2026-01-01T00:00:00Z'),
  reporterId: 'abcd1234-0000-0000-0000-000000000000',
  scamType: { code: 'phone', labelEn: 'Phone Scam', labelTh: 'หลอกลวงโทรศัพท์' },
  _count: { evidenceFiles: 2 },
  moderations: [],
};

const MOCK_DETAIL_REPORT = {
  id: VALID_ID,
  title: 'Test scam',
  description: 'Detailed description.',
  status: 'pending',
  priorityFlag: false,
  targetIdentifier: '0812345678',
  targetIdentifierKind: 'phone',
  targetIdentifierNormalized: null,
  reporterId: null,
  createdAt: new Date('2026-01-01T00:00:00Z'),
  scamType: { code: 'phone', labelEn: 'Phone Scam', labelTh: 'หลอกลวงโทรศัพท์' },
  evidenceFiles: [],
  moderations: [],
};

const MOCK_ACTION_REPORT = { id: VALID_ID, reporterId: null };

function req(
  path: string,
  opts?: { method?: string; token?: string; body?: unknown },
) {
  const headers: Record<string, string> = { 'content-type': 'application/json' };
  if (opts?.token) headers['Authorization'] = `Bearer ${opts.token}`;
  return new Request(`http://localhost${path}`, {
    method: opts?.method ?? 'GET',
    headers,
    body: opts?.body ? JSON.stringify(opts.body) : undefined,
  });
}

beforeEach(() => {
  mockDecoded = null;
  mockFindUniqueReport = null;
  mockFindManyReports = [];
  mockQueryRawResults = [];
});

afterEach(() => {
  mockDecoded = null;
  mockFindUniqueReport = null;
  mockFindManyReports = [];
  mockQueryRawResults = [];
});

// ---------------------------------------------------------------------------
describe('GET /admin/reports/queue', () => {
  test('401 unauthenticated', async () => {
    const res = await app.handle(req('/admin/reports/queue'));
    expect(res.status).toBe(401);
  });

  test('403 regular user', async () => {
    mockDecoded = USER;
    const res = await app.handle(req('/admin/reports/queue', { token: 'tok' }));
    expect(res.status).toBe(403);
  });

  test('200 admin returns empty queue', async () => {
    mockDecoded = ADMIN;
    const res = await app.handle(req('/admin/reports/queue', { token: 'tok' }));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('items');
    expect(body).toHaveProperty('pendingCount');
    expect(body).toHaveProperty('flaggedCount');
  });

  test('200 admin — queue with items includes reporterHandle', async () => {
    mockDecoded = ADMIN;
    mockFindManyReports = [MOCK_QUEUE_REPORT];
    const res = await app.handle(req('/admin/reports/queue', { token: 'tok' }));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.items).toHaveLength(1);
    expect(body.items[0]).toHaveProperty('reporterHandle');
  });
});

// ---------------------------------------------------------------------------
describe('GET /admin/reports/:id', () => {
  test('401 unauthenticated', async () => {
    const res = await app.handle(req(`/admin/reports/${VALID_ID}`));
    expect(res.status).toBe(401);
  });

  test('403 regular user', async () => {
    mockDecoded = USER;
    const res = await app.handle(req(`/admin/reports/${VALID_ID}`, { token: 'tok' }));
    expect(res.status).toBe(403);
  });

  test('422 non-UUID id', async () => {
    mockDecoded = ADMIN;
    const res = await app.handle(req('/admin/reports/not-a-uuid', { token: 'tok' }));
    expect(res.status).toBe(422);
  });

  test('404 admin — report not found', async () => {
    mockDecoded = ADMIN;
    const res = await app.handle(req(`/admin/reports/${VALID_ID}`, { token: 'tok' }));
    expect(res.status).toBe(404);
  });

  test('200 admin — returns report detail with AI score', async () => {
    mockDecoded = ADMIN;
    mockFindUniqueReport = MOCK_DETAIL_REPORT;
    mockQueryRawResults = [
      { report_id: 'aaaa0000-0000-0000-0000-000000000001', similarity: 0.92 },
      { report_id: 'bbbb0000-0000-0000-0000-000000000002', similarity: 0.88 },
      { report_id: 'cccc0000-0000-0000-0000-000000000003', similarity: 0.80 },
    ];
    const res = await app.handle(req(`/admin/reports/${VALID_ID}`, { token: 'tok' }));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('report');
    expect(body.report).toHaveProperty('aiScore');
    expect(body.report).toHaveProperty('aiConfidence');
    expect(body.report).toHaveProperty('reporterHandle');
  });
});

// ---------------------------------------------------------------------------
describe('POST /admin/reports/:id/approve', () => {
  test('401 unauthenticated', async () => {
    const res = await app.handle(
      req(`/admin/reports/${VALID_ID}/approve`, { method: 'POST', body: { remark: 'ok' } }),
    );
    expect(res.status).toBe(401);
  });

  test('403 regular user', async () => {
    mockDecoded = USER;
    const res = await app.handle(
      req(`/admin/reports/${VALID_ID}/approve`, { method: 'POST', token: 'tok', body: { remark: 'ok' } }),
    );
    expect(res.status).toBe(403);
  });

  test('422 empty remark', async () => {
    mockDecoded = ADMIN;
    const res = await app.handle(
      req(`/admin/reports/${VALID_ID}/approve`, { method: 'POST', token: 'tok', body: { remark: '' } }),
    );
    expect(res.status).toBe(422);
  });

  test('422 missing remark', async () => {
    mockDecoded = ADMIN;
    const res = await app.handle(
      req(`/admin/reports/${VALID_ID}/approve`, { method: 'POST', token: 'tok', body: {} }),
    );
    expect(res.status).toBe(422);
  });

  test('404 admin — report not found', async () => {
    mockDecoded = ADMIN;
    const res = await app.handle(
      req(`/admin/reports/${VALID_ID}/approve`, { method: 'POST', token: 'tok', body: { remark: 'verified' } }),
    );
    expect(res.status).toBe(404);
  });

  test('200 admin — approves report', async () => {
    mockDecoded = ADMIN;
    mockFindUniqueReport = MOCK_ACTION_REPORT;
    const res = await app.handle(
      req(`/admin/reports/${VALID_ID}/approve`, { method: 'POST', token: 'tok', body: { remark: 'looks legit' } }),
    );
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('id');
    expect(body).toHaveProperty('status');
    expect(body).toHaveProperty('updatedAt');
  });
});

// ---------------------------------------------------------------------------
// Spot-check reject / flag / unflag — auth + validation + happy path
(['reject', 'flag', 'unflag'] as const).forEach((action) => {
  describe(`POST /admin/reports/:id/${action}`, () => {
    test('401 unauthenticated', async () => {
      const res = await app.handle(
        req(`/admin/reports/${VALID_ID}/${action}`, { method: 'POST', body: { remark: 'reason' } }),
      );
      expect(res.status).toBe(401);
    });

    test('422 empty remark', async () => {
      mockDecoded = ADMIN;
      const res = await app.handle(
        req(`/admin/reports/${VALID_ID}/${action}`, { method: 'POST', token: 'tok', body: { remark: '' } }),
      );
      expect(res.status).toBe(422);
    });

    test('422 non-UUID id', async () => {
      mockDecoded = ADMIN;
      const res = await app.handle(
        req(`/admin/reports/bad-id/${action}`, { method: 'POST', token: 'tok', body: { remark: 'reason' } }),
      );
      expect(res.status).toBe(422);
    });

    test(`200 admin — ${action}s report`, async () => {
      mockDecoded = ADMIN;
      mockFindUniqueReport = MOCK_ACTION_REPORT;
      const res = await app.handle(
        req(`/admin/reports/${VALID_ID}/${action}`, { method: 'POST', token: 'tok', body: { remark: 'team decision' } }),
      );
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body).toHaveProperty('id');
      expect(body).toHaveProperty('status');
    });
  });
});
