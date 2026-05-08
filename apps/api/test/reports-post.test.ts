import { afterEach, beforeEach, describe, expect, mock, test } from 'bun:test';

// ---------------------------------------------------------------------------
// Module-level mocks — installed before importing app
// ---------------------------------------------------------------------------

let mockDecoded: { uid: string; email: string | null; role?: string } | null = null;
let mockScamType: { id: number; isActive: boolean } | null = null;
let mockExistingDuplicate: { id: string; status: string; createdAt: Date } | null = null;
let mirrorCalls: unknown[] = [];
let conversationUpdateCalls: unknown[] = [];
let uploadCalls: Array<{ bucket: string; path: string; bytes: number }> = [];
let uploadShouldFail = false;
let txReturn: unknown = null;

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
}));

mock.module('../src/core/gemini/client', () => ({
  embed: async () => Array(768).fill(0.01),
  generateText: async () => '',
}));

mock.module('../src/sync/firestore_sync', () => ({
  mirrorMyReport: async (report: unknown) => {
    mirrorCalls.push(report);
  },
}));

mock.module('../src/core/supabase/storage', () => ({
  uploadFile: async (bucket: string, path: string, body: ArrayBuffer | Uint8Array) => {
    if (uploadShouldFail) throw new Error('mock: storage failure');
    uploadCalls.push({
      bucket,
      path,
      bytes: body instanceof Uint8Array ? body.byteLength : (body as ArrayBuffer).byteLength,
    });
    return { path };
  },
  getSignedUrl: async () => 'https://signed.example/url',
  deleteFile: async () => {},
}));

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    user: {
      upsert: async ({ where }: { where: { firebaseUid: string } }) =>
        ({ id: where.firebaseUid }),
    },
    scamType: {
      findUnique: async () => mockScamType,
    },
    report: {
      findFirst: async () => mockExistingDuplicate,
      findMany: async () => [],
      count: async () => 0,
    },
    aiConversation: {
      updateMany: async (args: unknown) => {
        conversationUpdateCalls.push(args);
        return { count: 1 };
      },
    },
    $transaction: async (fn: (tx: unknown) => Promise<unknown>) => {
      const tx = {
        report: {
          create: async () => txReturn,
        },
        evidenceFile: {
          createMany: async () => ({ count: 0 }),
        },
        aiConversation: {
          updateMany: async (args: unknown) => {
            conversationUpdateCalls.push(args);
            return { count: 1 };
          },
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

const VALID_REPORT = {
  title: 'Fake Kerry parcel SMS',
  description: 'I received an SMS asking me to click a tracking link. The form requested OTP.',
  scamTypeCode: 'phishing_sms',
  evidenceFiles: [],
};

function jsonReq(
  path: string,
  opts?: { method?: string; token?: string; body?: unknown },
) {
  const headers: Record<string, string> = { 'content-type': 'application/json' };
  if (opts?.token) headers['Authorization'] = `Bearer ${opts.token}`;
  return new Request(`http://localhost${path}`, {
    method: opts?.method ?? 'POST',
    headers,
    body: opts?.body !== undefined ? JSON.stringify(opts.body) : undefined,
  });
}

function multipartReq(token: string, file: File) {
  const fd = new FormData();
  fd.append('file', file);
  return new Request('http://localhost/reports/evidence', {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
    body: fd,
  });
}

beforeEach(() => {
  mockDecoded = null;
  mockScamType = null;
  mockExistingDuplicate = null;
  mirrorCalls = [];
  conversationUpdateCalls = [];
  uploadCalls = [];
  uploadShouldFail = false;
  txReturn = null;
});

afterEach(() => {
  mockDecoded = null;
});

// ---------------------------------------------------------------------------
// POST /reports auth + validation
// ---------------------------------------------------------------------------

describe('POST /reports', () => {
  test('401 when unauthenticated', async () => {
    const res = await app.handle(jsonReq('/reports', { body: VALID_REPORT }));
    expect(res.status).toBe(401);
  });

  test('422 when title too short', async () => {
    mockDecoded = { uid: 'u1', email: 'u@example.com' };
    const res = await app.handle(
      jsonReq('/reports', { token: 'tok', body: { ...VALID_REPORT, title: 'no' } }),
    );
    expect(res.status).toBe(422);
  });

  test('422 when description too short', async () => {
    mockDecoded = { uid: 'u1', email: 'u@example.com' };
    const res = await app.handle(
      jsonReq('/reports', { token: 'tok', body: { ...VALID_REPORT, description: 'short' } }),
    );
    expect(res.status).toBe(422);
  });

  test('422 when more than 5 evidence files', async () => {
    mockDecoded = { uid: 'u1', email: 'u@example.com' };
    const meta = {
      storagePath: 'evidence/abc.jpg',
      kind: 'image' as const,
      mimeType: 'image/jpeg',
      sizeBytes: 100,
    };
    const res = await app.handle(
      jsonReq('/reports', {
        token: 'tok',
        body: { ...VALID_REPORT, evidenceFiles: [meta, meta, meta, meta, meta, meta] },
      }),
    );
    expect(res.status).toBe(422);
  });

  test('400 when scam type code unknown', async () => {
    mockDecoded = { uid: 'u1', email: 'u@example.com' };
    mockScamType = null;
    const res = await app.handle(
      jsonReq('/reports', {
        token: 'tok',
        body: { ...VALID_REPORT, scamTypeCode: 'nonexistent' },
      }),
    );
    expect(res.status).toBe(400);
    const json = (await res.json()) as { code: string };
    expect(json.code).toBe('invalid_scam_type');
  });

  test('inserts report + calls mirror on success', async () => {
    mockDecoded = { uid: 'reporter-1', email: 'r@example.com' };
    mockScamType = { id: 2, isActive: true };
    const created = new Date('2026-05-07T00:00:00Z');
    txReturn = {
      id: '11111111-1111-1111-1111-111111111111',
      status: 'pending',
      createdAt: created,
      title: VALID_REPORT.title,
      scamType: { code: 'phishing_sms' },
    };

    const res = await app.handle(jsonReq('/reports', { token: 'tok', body: VALID_REPORT }));
    expect(res.status).toBe(200);
    const json = (await res.json()) as { id: string; status: string; createdAt: string };
    expect(json.status).toBe('pending');
    expect(json.id).toBe('11111111-1111-1111-1111-111111111111');
    expect(mirrorCalls).toHaveLength(1);
    expect((mirrorCalls[0] as { reporterId: string }).reporterId).toBe('reporter-1');
  });

  test('links conversation when sourceConversationId is provided', async () => {
    mockDecoded = { uid: 'reporter-2', email: 'r@example.com' };
    mockScamType = { id: 2, isActive: true };
    const created = new Date('2026-05-07T00:00:00Z');
    txReturn = {
      id: '22222222-2222-2222-2222-222222222222',
      status: 'pending',
      createdAt: created,
      title: VALID_REPORT.title,
      scamType: { code: 'phishing_sms' },
    };

    const conversationId = '33333333-3333-3333-3333-333333333333';
    const res = await app.handle(
      jsonReq('/reports', {
        token: 'tok',
        body: { ...VALID_REPORT, sourceConversationId: conversationId },
      }),
    );
    expect(res.status).toBe(200);
    expect(conversationUpdateCalls).toHaveLength(1);
    const args = conversationUpdateCalls[0] as {
      where: { id: string; userId: string };
      data: { linkedReportId: string };
    };
    expect(args.where.id).toBe(conversationId);
    expect(args.where.userId).toBe('reporter-2');
    expect(args.data.linkedReportId).toBe('22222222-2222-2222-2222-222222222222');
  });

  test('idempotency: returns existing report when title+scamType match within window', async () => {
    mockDecoded = { uid: 'reporter-3', email: 'r@example.com' };
    mockScamType = { id: 2, isActive: true };
    const created = new Date('2026-05-07T00:00:00Z');
    mockExistingDuplicate = {
      id: '44444444-4444-4444-4444-444444444444',
      status: 'pending',
      createdAt: created,
    };

    const res = await app.handle(
      jsonReq('/reports', {
        token: 'tok',
        body: { ...VALID_REPORT, clientSubmissionId: 'client-abc' },
      }),
    );
    expect(res.status).toBe(200);
    const json = (await res.json()) as { id: string };
    expect(json.id).toBe('44444444-4444-4444-4444-444444444444');
    // Mirror NOT called on idempotent return path.
    expect(mirrorCalls).toHaveLength(0);
  });

  test('does not surface reporter PII in response', async () => {
    mockDecoded = { uid: 'reporter-4', email: 'r@example.com' };
    mockScamType = { id: 2, isActive: true };
    const created = new Date('2026-05-07T00:00:00Z');
    txReturn = {
      id: '55555555-5555-5555-5555-555555555555',
      status: 'pending',
      createdAt: created,
      title: VALID_REPORT.title,
      scamType: { code: 'phishing_sms' },
    };

    const res = await app.handle(jsonReq('/reports', { token: 'tok', body: VALID_REPORT }));
    const body = await res.json();
    expect(body).not.toHaveProperty('reporterId');
    expect(body).not.toHaveProperty('reporter');
    expect(body).not.toHaveProperty('email');
  });
});

// ---------------------------------------------------------------------------
// POST /reports/evidence
// ---------------------------------------------------------------------------

describe('POST /reports/evidence', () => {
  test('401 when unauthenticated', async () => {
    const fd = new FormData();
    fd.append('file', new File(['x'], 'a.jpg', { type: 'image/jpeg' }));
    const res = await app.handle(
      new Request('http://localhost/reports/evidence', { method: 'POST', body: fd }),
    );
    expect(res.status).toBe(401);
  });

  test('422 for unsupported MIME', async () => {
    mockDecoded = { uid: 'u1', email: 'u@example.com' };
    const file = new File(['x'], 'a.exe', { type: 'application/octet-stream' });
    const res = await app.handle(multipartReq('tok', file));
    // Elysia rejects at validator before handler.
    expect([415, 422]).toContain(res.status);
  });

  test('uploads and returns metadata for an image', async () => {
    mockDecoded = { uid: 'reporter-5', email: 'r@example.com' };
    const file = new File([new Uint8Array([1, 2, 3, 4])], 'a.jpg', {
      type: 'image/jpeg',
    });
    const res = await app.handle(multipartReq('tok', file));
    expect(res.status).toBe(200);
    const json = (await res.json()) as {
      storagePath: string;
      kind: string;
      mimeType: string;
      sizeBytes: number;
    };
    expect(json.kind).toBe('image');
    expect(json.mimeType).toBe('image/jpeg');
    expect(json.sizeBytes).toBe(4);
    expect(json.storagePath.startsWith('reporter-5/')).toBe(true);
    expect(uploadCalls).toHaveLength(1);
    expect(uploadCalls[0]?.bucket).toBe('evidence');
  });

  test('uploads PDF with kind=pdf', async () => {
    mockDecoded = { uid: 'reporter-6', email: 'r@example.com' };
    const file = new File([new Uint8Array([1, 2])], 'a.pdf', {
      type: 'application/pdf',
    });
    const res = await app.handle(multipartReq('tok', file));
    expect(res.status).toBe(200);
    const json = (await res.json()) as { kind: string };
    expect(json.kind).toBe('pdf');
  });
});
