import { afterEach, beforeEach, describe, expect, mock, test } from 'bun:test';
import { app } from '../src/index';
import { __setFirestoreForTest } from '../src/sync/firestore_sync';

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
let mockUpdateReport: Record<string, unknown> = {};

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    report: {
      findMany: async () => mockFindManyReports,
      findUnique: async () => mockFindUniqueReport,
      count: async () => 0,
      update: async () => mockUpdateReport,
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
  updatedAt: new Date('2026-01-01T00:00:00Z'),
  verifiedAt: null,
  rejectionRemark: null,
  scamType: { code: 'phone', labelEn: 'Phone Scam', labelTh: 'หลอกลวงโทรศัพท์' },
  evidenceFiles: [],
  moderations: [],
};

const REPORTER_ID = '11111111-1111-1111-1111-111111111111';
const MOCK_ACTION_REPORT = { id: VALID_ID, reporterId: REPORTER_ID };

const ACTION_UPDATE_RESULT = {
  id: VALID_ID,
  status: 'verified',
  updatedAt: new Date('2026-01-02T00:00:00Z'),
  reporterId: REPORTER_ID,
  title: 'Test scam',
  createdAt: new Date('2026-01-01T00:00:00Z'),
  verifiedAt: new Date('2026-01-02T00:00:00Z'),
  rejectionRemark: null,
  scamType: { code: 'phone' },
};

// In-memory Firestore stub. The service calls `mirrorMyReport(...)` after
// every admin action; this records what the mirror would have written so we
// can assert (a) it was called and (b) the admin-internal `flagged` status
// is mapped to reporter-facing `pending` per FR-6.1 inside
// `firestore_sync.toReporterStatus`.
let firestoreSets: Array<{ path: string; data: Record<string, unknown> }> = [];
let firestoreDeletes: Array<{ path: string }> = [];

const firestoreStub = {
  collection: (collPath: string) => ({
    doc: (id: string) => ({
      set: async (data: Record<string, unknown>) => {
        firestoreSets.push({ path: `${collPath}/${id}`, data });
      },
      delete: async () => {
        firestoreDeletes.push({ path: `${collPath}/${id}` });
      },
    }),
  }),
};

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

// Recursively walk the response payload looking for any reporter-identifying
// field. PRD v1.2 FR-7.4 + FR-7.8 — admin clients must never see reporter
// identity, masked or otherwise. The test asserts presence of the bug at
// every level of every payload, anti-regression for the demo-grade leak that
// shipped on `main` before this refactor.
function findReporterLeak(obj: unknown, path = ''): string | null {
  if (Array.isArray(obj)) {
    for (let i = 0; i < obj.length; i++) {
      const found = findReporterLeak(obj[i], `${path}[${i}]`);
      if (found) return found;
    }
    return null;
  }
  if (obj && typeof obj === 'object') {
    for (const [k, v] of Object.entries(obj as Record<string, unknown>)) {
      // adminId in audit-trail records is admin-to-admin transparency, not
      // reporter identity — explicitly allowed by FR-7.6.
      if (k === 'adminId') continue;
      if (/reporter|reporterhandle|user_/i.test(k)) {
        return `${path}.${k}`;
      }
      const found = findReporterLeak(v, `${path}.${k}`);
      if (found) return found;
    }
  }
  if (typeof obj === 'string' && /^User_[0-9a-f]/i.test(obj)) {
    return `${path}=<masked-handle:${obj}>`;
  }
  return null;
}

beforeEach(() => {
  mockDecoded = null;
  mockFindUniqueReport = null;
  mockFindManyReports = [];
  mockQueryRawResults = [];
  mockUpdateReport = ACTION_UPDATE_RESULT;
  firestoreSets = [];
  firestoreDeletes = [];
  __setFirestoreForTest(firestoreStub);
});

afterEach(() => {
  mockDecoded = null;
  mockFindUniqueReport = null;
  mockFindManyReports = [];
  mockQueryRawResults = [];
  __setFirestoreForTest(null);
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

  test('200 admin — queue with items omits reporter identity', async () => {
    mockDecoded = ADMIN;
    mockFindManyReports = [MOCK_QUEUE_REPORT];
    const res = await app.handle(req('/admin/reports/queue', { token: 'tok' }));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.items).toHaveLength(1);
    const item = body.items[0];
    expect(item).not.toHaveProperty('reporterHandle');
    expect(item).not.toHaveProperty('reporterId');
    expect(findReporterLeak(body)).toBeNull();
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

  test('200 admin — returns detail with AI score and no reporter identity', async () => {
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
    expect(body.report).not.toHaveProperty('reporterHandle');
    expect(body.report).not.toHaveProperty('reporterId');
    expect(findReporterLeak(body)).toBeNull();
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

  test('200 admin — approves report and returns no reporter identity', async () => {
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
    expect(findReporterLeak(body)).toBeNull();
  });

  test('200 admin — approve writes verified to my-reports mirror', async () => {
    mockDecoded = ADMIN;
    mockFindUniqueReport = MOCK_ACTION_REPORT;
    mockUpdateReport = { ...ACTION_UPDATE_RESULT, status: 'verified' };
    await app.handle(
      req(`/admin/reports/${VALID_ID}/approve`, { method: 'POST', token: 'tok', body: { remark: 'ok' } }),
    );
    expect(firestoreSets).toHaveLength(1);
    const write = firestoreSets[0]!;
    expect(write.path).toBe(`my-reports/${REPORTER_ID}/items/${VALID_ID}`);
    expect(write.data.status).toBe('verified');
  });
});

// ---------------------------------------------------------------------------
// reject / flag / unflag — auth + validation + happy path + mirror assertion.
//
// `expectedReporterStatus` is what the My Reports Firestore mirror should
// receive after the action, given `firestore_sync.toReporterStatus` maps the
// admin-internal `flagged` to the reporter-facing `pending` (FR-6.1).
const ACTION_CASES = [
  { action: 'reject' as const, dbStatus: 'rejected', mirroredStatus: 'rejected' },
  { action: 'flag' as const, dbStatus: 'flagged', mirroredStatus: 'pending' },
  { action: 'unflag' as const, dbStatus: 'pending', mirroredStatus: 'pending' },
];

ACTION_CASES.forEach(({ action, dbStatus, mirroredStatus }) => {
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

    test(`200 admin — ${action}s report and omits reporter identity`, async () => {
      mockDecoded = ADMIN;
      mockFindUniqueReport = MOCK_ACTION_REPORT;
      mockUpdateReport = { ...ACTION_UPDATE_RESULT, status: dbStatus };
      const res = await app.handle(
        req(`/admin/reports/${VALID_ID}/${action}`, { method: 'POST', token: 'tok', body: { remark: 'team decision' } }),
      );
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body).toHaveProperty('id');
      expect(body).toHaveProperty('status');
      expect(findReporterLeak(body)).toBeNull();
    });

    test(`${action} writes ${mirroredStatus} to my-reports mirror`, async () => {
      mockDecoded = ADMIN;
      mockFindUniqueReport = MOCK_ACTION_REPORT;
      mockUpdateReport = { ...ACTION_UPDATE_RESULT, status: dbStatus };
      await app.handle(
        req(`/admin/reports/${VALID_ID}/${action}`, { method: 'POST', token: 'tok', body: { remark: 'reason' } }),
      );
      expect(firestoreSets).toHaveLength(1);
      const write = firestoreSets[0]!;
      expect(write.path).toBe(`my-reports/${REPORTER_ID}/items/${VALID_ID}`);
      expect(write.data.status).toBe(mirroredStatus);
    });
  });
});
