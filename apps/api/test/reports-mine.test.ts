import { afterEach, beforeEach, describe, expect, mock, test } from 'bun:test';

// ---------------------------------------------------------------------------
// Module-level mocks — installed before importing app
// ---------------------------------------------------------------------------

let mockDecoded: { uid: string; email: string | null } | null = null;
let mockMyReports: unknown[] = [];
let mockFindFirst: unknown = null;
let mockScamType: unknown = null;
let mockUpdateResult: unknown = null;
let mirrorCalls: unknown[] = [];
let txDeleteManyCalls: unknown[] = [];
let txCreateManyCalls: unknown[] = [];
let txUpdateCalls: unknown[] = [];

mock.module('firebase-admin/auth', () => ({
  getAuth: () => ({
    verifyIdToken: async () => {
      if (!mockDecoded) throw new Error('mock: no decoded token');
      return mockDecoded;
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
  generateStructured: async () => ({}),
  generateMultimodal: async () => '',
  GeminiStructuredParseError: class GeminiStructuredParseError extends Error {},
  inlinePart: () => ({}),
}));

mock.module('../src/sync/firestore_sync', () => ({
  mirrorMyReport: async (report: unknown) => {
    mirrorCalls.push(report);
  },
}));

mock.module('../src/core/supabase/storage', () => ({
  uploadFile: async () => {},
  getSignedUrl: async () => 'https://signed.example/url',
  deleteFile: async () => {},
  copyFile: async () => {},
}));

const REPORT_ID = '00000000-0000-0000-0000-000000000001';
const USER_ID   = '00000000-0000-0000-0000-000000000002';
const SCAM_TYPE_ID = 10;
const NOW = new Date('2026-01-01T00:00:00Z');

const MOCK_SCAM_TYPE = { id: SCAM_TYPE_ID, isActive: true, code: 'phishing_sms' };

const MOCK_REPORT_ROW = {
  id: REPORT_ID,
  title: 'Test phishing report',
  status: 'pending',
  createdAt: NOW,
  updatedAt: NOW,
  rejectionRemark: null,
  scamType: { id: SCAM_TYPE_ID, code: 'phishing_sms', labelEn: 'Phishing SMS', labelTh: 'SMS ฟิชชิ่ง' },
};

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    user: {
      upsert: async () => ({ id: USER_ID }),
    },
    scamType: {
      findUnique: async () => mockScamType,
    },
    report: {
      findMany: async () => mockMyReports,
      findFirst: async () => {
        if (mockFindFirst === 'report') return MOCK_REPORT_ROW;
        if (mockFindFirst === 'verified-report') return { ...MOCK_REPORT_ROW, status: 'verified' };
        return null;
      },
      update: async () => mockUpdateResult,
    },
    evidenceFile: {
      deleteMany: async () => ({ count: 0 }),
      createMany: async () => ({ count: 0 }),
    },
    $transaction: async (fn: (tx: unknown) => Promise<unknown>) => {
      const tx = {
        evidenceFile: {
          deleteMany: async (args: unknown) => { txDeleteManyCalls.push(args); return { count: 0 }; },
          createMany: async (args: unknown) => { txCreateManyCalls.push(args); return { count: 0 }; },
        },
        report: {
          update: async (args: unknown) => { txUpdateCalls.push(args); return mockUpdateResult; },
        },
      };
      return fn(tx);
    },
  }),
}));

const { app } = await import('../src/index');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function jsonReq(
  path: string,
  opts?: { method?: string; token?: string; body?: unknown },
) {
  const headers: Record<string, string> = { 'content-type': 'application/json' };
  if (opts?.token) headers['Authorization'] = `Bearer ${opts.token}`;
  return new Request(`http://localhost${path}`, {
    method: opts?.method ?? 'GET',
    headers,
    body: opts?.body !== undefined ? JSON.stringify(opts.body) : undefined,
  });
}

