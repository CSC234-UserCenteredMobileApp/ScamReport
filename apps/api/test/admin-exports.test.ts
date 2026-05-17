// Tests for GET /admin/exports/reports.csv and /admin/exports/bundle.
//
// Pattern mirrors admin-platform-summary.test.ts: Firebase auth + Prisma are
// mocked at the module level, then the composed Elysia app is exercised via
// app.handle(new Request(...)).

import { beforeEach, describe, expect, mock, test } from 'bun:test';
import ExcelJS from 'exceljs';
import { unzipSync, strFromU8 } from 'fflate';

let mockDecoded: { uid: string; email: string; role: 'user' | 'admin' } | null = null;
let lastReportWhere: unknown = null;
let lastModerationWhere: unknown = null;

const SAMPLE_REPORTS = [
  {
    id: '11111111-1111-1111-1111-111111111111',
    title: 'Fake bank SMS',
    description: 'Got SMS from "K-Bank" asking to verify card',
    scamType: { code: 'phone_imp', labelEn: 'Phone impersonation', labelTh: 'แอบอ้างทางโทรศัพท์' },
    targetIdentifierKind: 'phone' as const,
    targetIdentifierNormalized: '+66812345678',
    status: 'pending' as const,
    priorityFlag: false,
    rejectionRemark: null,
    aiScore: 84,
    aiConfidence: 'high',
    suspectedNameAtSubmit: 'Khun Somchai',
    scammerId: null,
    createdAt: new Date('2026-04-01T10:00:00Z'),
    updatedAt: new Date('2026-04-01T10:00:00Z'),
    verifiedAt: null,
  },
  {
    id: '22222222-2222-2222-2222-222222222222',
    title: 'Phishing URL claiming SCB',
    description: 'Link to scb-th[.]xyz/login asking for OTP',
    scamType: { code: 'url_phish', labelEn: 'Phishing URL', labelTh: 'ลิงก์หลอกลวง' },
    targetIdentifierKind: 'url' as const,
    targetIdentifierNormalized: 'scb-th.xyz/login',
    status: 'verified' as const,
    priorityFlag: true,
    rejectionRemark: null,
    aiScore: 92,
    aiConfidence: 'high',
    suspectedNameAtSubmit: null,
    scammerId: '33333333-3333-3333-3333-333333333333',
    createdAt: new Date('2026-04-02T10:00:00Z'),
    updatedAt: new Date('2026-04-02T11:00:00Z'),
    verifiedAt: new Date('2026-04-02T11:00:00Z'),
  },
];

const SAMPLE_MODERATION = [
  {
    id: '44444444-4444-4444-4444-444444444444',
    reportId: '22222222-2222-2222-2222-222222222222',
    adminId: '55555555-5555-5555-5555-555555555555',
    action: 'approve',
    remark: 'Confirmed via scammer DB lookup',
    createdAt: new Date('2026-04-02T11:00:00Z'),
    report: { createdAt: new Date('2026-04-02T10:00:00Z') },
  },
];

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
    report: {
      findMany: async ({ where, cursor }: { where: unknown; cursor?: { id: string } }) => {
        lastReportWhere = where;
        // Single batch — emulate end of cursor.
        return cursor ? [] : SAMPLE_REPORTS;
      },
      count: async ({ where }: { where?: Record<string, unknown> }) => {
        const status = (where?.status as string | undefined) ?? null;
        if (status === 'verified') return 1;
        if (status === 'pending') return 1;
        if (status === 'flagged') return 0;
        if (status === 'rejected') return 0;
        return 2;
      },
      groupBy: async () => [],
    },
    moderationAction: {
      findMany: async ({ where, cursor }: { where: unknown; cursor?: { id: string } }) => {
        lastModerationWhere = where;
        return cursor ? [] : SAMPLE_MODERATION;
      },
    },
    evidenceFile: {
      groupBy: async () => [
        { reportId: '11111111-1111-1111-1111-111111111111', kind: 'image', _count: { _all: 2 }, _sum: { sizeBytes: 1024n * 800n } },
      ],
    },
    scamType: {
      findMany: async () => [
        { code: 'phone_imp', labelEn: 'Phone impersonation', labelTh: 'แอบอ้างทางโทรศัพท์' },
        { code: 'url_phish', labelEn: 'Phishing URL', labelTh: 'ลิงก์หลอกลวง' },
      ],
    },
    scammer: {
      findMany: async () => [],
    },
    checkLog: {
      count: async () => 0,
      groupBy: async () => [],
    },
    $queryRaw: async () => [
      { day: new Date('2026-04-01T00:00:00Z'), verdict: 'scam', calls: 12n, p95_latency_ms: 420 },
      { day: new Date('2026-04-02T00:00:00Z'), verdict: 'safe', calls: 8n, p95_latency_ms: 380 },
    ],
  }),
}));

