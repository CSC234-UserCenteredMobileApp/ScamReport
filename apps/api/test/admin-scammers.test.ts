// Tests for the admin-scammers feature: search, dossier, link-scammer.
// Uses an in-memory Prisma double that supports the small surface of methods
// this route touches.

import { beforeEach, describe, expect, mock, test } from 'bun:test';

// Auth mocks ----------------------------------------------------------------

let mockDecoded: { uid: string; email: string; role: 'user' | 'admin' } | null = null;

mock.module('firebase-admin/auth', () => ({
  getAuth: () => ({
    verifyIdToken: async () => {
      if (!mockDecoded) throw new Error('mock: no decoded token');
      const { role: _role, ...rest } = mockDecoded;
      return rest;
    },
  }),
}));
mock.module('../src/core/firebase/admin', () => ({
  getFirebaseAdmin: () => ({}),
}));

mock.module('../src/core/supabase/storage', () => ({
  getSignedUrl: async () => 'https://signed.example/evidence/mock.jpg',
  uploadFile: async () => ({}),
  deleteFile: async () => undefined,
  copyFile: async () => undefined,
}));

// Prisma double -------------------------------------------------------------

const SCAMMER_ID = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const REPORT_ID = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
const FILE_ID = 'cccccccc-cccc-cccc-cccc-cccccccccccc';

let mockScammer: Record<string, unknown> | null = null;
let mockLinkedReports: unknown[] = [];

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    user: {
      findUnique: async () => (mockDecoded?.role ? { role: mockDecoded.role } : null),
      upsert: async () => ({ id: '11111111-1111-1111-1111-111111111111' }),
    },
    scammer: {
      findUnique: async ({ where }: { where: { id: string } }) =>
        where.id === SCAMMER_ID ? mockScammer : null,
      findMany: async () => [],
      update: async () => ({ id: SCAMMER_ID, reportCountCache: 1 }),
      create: async () => ({ id: SCAMMER_ID }),
    },
    scammerIdentifier: {
      findMany: async () => [
        {
          scammerId: SCAMMER_ID,
          scammer: {
            id: SCAMMER_ID,
            displayName: 'Revenue Dept Impersonator',
            suspectedName: 'Khun Somchai Wongchai',
            person: null,
            aliases: ['Khun Anan'],
            riskLevel: 'high',
            reportCountCache: 3,
          },
        },
      ],
    },
    report: {
      findMany: async () => mockLinkedReports,
      count: async () => mockLinkedReports.length,
      findUnique: async () => ({ id: REPORT_ID, scammerId: null }),
      update: async () => ({}),
    },
    checkLog: {
      findMany: async () => [],
    },
    $transaction: async (fn: (tx: unknown) => unknown) => fn({}),
    $queryRaw: async () => [],
  }),
}));

import { app } from '../src/index';

function req(method: string, path: string, body?: unknown): Promise<Response> {
  const init: RequestInit = {
    method,
    headers: { 'content-type': 'application/json', authorization: 'Bearer test-token' },
  };
  if (body !== undefined) init.body = JSON.stringify(body);
  return app.handle(new Request(`http://localhost${path}`, init));
}

beforeEach(() => {
  mockDecoded = { uid: 'firebase-admin', email: 'admin@example.com', role: 'admin' };
  mockScammer = {
    id: SCAMMER_ID,
    displayName: 'Revenue Dept Impersonator',
    suspectedName: 'Khun Somchai Wongchai',
    person: null,
    aliases: ['Khun Anan'],
    riskLevel: 'high',
    notes: 'mock',
    reportCountCache: 1,
    firstSeenAt: new Date('2026-01-01T00:00:00Z'),
    lastSeenAt: new Date('2026-05-01T00:00:00Z'),
    createdAt: new Date('2026-01-01T00:00:00Z'),
    identifiers: [
      {
        id: 'dddddddd-dddd-dddd-dddd-dddddddddddd',
        kind: 'phone',
        valueRaw: '+66 2 999 1234',
        valueNormalized: '+6629991234',
      },
    ],
  };
  mockLinkedReports = [
    {
      id: REPORT_ID,
      title: 'Fake tax demand call',
      description: 'Caller claimed unpaid tax penalties.',
      status: 'verified',
      targetIdentifier: '+66 2 999 1234',
      reporterId: '99999999-9999-9999-9999-999999999999',
      createdAt: new Date('2026-04-01T00:00:00Z'),
      verifiedAt: new Date('2026-04-02T00:00:00Z'),
      aiScore: 88,
      aiConfidence: 'high',
      scamType: {
        id: 1,
        code: 'phone_impersonation',
        labelEn: 'Phone Impersonation',
        labelTh: 'การปลอมตัวทางโทรศัพท์',
      },
      evidenceFiles: [
        {
          id: FILE_ID,
          storagePath: 'evidence/sample.jpg',
          kind: 'image',
          mimeType: 'image/jpeg',
        },
      ],
    },
  ];
});

describe('GET /admin/scammers/search', () => {
  test('admin → identifier match returns the scammer', async () => {
    const res = await req('GET', '/admin/scammers/search?identifier=' + encodeURIComponent('+66 2 999 1234'));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.items).toHaveLength(1);
    expect(body.items[0].displayName).toBe('Revenue Dept Impersonator');
  });

  test('non-admin → 403', async () => {
    mockDecoded = { uid: 'firebase-user', email: 'u@example.com', role: 'user' };
    const res = await req('GET', '/admin/scammers/search?identifier=anything');
    expect(res.status).toBe(403);
  });
});

describe('GET /admin/scammers/:id/dossier', () => {
  test('admin → dossier shape with cases, aggregates, aiStats', async () => {
    const res = await req('GET', `/admin/scammers/${SCAMMER_ID}/dossier`);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.scammer.id).toBe(SCAMMER_ID);
    expect(body.scammer.displayName).toBe('Revenue Dept Impersonator');
    expect(body.cases).toHaveLength(1);
    expect(body.cases[0].evidenceFiles[0].signedUrl).toContain('signed.example');
    expect(body.aggregates.totalCases).toBe(1);
    expect(body.aggregates.verifiedCases).toBe(1);
    expect(body.aiStats.lastAiScore).toBe(88);
    expect(body.aiStats.highCount).toBe(1);
  });

  test('unknown id → 404', async () => {
    const res = await req('GET', '/admin/scammers/00000000-0000-0000-0000-000000000000/dossier');
    expect(res.status).toBe(404);
  });
});

describe('POST /admin/reports/:id/link-scammer', () => {
  test('linking to an existing scammer id succeeds', async () => {
    const res = await req('POST', `/admin/reports/${REPORT_ID}/link-scammer`, {
      scammerId: SCAMMER_ID,
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.reportId).toBe(REPORT_ID);
    expect(body.scammerId).toBe(SCAMMER_ID);
  });
});
