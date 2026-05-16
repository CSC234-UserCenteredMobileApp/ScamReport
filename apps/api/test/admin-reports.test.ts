import { afterEach, beforeEach, describe, expect, mock, test } from 'bun:test';
import { app } from '../src/index';
import { __setFirestoreForTest } from '../src/sync/firestore_sync';

// ---------------------------------------------------------------------------
// Firebase mocks
// ---------------------------------------------------------------------------
// `role` here is the role we want `requireRole` to resolve for this caller.
// It's no longer carried on the Firebase token (real tokens don't have a
// `role` claim — see `core/middleware/require_role.ts`); the prisma mock
// below reads from it to fake the `users.role` Postgres lookup.
let mockDecoded: { uid: string; email: string | null; role?: 'user' | 'admin' } | null = null;

mock.module('firebase-admin/auth', () => ({
  getAuth: () => ({
    verifyIdToken: async () => {
      if (!mockDecoded) throw new Error('mock: no decoded token configured');
      // Real tokens have no `role` claim; strip it before returning so the
      // middleware can't accidentally start trusting it again.
      const { role: _role, ...decoded } = mockDecoded;
      return decoded;
    },
  }),
}));

mock.module('../src/core/firebase/admin', () => ({
  getFirebaseAdmin: () => ({}),
}));

mock.module('../src/core/firebase/messaging', () => ({
  sendFcmToUser: async () => {},
  sendFcmBroadcast: async () => {},
}));

mock.module('../src/core/gemini/client', () => ({
  embed: async () => Array(768).fill(0.01),
  generateText: async () => '',
}));

// Supabase storage stub — evidence URL endpoint asks for a signed URL; the
// test pins the response so we can assert the route returns it verbatim.
let mockSignedUrl = 'https://signed.example/evidence/test';
mock.module('../src/core/supabase/storage', () => ({
  getSignedUrl: async () => mockSignedUrl,
  uploadFile: async () => ({}),
  deleteFile: async () => undefined,
  copyFile: async () => undefined,
  // PDF route downloads evidence bytes to embed image thumbnails. The test
  // doesn't care about real PNG bytes — a non-empty Uint8Array is enough.
  downloadFile: async () => new Uint8Array([0x89, 0x50, 0x4e, 0x47]),
}));

// ---------------------------------------------------------------------------
// Prisma mock — dynamic per test via module-level variables
// ---------------------------------------------------------------------------
let mockFindUniqueReport: Record<string, unknown> | null = null;
let mockFindManyReports: unknown[] = [];
let mockQueryRawResults: unknown[] = [];
let mockUpdateReport: Record<string, unknown> = {};
let mockEvidenceFile: Record<string, unknown> | null = null;

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    user: {
      // `requireRole` reads the canonical role from Postgres on every request.
      // Derive it from the test's `mockDecoded.role` so each test stays a
      // single assignment. Returns null when there is no decoded token, which
      // mirrors what would happen in production for an unverified caller —
      // although in practice the middleware short-circuits before the DB
      // lookup in that case.
      findUnique: async () =>
        mockDecoded?.role ? { role: mockDecoded.role } : null,
      // Action handlers resolve the Firebase UID to a Postgres users.id via
      // `resolveInternalUserId`, which upserts. Return a stable UUID so the
      // FK insert into moderation_actions doesn't 500.
      upsert: async () => ({ id: '00000000-0000-0000-0000-aaaaaaaaaaaa' }),
    },
    report: {
      findMany: async () => mockFindManyReports,
      findUnique: async () => mockFindUniqueReport,
      count: async () => 0,
      update: async () => mockUpdateReport,
    },
    moderationAction: {
      create: async () => ({}),
    },
    evidenceFile: {
      // The repo's `findEvidenceFile` filters on { id, reportId } — the mock
      // returns whatever the test set, so the test controls the cross-report
      // 404 path (set `mockEvidenceFile = null`).
      findFirst: async () => mockEvidenceFile,
    },
    $transaction: async (ops: Promise<unknown>[]) => Promise.all(ops),
    $queryRaw: async () => mockQueryRawResults,
  }),
}));

// ---------------------------------------------------------------------------
// Constants / helpers
// ---------------------------------------------------------------------------
const VALID_ID = '00000000-0000-0000-0000-000000000000';
const ADMIN = { uid: 'a1', email: 'a@example.com', role: 'admin' as const };
const USER = { uid: 'u1', email: 'u@example.com', role: 'user' as const };

const MOCK_QUEUE_REPORT = {
  id: VALID_ID,
  title: 'Test scam',
  status: 'pending',
  priorityFlag: false,
  createdAt: new Date('2026-01-01T00:00:00Z'),
  reporterId: 'abcd1234-0000-0000-0000-000000000000',
  aiScore: 87,
  aiConfidence: 'high',
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
  aiScore: 92,
  aiConfidence: 'high',
  suspectedNameAtSubmit: null,
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
  mockEvidenceFile = null;
  mockSignedUrl = 'https://signed.example/evidence/test';
  firestoreSets = [];
  firestoreDeletes = [];
  __setFirestoreForTest(firestoreStub);
});