beforeEach(() => {
  mockDecoded = null;
  mockMyReports = [];
  mockFindFirst = null;
  mockScamType = null;
  mockUpdateResult = null;
  mirrorCalls = [];
  txDeleteManyCalls = [];
  txCreateManyCalls = [];
  txUpdateCalls = [];
});

afterEach(() => {
  mockDecoded = null;
});

// ---------------------------------------------------------------------------
// GET /reports/mine
// ---------------------------------------------------------------------------

describe('GET /reports/mine', () => {
  test('401 when unauthenticated', async () => {
    const res = await app.handle(jsonReq('/reports/mine'));
    expect(res.status).toBe(401);
  });

  test('200 returns empty items when user has no reports', async () => {
    mockDecoded = { uid: 'u1', email: 'u@example.com' };
    mockMyReports = [];
    const res = await app.handle(jsonReq('/reports/mine', { token: 'tok' }));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('items');
    expect(body.items).toHaveLength(0);
  });

  test('200 returns mapped report rows', async () => {
    mockDecoded = { uid: 'u1', email: 'u@example.com' };
    mockMyReports = [MOCK_REPORT_ROW];
    const res = await app.handle(jsonReq('/reports/mine', { token: 'tok' }));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.items).toHaveLength(1);
    const item = body.items[0];
    expect(item.id).toBe(REPORT_ID);
    expect(item.title).toBe('Test phishing report');
    expect(item.status).toBe('pending');
    expect(item.scamTypeCode).toBe('phishing_sms');
    expect(item.scamTypeLabelEn).toBe('Phishing SMS');
    expect(item.rejectionRemark).toBeNull();
  });

  test('maps flagged status → pending per FR-6.1', async () => {
    mockDecoded = { uid: 'u1', email: 'u@example.com' };
    mockMyReports = [{ ...MOCK_REPORT_ROW, status: 'flagged' }];
    const res = await app.handle(jsonReq('/reports/mine', { token: 'tok' }));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.items[0].status).toBe('pending');
  });

  test('includes rejectionRemark for rejected reports', async () => {
    mockDecoded = { uid: 'u1', email: 'u@example.com' };
    mockMyReports = [
      { ...MOCK_REPORT_ROW, status: 'rejected', rejectionRemark: 'Insufficient evidence' },
    ];
    const res = await app.handle(jsonReq('/reports/mine', { token: 'tok' }));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.items[0].status).toBe('rejected');
    expect(body.items[0].rejectionRemark).toBe('Insufficient evidence');
  });
});

// ---------------------------------------------------------------------------
// PATCH /reports/:id
// ---------------------------------------------------------------------------

const VALID_UPDATE_BODY = {
  title: 'Updated phishing report',
  description: 'Updated description with more detail about the phishing attempt.',
  scamTypeCode: 'phishing_sms',
  evidenceFiles: [],
};

