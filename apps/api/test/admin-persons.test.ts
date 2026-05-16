// Tests for GET /admin/persons/:id/dossier + /pdf.

import { beforeEach, describe, expect, mock, test } from 'bun:test';

let mockDecoded: { uid: string; email: string; role: 'user' | 'admin' } | null = null;
let mockPerson: Record<string, unknown> | null = null;

mock.module('firebase-admin/auth', () => ({
  getAuth: () => ({
    verifyIdToken: async () => {
      if (!mockDecoded) throw new Error('no token');
      const { role: _role, ...rest } = mockDecoded;
      return rest;
    },
  }),
}));
mock.module('../src/core/firebase/admin', () => ({
  getFirebaseAdmin: () => ({}),
}));

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    user: {
      findUnique: async () => (mockDecoded?.role ? { role: mockDecoded.role } : null),
      upsert: async () => ({ id: '11111111-1111-1111-1111-111111111111' }),
    },
    person: {
      findUnique: async () => mockPerson,
    },
  }),
}));

import { app } from '../src/index';

const PERSON_ID = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

beforeEach(() => {
  mockDecoded = { uid: 'firebase-admin', email: 'admin@example.com', role: 'admin' };
  mockPerson = {
    id: PERSON_ID,
    fullName: 'Khun Somchai Wongchai',
    aliases: ['Officer Anan'],
    riskLevel: 'high',
    notes: null,
    reportCountCache: 4,
    campaignCountCache: 2,
    firstSeenAt: new Date('2026-01-01T00:00:00Z'),
    lastSeenAt: new Date('2026-05-01T00:00:00Z'),
    createdAt: new Date('2026-01-01T00:00:00Z'),
    scammers: [
      {
        id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        displayName: 'Revenue Dept Impersonator',
        suspectedName: 'Khun Somchai Wongchai',
        riskLevel: 'high',
        reportCountCache: 4,
        firstSeenAt: new Date('2026-04-01T00:00:00Z'),
        lastSeenAt: new Date('2026-05-01T00:00:00Z'),
        reports: [
          {
            scamType: { code: 'phone_impersonation' },
            verifiedAt: new Date('2026-05-01T00:00:00Z'),
          },
        ],
      },
    ],
  };
});

function req(path: string): Request {
  return new Request(`http://localhost${path}`, {
    method: 'GET',
    headers: { authorization: 'Bearer test-token' },
  });
}

describe('GET /admin/persons/:id/dossier', () => {
  test('admin → returns person + campaigns', async () => {
    const res = await app.handle(req(`/admin/persons/${PERSON_ID}/dossier`));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.person.fullName).toBe('Khun Somchai Wongchai');
    expect(body.campaigns).toHaveLength(1);
    expect(body.campaigns[0].displayName).toBe('Revenue Dept Impersonator');
    expect(body.campaigns[0].topScamTypeCodes).toContain('phone_impersonation');
  });

  test('non-admin → 403', async () => {
    mockDecoded = { uid: 'firebase-user', email: 'u@example.com', role: 'user' };
    const res = await app.handle(req(`/admin/persons/${PERSON_ID}/dossier`));
    expect(res.status).toBe(403);
  });

  test('unknown id → 404', async () => {
    mockPerson = null;
    const res = await app.handle(req(`/admin/persons/${PERSON_ID}/dossier`));
    expect(res.status).toBe(404);
  });

  test('admin → /pdf returns application/pdf bytes', async () => {
    const res = await app.handle(req(`/admin/persons/${PERSON_ID}/pdf`));
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toBe('application/pdf');
    const buf = new Uint8Array(await res.arrayBuffer());
    expect(buf.length).toBeGreaterThan(100);
    expect(String.fromCharCode(...buf.slice(0, 4))).toBe('%PDF');
  });
});