const { app } = await import('../src/index');

beforeEach(() => {
  mockDecoded = { uid: 'firebase-admin', email: 'admin@example.com', role: 'admin' };
  lastReportWhere = null;
  lastModerationWhere = null;
});

describe('GET /admin/exports/reports.csv', () => {
  test('missing token → 401', async () => {
    mockDecoded = null;
    const res = await app.handle(
      new Request('http://localhost/admin/exports/reports.csv', { method: 'GET' }),
    );
    expect(res.status).toBe(401);
  });

  test('user role → 403', async () => {
    mockDecoded = { uid: 'firebase-user', email: 'u@example.com', role: 'user' };
    const res = await app.handle(
      new Request('http://localhost/admin/exports/reports.csv', {
        method: 'GET',
        headers: { authorization: 'Bearer test-token' },
      }),
    );
    expect(res.status).toBe(403);
  });

  test('admin → CSV with BOM, expected headers, no reporter columns', async () => {
    const res = await app.handle(
      new Request('http://localhost/admin/exports/reports.csv', {
        method: 'GET',
        headers: { authorization: 'Bearer test-token' },
      }),
    );
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toBe('text/csv; charset=utf-8');
    expect(res.headers.get('content-disposition')).toMatch(
      /^attachment; filename="scamreport-reports-\d{8}-\d{6}\.csv"$/,
    );
    // UTF-8 BOM present in raw bytes (Response.text() decodes via TextDecoder
    // which strips a leading BOM, so check the byte stream directly).
    const bytes = new Uint8Array(await res.arrayBuffer());
    expect(bytes[0]).toBe(0xef);
    expect(bytes[1]).toBe(0xbb);
    expect(bytes[2]).toBe(0xbf);
    const body = new TextDecoder('utf-8').decode(bytes);
    const lines = body.split('\r\n');
    const header = lines[0]!.replace('﻿', '');
    expect(header).toContain('id,title,description,scamTypeCode');
    // Privacy invariant: reporter identity must not appear anywhere.
    expect(body).not.toMatch(/reporter|firebase_uid|fcm/i);
    // First non-BOM header is the columns line; there should be at least one
    // data row containing one of the sample ids.
    expect(body).toContain('11111111-1111-1111-1111-111111111111');
    expect(body).toContain('22222222-2222-2222-2222-222222222222');
  });

  test('admin → CSV scope default = pending,flagged when no status filter', async () => {
    await app.handle(
      new Request('http://localhost/admin/exports/reports.csv', {
        method: 'GET',
        headers: { authorization: 'Bearer test-token' },
      }),
    );
    expect(lastReportWhere).toMatchObject({
      status: { in: ['pending', 'flagged'] },
    });
  });

  test('admin → CSV passes explicit filter through', async () => {
    await app.handle(
      new Request(
        'http://localhost/admin/exports/reports.csv?status=verified&scamType=url_phish&priority=true&confidence=high&from=2026-04-01T00:00:00Z&to=2026-04-30T23:59:59Z',
        { method: 'GET', headers: { authorization: 'Bearer test-token' } },
      ),
    );
    const w = lastReportWhere as Record<string, unknown>;
    expect((w.status as { in: string[] }).in).toEqual(['verified']);
    expect(w.scamType).toEqual({ code: 'url_phish' });
    expect(w.priorityFlag).toBe(true);
    expect(w.aiConfidence).toBe('high');
    const cAt = w.createdAt as { gte: Date; lte: Date };
    expect(cAt.gte.toISOString()).toBe('2026-04-01T00:00:00.000Z');
    expect(cAt.lte.toISOString()).toBe('2026-04-30T23:59:59.000Z');
  });
});