afterEach(() => {
  mockDecoded = null;
  mockFindUniqueReport = null;
  mockFindManyReports = [];
  mockQueryRawResults = [];
  mockEvidenceFile = null;
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

  test('200 admin — queue items expose persisted AI score + confidence', async () => {
    mockDecoded = ADMIN;
    mockFindManyReports = [MOCK_QUEUE_REPORT];
    const res = await app.handle(req('/admin/reports/queue', { token: 'tok' }));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.items[0]).toHaveProperty('aiScore', 87);
    expect(body.items[0]).toHaveProperty('aiConfidence', 'high');
  });

  test('200 admin — queue items render null AI score when never computed', async () => {
    mockDecoded = ADMIN;
    mockFindManyReports = [{ ...MOCK_QUEUE_REPORT, aiScore: null, aiConfidence: null }];
    const res = await app.handle(req('/admin/reports/queue', { token: 'tok' }));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.items[0].aiScore).toBeNull();
    expect(body.items[0].aiConfidence).toBeNull();
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

  test('200 admin — returns detail with persisted AI score and no reporter identity', async () => {
    mockDecoded = ADMIN;
    mockFindUniqueReport = MOCK_DETAIL_REPORT;
    const res = await app.handle(req(`/admin/reports/${VALID_ID}`, { token: 'tok' }));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('report');
    expect(body.report.aiScore).toBe(92);
    expect(body.report.aiConfidence).toBe('high');
    expect(body.report).not.toHaveProperty('reporterHandle');
    expect(body.report).not.toHaveProperty('reporterId');
    expect(findReporterLeak(body)).toBeNull();
  });

  test('200 admin — detail triggers lazy backfill on legacy null rows (empty corpus → unknown)', async () => {
    // Legacy row with both AI fields null + an empty corpus (no $queryRaw
    // matches). The detail handler should call computeAiScore, get
    // { null, 'unknown' } back, return that to the client, and not crash.
    mockDecoded = ADMIN;
    mockFindUniqueReport = { ...MOCK_DETAIL_REPORT, aiScore: null, aiConfidence: null };
    mockQueryRawResults = [];
    const res = await app.handle(req(`/admin/reports/${VALID_ID}`, { token: 'tok' }));
    expect(res.status).toBe(200);
    const body = await res.json();
    // After backfill: score stays null (no matches), confidence reads
    // 'unknown' (helper's signal to the UI to render the pending chip).
    expect(body.report.aiScore).toBeNull();
    expect(body.report.aiConfidence).toBe('unknown');
  });

  test('200 admin — /pdf returns application/pdf bytes', async () => {
    mockDecoded = ADMIN;
    mockFindUniqueReport = MOCK_DETAIL_REPORT;
    const res = await app.handle(req(`/admin/reports/${VALID_ID}/pdf`, { token: 'tok' }));
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toBe('application/pdf');
    const buf = new Uint8Array(await res.arrayBuffer());
    expect(buf.length).toBeGreaterThan(100);
    expect(String.fromCharCode(...buf.slice(0, 4))).toBe('%PDF');
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

// ---------------------------------------------------------------------------
describe('GET /admin/reports/:id/evidence/:fileId/url', () => {
  const FILE_ID = '22222222-2222-2222-2222-222222222222';

  test('401 unauthenticated', async () => {
    const res = await app.handle(
      req(`/admin/reports/${VALID_ID}/evidence/${FILE_ID}/url`),
    );
    expect(res.status).toBe(401);
  });

  test('403 regular user', async () => {
    mockDecoded = USER;
    const res = await app.handle(
      req(`/admin/reports/${VALID_ID}/evidence/${FILE_ID}/url`, { token: 'tok' }),
    );
    expect(res.status).toBe(403);
  });

  test('404 admin — file not found (also covers cross-report URL tampering)', async () => {
    // mockEvidenceFile stays null — repo's findFirst returns null whether the
    // file doesn't exist OR exists under a different reportId. Either way the
    // route 404s, which is the security property under test.
    mockDecoded = ADMIN;
    const res = await app.handle(
      req(`/admin/reports/${VALID_ID}/evidence/${FILE_ID}/url`, { token: 'tok' }),
    );
    expect(res.status).toBe(404);
  });

  test('200 admin — returns signed URL + expiresAt', async () => {
    mockDecoded = ADMIN;
    mockEvidenceFile = {
      id: FILE_ID,
      storagePath: 'admin/evidence/foo.jpg',
      kind: 'image',
      mimeType: 'image/jpeg',
    };
    mockSignedUrl = 'https://signed.example/evidence/foo.jpg?token=abc';
    const res = await app.handle(
      req(`/admin/reports/${VALID_ID}/evidence/${FILE_ID}/url`, { token: 'tok' }),
    );
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.url).toBe('https://signed.example/evidence/foo.jpg?token=abc');
    expect(typeof body.expiresAt).toBe('string');
    expect(new Date(body.expiresAt).getTime()).toBeGreaterThan(Date.now());
  });
});