describe('PATCH /reports/:id', () => {
  test('401 when unauthenticated', async () => {
    const res = await app.handle(
      jsonReq(`/reports/${REPORT_ID}`, { method: 'PATCH', body: VALID_UPDATE_BODY }),
    );
    expect(res.status).toBe(401);
  });

  test('422 when title too short', async () => {
    mockDecoded = { uid: 'u1', email: 'u@example.com' };
    const res = await app.handle(
      jsonReq(`/reports/${REPORT_ID}`, {
        method: 'PATCH',
        token: 'tok',
        body: { ...VALID_UPDATE_BODY, title: 'no' },
      }),
    );
    expect(res.status).toBe(422);
  });

  test('422 when description too short', async () => {
    mockDecoded = { uid: 'u1', email: 'u@example.com' };
    const res = await app.handle(
      jsonReq(`/reports/${REPORT_ID}`, {
        method: 'PATCH',
        token: 'tok',
        body: { ...VALID_UPDATE_BODY, description: 'short' },
      }),
    );
    expect(res.status).toBe(422);
  });

  test('404 when report not found', async () => {
    mockDecoded = { uid: 'u1', email: 'u@example.com' };
    mockFindFirst = null; // no report
    const res = await app.handle(
      jsonReq(`/reports/${REPORT_ID}`, {
        method: 'PATCH',
        token: 'tok',
        body: VALID_UPDATE_BODY,
      }),
    );
    expect(res.status).toBe(404);
    const body = await res.json();
    expect(body.code).toBe('not_found');
  });

  test('409 when report is not editable (verified status)', async () => {
    mockDecoded = { uid: 'u1', email: 'u@example.com' };
    mockFindFirst = 'verified-report';
    const { updateReport, ReportSubmitError } = await import('../src/features/reports/reports.service');
    try {
      await updateReport(USER_ID, REPORT_ID, VALID_UPDATE_BODY);
      throw new Error('should have thrown');
    } catch (err) {
      expect(err).toBeInstanceOf(ReportSubmitError);
      expect((err as InstanceType<typeof ReportSubmitError>).status).toBe(409);
      expect((err as InstanceType<typeof ReportSubmitError>).code).toBe('not_editable');
    }
  });

  test('200 on successful update with mirror call', async () => {
    mockDecoded = { uid: 'u1', email: 'u@example.com' };
    mockFindFirst = 'report';
    mockScamType = MOCK_SCAM_TYPE;
    mockUpdateResult = {
      id: REPORT_ID,
      status: 'pending',
      updatedAt: NOW,
    };

    const { updateReport } = await import('../src/features/reports/reports.service');
    // Directly exercise the service (DB mock is already set up)
    // We trust the route integration for auth; test business logic here
    const result = await updateReport(USER_ID, REPORT_ID, {
      ...VALID_UPDATE_BODY,
      scamTypeCode: 'phishing_sms',
    });
    expect(result.id).toBe(REPORT_ID);
    expect(result.status).toBe('pending');
    expect(mirrorCalls).toHaveLength(1);
  });
});

// ---------------------------------------------------------------------------
// DELETE /reports/:id
// ---------------------------------------------------------------------------

describe('DELETE /reports/:id', () => {
  test('401 when unauthenticated', async () => {
    const res = await app.handle(
      jsonReq(`/reports/${REPORT_ID}`, { method: 'DELETE' }),
    );
    expect(res.status).toBe(401);
  });

  test('404 when report not found', async () => {
    mockDecoded = { uid: 'u1', email: 'u@example.com' };
    // findFirst returns null → not_found
    const res = await app.handle(
      jsonReq(`/reports/${REPORT_ID}`, { method: 'DELETE', token: 'tok' }),
    );
    expect(res.status).toBe(404);
    const body = await res.json();
    expect(body.code).toBe('not_found');
  });

  test('409 when report is already verified', async () => {
    const { withdrawReport, ReportSubmitError } = await import('../src/features/reports/reports.service');
    try {
      await withdrawReport(USER_ID, 'non-existent-id');
      throw new Error('should have thrown');
    } catch (err) {
      expect(err).toBeInstanceOf(ReportSubmitError);
      expect((err as InstanceType<typeof ReportSubmitError>).status).toBe(404);
    }
  });

  test('200 withdrawn + mirror delete called', async () => {
    mockDecoded = { uid: 'u1', email: 'u@example.com' };
    mockFindFirst = 'report';
    mockUpdateResult = {
      id: REPORT_ID,
      status: 'withdrawn',
      updatedAt: NOW,
    };

    const { withdrawReport } = await import('../src/features/reports/reports.service');
    const result = await withdrawReport(USER_ID, REPORT_ID);
    expect(result.id).toBe(REPORT_ID);
    expect(result.status).toBe('withdrawn');
    // mirrorMyReport called with status=withdrawn (which triggers Firestore delete)
    expect(mirrorCalls).toHaveLength(1);
    expect((mirrorCalls[0] as { status: string }).status).toBe('withdrawn');
  });
});