describe('GET /admin/exports/bundle (XLSX default)', () => {
  test('admin → XLSX with 8 expected sheets, admin id hashed', async () => {
    const res = await app.handle(
      new Request('http://localhost/admin/exports/bundle', {
        method: 'GET',
        headers: { authorization: 'Bearer test-token' },
      }),
    );
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toBe(
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    expect(res.headers.get('content-disposition')).toMatch(
      /^attachment; filename="scamreport-bundle-\d{8}-\d{6}\.xlsx"$/,
    );
    const ab = await res.arrayBuffer();
    expect(ab.byteLength).toBeGreaterThan(1000);

    const wb = new ExcelJS.Workbook();
    await wb.xlsx.load(ab);
    const names = wb.worksheets.map((s) => s.name);
    expect(names).toEqual([
      '_meta',
      'summary',
      'reports',
      'moderation_actions',
      'evidence_summary',
      'check_logs',
      'ai_eval_summary',
      'scam_types_reference',
    ]);

    const modSheet = wb.getWorksheet('moderation_actions')!;
    // Header row + at least one data row.
    expect(modSheet.rowCount).toBeGreaterThanOrEqual(2);
    const headerRow = modSheet.getRow(1);
    const cols: string[] = [];
    headerRow.eachCell({ includeEmpty: false }, (cell) => {
      cols.push(String(cell.value));
    });
    const adminIdHashIdx = cols.indexOf('adminIdHash');
    expect(adminIdHashIdx).toBeGreaterThan(-1);
    const firstData = modSheet.getRow(2);
    const hashCell = firstData.getCell(adminIdHashIdx + 1).value;
    // Raw UUID must never appear; hashed value is 12 hex chars.
    expect(typeof hashCell).toBe('string');
    expect(hashCell).not.toBe('55555555-5555-5555-5555-555555555555');
    expect(String(hashCell)).toMatch(/^[0-9a-f]{12}$/);

    // No reporter PII anywhere in the reports sheet headers.
    const reports = wb.getWorksheet('reports')!;
    const reportCols: string[] = [];
    reports.getRow(1).eachCell({ includeEmpty: false }, (cell) => {
      reportCols.push(String(cell.value));
    });
    expect(reportCols.join(',')).not.toMatch(/reporter|email|firebase_uid|fcm/i);
  });

  test('admin → bundle scope default = last 30 days (no status filter)', async () => {
    await app.handle(
      new Request('http://localhost/admin/exports/bundle', {
        method: 'GET',
        headers: { authorization: 'Bearer test-token' },
      }),
    );
    const w = lastReportWhere as Record<string, unknown>;
    // Bundle default does not narrow status (different from CSV).
    expect(w.status).toBeUndefined();
    // Date range was applied.
    expect(w.createdAt).toBeDefined();
  });
});

describe('GET /admin/exports/bundle?format=zip', () => {
  test('admin → ZIP with the same 8 entries', async () => {
    const res = await app.handle(
      new Request('http://localhost/admin/exports/bundle?format=zip', {
        method: 'GET',
        headers: { authorization: 'Bearer test-token' },
      }),
    );
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toBe('application/zip');
    const buf = new Uint8Array(await res.arrayBuffer());
    const unzipped = unzipSync(buf);
    const keys = Object.keys(unzipped).sort();
    expect(keys).toEqual(
      [
        '_meta.csv',
        'ai_eval_summary.csv',
        'check_logs.csv',
        'evidence_summary.csv',
        'moderation_actions.csv',
        'reports.csv',
        'scam_types_reference.csv',
        'summary.csv',
      ].sort(),
    );
    const reportsCsv = strFromU8(unzipped['reports.csv']!);
    expect(reportsCsv).not.toMatch(/reporter|firebase_uid|fcm/i);
    expect(reportsCsv).toContain('11111111-1111-1111-1111-111111111111');
  });
});
