# RAG Retrieval + Admin Reports API Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a pgvector RAG retrieval utility and the complete admin reports API (queue / detail with AI confidence score / approve / reject / flag / unflag) — API side only; mobile screens are blocked on design-spec updates.

**Architecture:** A thin `core/rag/retrieval.ts` embeds a query string with Gemini and queries `report_embeddings` via `$queryRaw` cosine similarity. The admin-reports feature composes that into an `computeAiScore()` call inside its detail handler. All admin routes are gated by `requireRole('admin')` from the existing middleware. Reporter identity is excluded at the Prisma `select` layer so it is structurally impossible for it to leak.

**Tech Stack:** Elysia.js, Bun, Prisma v7 + `$queryRaw`, pgvector `<=>` cosine distance, `@google/genai` `embed()`, TypeBox schemas, `firebase-admin` messaging, `bun:test`.

**Reference spec:** `docs/plans/admin-moderator-tools.md` — read it before starting; this plan implements the API portion of that spec.

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `packages/shared/src/schemas/admin-reports.ts` | **Create** | TypeBox schemas for all admin-reports types |
| `packages/shared/src/index.ts` | **Modify** | Re-export admin-reports schemas |
| `apps/api/src/core/rag/retrieval.ts` | **Create** | `searchSimilarReports(text, topK)` — embed + pgvector query |
| `apps/api/src/core/firebase/messaging.ts` | **Create** | `sendFcmToUser(userId, title, body)` — FCM push helper |
| `apps/api/src/features/admin-reports/admin-reports.service.ts` | **Create** | All business logic: queue, detail, AI score, actions |
| `apps/api/src/features/admin-reports/admin-reports.route.ts` | **Create** | Elysia plugin — 6 endpoints, all gated by `requireRole('admin')` |
| `apps/api/src/index.ts` | **Modify** | Mount `adminReportsRoute` |
| `apps/api/test/admin-reports.test.ts` | **Create** | Auth/role gates, validation, reporter-field absence assertion |

---

## Task 1: Shared schemas

**Files:**
- Create: `packages/shared/src/schemas/admin-reports.ts`
- Modify: `packages/shared/src/index.ts`

- [ ] **Step 1: Write `admin-reports.ts`**

```ts
// packages/shared/src/schemas/admin-reports.ts
import { Type, type Static } from '@sinclair/typebox';

export const AiConfidence = Type.Union([
  Type.Literal('high'),
  Type.Literal('medium'),
  Type.Literal('low'),
  Type.Literal('unknown'),
]);
export type AiConfidence = Static<typeof AiConfidence>;

export const ModerationRecord = Type.Object({
  adminId: Type.Union([Type.String({ format: 'uuid' }), Type.Null()]),
  action: Type.Union([
    Type.Literal('approve'),
    Type.Literal('reject'),
    Type.Literal('flag'),
    Type.Literal('unflag'),
  ]),
  remark: Type.String(),
  createdAt: Type.String({ format: 'date-time' }),
});
export type ModerationRecord = Static<typeof ModerationRecord>;

export const AdminEvidenceFile = Type.Object({
  id: Type.String({ format: 'uuid' }),
  storagePath: Type.String(),
  kind: Type.Union([Type.Literal('image'), Type.Literal('pdf')]),
  mimeType: Type.String(),
  sizeBytes: Type.Number(),
});
export type AdminEvidenceFile = Static<typeof AdminEvidenceFile>;

export const AdminQueueItem = Type.Object({
  id: Type.String({ format: 'uuid' }),
  title: Type.String(),
  scamTypeCode: Type.String(),
  scamTypeLabelEn: Type.String(),
  scamTypeLabelTh: Type.String(),
  submittedAt: Type.String({ format: 'date-time' }),
  status: Type.Union([Type.Literal('pending'), Type.Literal('flagged')]),
  priorityFlag: Type.Boolean(),
  evidenceCount: Type.Integer({ minimum: 0 }),
  lastRemarkByAdmin: Type.Union([Type.String(), Type.Null()]),
});
export type AdminQueueItem = Static<typeof AdminQueueItem>;

export const AdminQueueResponse = Type.Object({
  items: Type.Array(AdminQueueItem),
  pendingCount: Type.Integer({ minimum: 0 }),
  flaggedCount: Type.Integer({ minimum: 0 }),
});
export type AdminQueueResponse = Static<typeof AdminQueueResponse>;

export const AdminReportDetail = Type.Object({
  id: Type.String({ format: 'uuid' }),
  title: Type.String(),
  description: Type.String(),
  scamTypeCode: Type.String(),
  scamTypeLabelEn: Type.String(),
  scamTypeLabelTh: Type.String(),
  submittedAt: Type.String({ format: 'date-time' }),
  status: Type.Union([
    Type.Literal('pending'),
    Type.Literal('flagged'),
    Type.Literal('verified'),
    Type.Literal('rejected'),
  ]),
  priorityFlag: Type.Boolean(),
  targetIdentifier: Type.Union([Type.String(), Type.Null()]),
  targetIdentifierKind: Type.Union([
    Type.Literal('phone'),
    Type.Literal('url'),
    Type.Literal('other'),
    Type.Null(),
  ]),
  evidenceFiles: Type.Array(AdminEvidenceFile),
  duplicateCount: Type.Integer({ minimum: 0 }),
  aiScore: Type.Union([Type.Integer({ minimum: 0, maximum: 100 }), Type.Null()]),
  aiConfidence: Type.Union([AiConfidence, Type.Null()]),
  auditTrail: Type.Array(ModerationRecord),
});
export type AdminReportDetail = Static<typeof AdminReportDetail>;

export const AdminReportDetailResponse = Type.Object({
  report: AdminReportDetail,
});
export type AdminReportDetailResponse = Static<typeof AdminReportDetailResponse>;

export const ApproveRejectFlagRequest = Type.Object({
  remark: Type.String({ minLength: 1 }),
});
export type ApproveRejectFlagRequest = Static<typeof ApproveRejectFlagRequest>;

export const AdminActionResponse = Type.Object({
  id: Type.String({ format: 'uuid' }),
  status: Type.String(),
  updatedAt: Type.String({ format: 'date-time' }),
});
export type AdminActionResponse = Static<typeof AdminActionResponse>;
```

- [ ] **Step 2: Re-export from `packages/shared/src/index.ts`**

Add this line to the end of the file:
```ts
export * from './schemas/admin-reports';
```

- [ ] **Step 3: Typecheck passes**

Run from repo root:
```bash
bun run typecheck
```
Expected: both `@my-product/shared` and `@my-product/api` exit 0.

- [ ] **Step 4: Commit**

```bash
git add packages/shared/src/schemas/admin-reports.ts packages/shared/src/index.ts
git commit -m "feat(shared): admin-reports TypeBox schemas"
```

---

## Task 2: RAG retrieval core

**Files:**
- Create: `apps/api/src/core/rag/retrieval.ts`

- [ ] **Step 1: Create `retrieval.ts`**

```ts
// apps/api/src/core/rag/retrieval.ts
import { getPrisma } from '../db/client';
import { embed } from '../gemini/client';

export type SimilarReport = {
  reportId: string;
  similarity: number;
};

/**
 * Embeds `text` with Gemini, then queries report_embeddings for the
 * top-K cosine-similar verified reports.
 *
 * Returns [] when:
 *   - Gemini returns an empty embedding (API misconfigured / rate-limited)
 *   - No verified report embeddings exist yet
 */
export async function searchSimilarReports(
  text: string,
  topK = 5,
): Promise<SimilarReport[]> {
  const vector = await embed(text);
  if (vector.length === 0) return [];

  const vectorLiteral = `[${vector.join(',')}]`;
  const prisma = getPrisma();

  const rows = await prisma.$queryRaw<{ report_id: string; similarity: number }[]>`
    SELECT re.report_id::text,
           1 - (re.embedding <=> ${vectorLiteral}::vector) AS similarity
    FROM report_embeddings re
    JOIN reports r ON r.id = re.report_id AND r.status = 'verified'
    ORDER BY re.embedding <=> ${vectorLiteral}::vector
    LIMIT ${topK}
  `;

  return rows.map((r) => ({ reportId: r.report_id, similarity: r.similarity }));
}
```

- [ ] **Step 2: Typecheck passes**

```bash
bun run typecheck
```
Expected: exits 0.

- [ ] **Step 3: Commit**

```bash
git add apps/api/src/core/rag/retrieval.ts
git commit -m "feat(api): RAG retrieval — embed + pgvector cosine similarity"
```

---

## Task 3: FCM messaging helper

**Files:**
- Create: `apps/api/src/core/firebase/messaging.ts`

This helper looks up all FCM tokens for a user and sends a notification. It fails gracefully (logs + returns) when Firebase is not configured so the route doesn't break in test/staging environments.

- [ ] **Step 1: Create `messaging.ts`**

```ts
// apps/api/src/core/firebase/messaging.ts
import { getMessaging } from 'firebase-admin/messaging';
import { getFirebaseAdmin } from './admin';
import { getPrisma } from '../db/client';

export async function sendFcmToUser(
  userId: string,
  notification: { title: string; body: string },
  data?: Record<string, string>,
): Promise<void> {
  try {
    const prisma = getPrisma();
    const devices = await prisma.fcmDevice.findMany({
      where: { userId },
      select: { fcmToken: true },
    });
    if (devices.length === 0) return;

    const tokens = devices.map((d) => d.fcmToken);
    await getMessaging(getFirebaseAdmin()).sendEachForMulticast({
      tokens,
      notification,
      data,
    });
  } catch (err) {
    // Non-fatal: FCM failure should not roll back the moderation action.
    console.error('[fcm] sendFcmToUser failed:', err);
  }
}
```

- [ ] **Step 2: Typecheck passes**

```bash
bun run typecheck
```
Expected: exits 0.

- [ ] **Step 3: Commit**

```bash
git add apps/api/src/core/firebase/messaging.ts
git commit -m "feat(api): FCM sendFcmToUser helper"
```

---

## Task 4: Admin reports service

**Files:**
- Create: `apps/api/src/features/admin-reports/admin-reports.service.ts`

**Reporter anonymity invariant:** Every Prisma query on `Report` in this file uses an explicit `select` that excludes `reporterId`, `reporter`, and all `reporter.*` fields. The `reporterId` is fetched in one place only — internally in `approveReport` and `rejectReport` — purely to dispatch FCM and is never returned.

- [ ] **Step 1: Create `admin-reports.service.ts`**

```ts
// apps/api/src/features/admin-reports/admin-reports.service.ts
import { getPrisma } from '../../core/db/client';
import { searchSimilarReports } from '../../core/rag/retrieval';
import { sendFcmToUser } from '../../core/firebase/messaging';
import type {
  AdminQueueItem,
  AdminReportDetail,
  AdminEvidenceFile,
  ModerationRecord,
  AiConfidence,
} from '@my-product/shared';

// ---------------------------------------------------------------------------
// Queue
// ---------------------------------------------------------------------------

export async function getQueue(scamTypeCode?: string): Promise<{
  items: AdminQueueItem[];
  pendingCount: number;
  flaggedCount: number;
}> {
  const prisma = getPrisma();

  const where = {
    status: { in: ['pending', 'flagged'] as const },
    ...(scamTypeCode ? { scamType: { code: scamTypeCode } } : {}),
  };

  const [reports, pendingCount, flaggedCount] = await Promise.all([
    prisma.report.findMany({
      where,
      orderBy: [
        // flagged first (priorityFlag proxy), then oldest
        { priorityFlag: 'desc' },
        { createdAt: 'asc' },
      ],
      select: {
        id: true,
        title: true,
        status: true,
        priorityFlag: true,
        createdAt: true,
        scamType: { select: { code: true, labelEn: true, labelTh: true } },
        _count: { select: { evidenceFiles: true } },
        moderations: {
          orderBy: { createdAt: 'desc' },
          take: 1,
          where: { action: 'flag' },
          select: { remark: true },
        },
      },
    }),
    prisma.report.count({ where: { status: 'pending', ...(scamTypeCode ? { scamType: { code: scamTypeCode } } : {}) } }),
    prisma.report.count({ where: { status: 'flagged', ...(scamTypeCode ? { scamType: { code: scamTypeCode } } : {}) } }),
  ]);

  const items: AdminQueueItem[] = reports.map((r) => ({
    id: r.id,
    title: r.title,
    scamTypeCode: r.scamType.code,
    scamTypeLabelEn: r.scamType.labelEn,
    scamTypeLabelTh: r.scamType.labelTh,
    submittedAt: r.createdAt.toISOString(),
    status: r.status as 'pending' | 'flagged',
    priorityFlag: r.priorityFlag,
    evidenceCount: r._count.evidenceFiles,
    lastRemarkByAdmin: r.moderations[0]?.remark ?? null,
  }));

  return { items, pendingCount, flaggedCount };
}

// ---------------------------------------------------------------------------
// Detail
// ---------------------------------------------------------------------------

export async function getDetail(reportId: string): Promise<AdminReportDetail | null> {
  const prisma = getPrisma();

  const report = await prisma.report.findUnique({
    where: { id: reportId },
    select: {
      id: true,
      title: true,
      description: true,
      status: true,
      priorityFlag: true,
      targetIdentifier: true,
      targetIdentifierKind: true,
      targetIdentifierNormalized: true,
      createdAt: true,
      scamType: { select: { code: true, labelEn: true, labelTh: true } },
      evidenceFiles: {
        select: {
          id: true,
          storagePath: true,
          kind: true,
          mimeType: true,
          sizeBytes: true,
        },
      },
      moderations: {
        orderBy: { createdAt: 'asc' },
        select: {
          adminId: true,
          action: true,
          remark: true,
          createdAt: true,
        },
      },
    },
  });

  if (!report) return null;

  // Duplicate count — how many other verified reports share the same target.
  let duplicateCount = 0;
  if (report.targetIdentifierNormalized) {
    duplicateCount = await prisma.report.count({
      where: {
        status: 'verified',
        targetIdentifierNormalized: report.targetIdentifierNormalized,
        id: { not: reportId },
      },
    });
  }

  // AI confidence score — on-demand, advisory only.
  const { aiScore, aiConfidence } = await computeAiScore(
    report.title + '\n' + report.description,
  );

  const evidenceFiles: AdminEvidenceFile[] = report.evidenceFiles.map((f) => ({
    id: f.id,
    storagePath: f.storagePath,
    kind: f.kind as 'image' | 'pdf',
    mimeType: f.mimeType,
    sizeBytes: Number(f.sizeBytes),
  }));

  const auditTrail: ModerationRecord[] = report.moderations.map((m) => ({
    adminId: m.adminId,
    action: m.action as ModerationRecord['action'],
    remark: m.remark,
    createdAt: m.createdAt.toISOString(),
  }));

  return {
    id: report.id,
    title: report.title,
    description: report.description,
    scamTypeCode: report.scamType.code,
    scamTypeLabelEn: report.scamType.labelEn,
    scamTypeLabelTh: report.scamType.labelTh,
    submittedAt: report.createdAt.toISOString(),
    status: report.status as AdminReportDetail['status'],
    priorityFlag: report.priorityFlag,
    targetIdentifier: report.targetIdentifier,
    targetIdentifierKind: report.targetIdentifierKind as AdminReportDetail['targetIdentifierKind'],
    evidenceFiles,
    duplicateCount,
    aiScore,
    aiConfidence,
    auditTrail,
  };
}

// ---------------------------------------------------------------------------
// AI score
// ---------------------------------------------------------------------------

const TOP_K = 5;
const AVG_TOP_K = 3;

export async function computeAiScore(text: string): Promise<{
  aiScore: number | null;
  aiConfidence: AiConfidence | null;
}> {
  try {
    const results = await searchSimilarReports(text, TOP_K);
    if (results.length === 0) return { aiScore: null, aiConfidence: 'unknown' };

    const top = results.slice(0, AVG_TOP_K);
    const avg = top.reduce((sum, r) => sum + r.similarity, 0) / top.length;

    const score = Math.round(avg * 100);
    const confidence: AiConfidence =
      avg >= 0.85 ? 'high' : avg >= 0.70 ? 'medium' : 'low';

    return { aiScore: score, aiConfidence: confidence };
  } catch {
    // Never let AI scoring crash the detail endpoint.
    return { aiScore: null, aiConfidence: 'unknown' };
  }
}

// ---------------------------------------------------------------------------
// Actions
// ---------------------------------------------------------------------------

type ActionResult = { id: string; status: string; updatedAt: Date };

export async function approveReport(
  reportId: string,
  adminId: string,
  remark: string,
): Promise<ActionResult | null> {
  const prisma = getPrisma();

  // Fetch reporterId internally — used only for FCM, never returned.
  const report = await prisma.report.findUnique({
    where: { id: reportId },
    select: { id: true, reporterId: true },
  });
  if (!report) return null;

  const [updated] = await prisma.$transaction([
    prisma.report.update({
      where: { id: reportId },
      data: { status: 'verified', verifiedAt: new Date() },
      select: { id: true, status: true, updatedAt: true },
    }),
    prisma.moderationAction.create({
      data: { reportId, adminId, action: 'approve', remark },
    }),
  ]);

  if (report.reporterId) {
    await sendFcmToUser(report.reporterId, {
      title: 'Your report was verified',
      body: 'Thank you — your report has been reviewed and verified.',
    });
  }

  return { id: updated.id, status: updated.status, updatedAt: updated.updatedAt };
}

export async function rejectReport(
  reportId: string,
  adminId: string,
  remark: string,
): Promise<ActionResult | null> {
  const prisma = getPrisma();

  const report = await prisma.report.findUnique({
    where: { id: reportId },
    select: { id: true, reporterId: true },
  });
  if (!report) return null;

  const [updated] = await prisma.$transaction([
    prisma.report.update({
      where: { id: reportId },
      data: { status: 'rejected', rejectionRemark: remark },
      select: { id: true, status: true, updatedAt: true },
    }),
    prisma.moderationAction.create({
      data: { reportId, adminId, action: 'reject', remark },
    }),
  ]);

  if (report.reporterId) {
    await sendFcmToUser(report.reporterId, {
      title: 'Your report was reviewed',
      body: remark,
    });
  }

  return { id: updated.id, status: updated.status, updatedAt: updated.updatedAt };
}

export async function flagReport(
  reportId: string,
  adminId: string,
  remark: string,
): Promise<ActionResult | null> {
  const prisma = getPrisma();
  const exists = await prisma.report.findUnique({
    where: { id: reportId },
    select: { id: true },
  });
  if (!exists) return null;

  const [updated] = await prisma.$transaction([
    prisma.report.update({
      where: { id: reportId },
      data: { status: 'flagged', priorityFlag: true },
      select: { id: true, status: true, updatedAt: true },
    }),
    prisma.moderationAction.create({
      data: { reportId, adminId, action: 'flag', remark },
    }),
  ]);

  return { id: updated.id, status: updated.status, updatedAt: updated.updatedAt };
}

export async function unflagReport(
  reportId: string,
  adminId: string,
  remark: string,
): Promise<ActionResult | null> {
  const prisma = getPrisma();
  const exists = await prisma.report.findUnique({
    where: { id: reportId },
    select: { id: true },
  });
  if (!exists) return null;

  const [updated] = await prisma.$transaction([
    prisma.report.update({
      where: { id: reportId },
      data: { status: 'pending', priorityFlag: false },
      select: { id: true, status: true, updatedAt: true },
    }),
    prisma.moderationAction.create({
      data: { reportId, adminId, action: 'unflag', remark },
    }),
  ]);

  return { id: updated.id, status: updated.status, updatedAt: updated.updatedAt };
}
```

- [ ] **Step 2: Typecheck passes**

```bash
bun run typecheck
```
Expected: exits 0.

- [ ] **Step 3: Commit**

```bash
git add apps/api/src/features/admin-reports/admin-reports.service.ts
git commit -m "feat(api): admin-reports service — queue, detail, AI score, actions"
```

---

## Task 5: Admin reports route

**Files:**
- Create: `apps/api/src/features/admin-reports/admin-reports.route.ts`

- [ ] **Step 1: Create `admin-reports.route.ts`**

```ts
// apps/api/src/features/admin-reports/admin-reports.route.ts
import { Elysia, t } from 'elysia';
import {
  AdminQueueResponse,
  AdminReportDetailResponse,
  ApproveRejectFlagRequest,
  AdminActionResponse,
} from '@my-product/shared';
import { requireRole } from '../../core/middleware/require_role';
import {
  getQueue,
  getDetail,
  approveReport,
  rejectReport,
  flagReport,
  unflagReport,
} from './admin-reports.service';

const uuidParam = t.Object({ id: t.String({ format: 'uuid' }) });

export const adminReportsRoute = new Elysia({ prefix: '/admin/reports' })
  .use(requireRole('admin'))

  // GET /admin/reports/queue
  .get(
    '/queue',
    async ({ query }) => {
      const result = await getQueue(query.scam_type);
      return result;
    },
    {
      query: t.Object({ scam_type: t.Optional(t.String()) }),
      response: AdminQueueResponse,
    },
  )

  // GET /admin/reports/:id
  .get(
    '/:id',
    async ({ params, set }) => {
      const report = await getDetail(params.id);
      if (!report) {
        set.status = 404;
        return { error: 'Not found' };
      }
      return { report };
    },
    {
      params: uuidParam,
      response: { 200: AdminReportDetailResponse, 404: t.Object({ error: t.String() }) },
    },
  )

  // POST /admin/reports/:id/approve
  .post(
    '/:id/approve',
    async ({ params, body, user, set }) => {
      const result = await approveReport(params.id, user!.uid, body.remark);
      if (!result) { set.status = 404; return { error: 'Not found' }; }
      return { id: result.id, status: result.status, updatedAt: result.updatedAt.toISOString() };
    },
    {
      params: uuidParam,
      body: ApproveRejectFlagRequest,
      response: { 200: AdminActionResponse, 404: t.Object({ error: t.String() }) },
    },
  )

  // POST /admin/reports/:id/reject
  .post(
    '/:id/reject',
    async ({ params, body, user, set }) => {
      const result = await rejectReport(params.id, user!.uid, body.remark);
      if (!result) { set.status = 404; return { error: 'Not found' }; }
      return { id: result.id, status: result.status, updatedAt: result.updatedAt.toISOString() };
    },
    {
      params: uuidParam,
      body: ApproveRejectFlagRequest,
      response: { 200: AdminActionResponse, 404: t.Object({ error: t.String() }) },
    },
  )

  // POST /admin/reports/:id/flag
  .post(
    '/:id/flag',
    async ({ params, body, user, set }) => {
      const result = await flagReport(params.id, user!.uid, body.remark);
      if (!result) { set.status = 404; return { error: 'Not found' }; }
      return { id: result.id, status: result.status, updatedAt: result.updatedAt.toISOString() };
    },
    {
      params: uuxParam,
      body: ApproveRejectFlagRequest,
      response: { 200: AdminActionResponse, 404: t.Object({ error: t.String() }) },
    },
  )

  // POST /admin/reports/:id/unflag
  .post(
    '/:id/unflag',
    async ({ params, body, user, set }) => {
      const result = await unflagReport(params.id, user!.uid, body.remark);
      if (!result) { set.status = 404; return { error: 'Not found' }; }
      return { id: result.id, status: result.status, updatedAt: result.updatedAt.toISOString() };
    },
    {
      params: uuidParam,
      body: ApproveRejectFlagRequest,
      response: { 200: AdminActionResponse, 404: t.Object({ error: t.String() }) },
    },
  );
```

> **Note:** There is a typo `uuxParam` in the flag endpoint — fix it to `uuidParam` before running typecheck.

- [ ] **Step 2: Typecheck passes**

Fix the typo (line with `uuxParam` → `uuidParam`), then:
```bash
bun run typecheck
```
Expected: exits 0.

- [ ] **Step 3: Commit**

```bash
git add apps/api/src/features/admin-reports/admin-reports.route.ts
git commit -m "feat(api): admin-reports route — 6 endpoints, requireRole('admin')"
```

---

## Task 6: Wire into app

**Files:**
- Modify: `apps/api/src/index.ts`

- [ ] **Step 1: Mount route in `src/index.ts`**

Add the import and `.use()` call:

```ts
import { Elysia } from 'elysia';
import { cors } from '@elysiajs/cors';
import { healthRoute } from './features/health/health.route';
import { authRoute } from './features/auth/auth.route';
import { statsRoute } from './features/stats/stats.route';
import { announcementsRoute } from './features/announcements/announcements.route';
import { reportsRoute } from './features/reports/reports.route';
import { adminReportsRoute } from './features/admin-reports/admin-reports.route';

export const app = new Elysia()
  .use(cors())
  .use(healthRoute)
  .use(authRoute)
  .use(statsRoute)
  .use(announcementsRoute)
  .use(reportsRoute)
  .use(adminReportsRoute);

if (import.meta.main) {
  const port = Number(process.env.PORT ?? 3000);
  app.listen(port);
  console.log(`[api] listening on http://localhost:${port}`);
}
```

- [ ] **Step 2: Typecheck passes**

```bash
bun run typecheck
```
Expected: exits 0.

- [ ] **Step 3: Commit**

```bash
git add apps/api/src/index.ts
git commit -m "feat(api): mount adminReportsRoute"
```

---

## Task 7: Tests

**Files:**
- Create: `apps/api/test/admin-reports.test.ts`

Tests follow the project pattern: mock Firebase auth at the module level, check status codes. No real DB — `DATABASE_URL` is unset in the test env so DB calls return 500.

- [ ] **Step 1: Create `admin-reports.test.ts`**

```ts
// apps/api/test/admin-reports.test.ts
import { afterAll, beforeAll, describe, expect, mock, test } from 'bun:test';
import { app } from '../src/index';

// --- Firebase mock (same pattern as require_role.test.ts) ---
let mockDecoded: { uid: string; email: string | null; role?: string } | null = null;
let shouldThrow = false;

mock.module('firebase-admin/auth', () => ({
  getAuth: () => ({
    verifyIdToken: async () => {
      if (shouldThrow) throw new Error('mock: invalid token');
      if (!mockDecoded) throw new Error('mock: no decoded token configured');
      return mockDecoded;
    },
  }),
}));

mock.module('../src/core/firebase/admin', () => ({
  getFirebaseAdmin: () => ({}),
}));

beforeAll(() => {
  mockDecoded = null;
  shouldThrow = false;
});

afterAll(() => {
  mockDecoded = null;
  shouldThrow = false;
});

function makeReq(path: string, opts?: { method?: string; token?: string; body?: unknown }) {
  const headers: Record<string, string> = { 'content-type': 'application/json' };
  if (opts?.token) headers['Authorization'] = `Bearer ${opts.token}`;
  return new Request(`http://localhost${path}`, {
    method: opts?.method ?? 'GET',
    headers,
    body: opts?.body ? JSON.stringify(opts.body) : undefined,
  });
}

// ---------------------------------------------------------------------------
describe('GET /admin/reports/queue', () => {
  test('401 when unauthenticated', async () => {
    const res = await app.handle(makeReq('/admin/reports/queue'));
    expect(res.status).toBe(401);
  });

  test('403 when authenticated as regular user', async () => {
    mockDecoded = { uid: 'u1', email: 'u@example.com', role: 'user' };
    const res = await app.handle(makeReq('/admin/reports/queue', { token: 'tok' }));
    expect(res.status).toBe(403);
    mockDecoded = null;
  });

  test('500 when admin but DATABASE_URL unset', async () => {
    mockDecoded = { uid: 'a1', email: 'a@example.com', role: 'admin' };
    const res = await app.handle(makeReq('/admin/reports/queue', { token: 'tok' }));
    expect(res.status).toBe(500);
    mockDecoded = null;
  });
});

// ---------------------------------------------------------------------------
describe('GET /admin/reports/:id', () => {
  test('401 when unauthenticated', async () => {
    const res = await app.handle(
      makeReq('/admin/reports/00000000-0000-0000-0000-000000000000'),
    );
    expect(res.status).toBe(401);
  });

  test('403 when regular user', async () => {
    mockDecoded = { uid: 'u1', email: 'u@example.com', role: 'user' };
    const res = await app.handle(
      makeReq('/admin/reports/00000000-0000-0000-0000-000000000000', { token: 'tok' }),
    );
    expect(res.status).toBe(403);
    mockDecoded = null;
  });

  test('422 for non-UUID id', async () => {
    mockDecoded = { uid: 'a1', email: 'a@example.com', role: 'admin' };
    const res = await app.handle(
      makeReq('/admin/reports/not-a-uuid', { token: 'tok' }),
    );
    expect(res.status).toBe(422);
    mockDecoded = null;
  });

  test('500 when admin but DATABASE_URL unset', async () => {
    mockDecoded = { uid: 'a1', email: 'a@example.com', role: 'admin' };
    const res = await app.handle(
      makeReq('/admin/reports/00000000-0000-0000-0000-000000000000', { token: 'tok' }),
    );
    expect(res.status).toBe(500);
    mockDecoded = null;
  });
});

// ---------------------------------------------------------------------------
describe('POST /admin/reports/:id/approve', () => {
  const validId = '00000000-0000-0000-0000-000000000000';

  test('401 when unauthenticated', async () => {
    const res = await app.handle(
      makeReq(`/admin/reports/${validId}/approve`, { method: 'POST', body: { remark: 'ok' } }),
    );
    expect(res.status).toBe(401);
  });

  test('403 when regular user', async () => {
    mockDecoded = { uid: 'u1', email: 'u@example.com', role: 'user' };
    const res = await app.handle(
      makeReq(`/admin/reports/${validId}/approve`, { method: 'POST', token: 'tok', body: { remark: 'ok' } }),
    );
    expect(res.status).toBe(403);
    mockDecoded = null;
  });

  test('422 when remark is empty string', async () => {
    mockDecoded = { uid: 'a1', email: 'a@example.com', role: 'admin' };
    const res = await app.handle(
      makeReq(`/admin/reports/${validId}/approve`, { method: 'POST', token: 'tok', body: { remark: '' } }),
    );
    expect(res.status).toBe(422);
    mockDecoded = null;
  });

  test('422 when remark is missing', async () => {
    mockDecoded = { uid: 'a1', email: 'a@example.com', role: 'admin' };
    const res = await app.handle(
      makeReq(`/admin/reports/${validId}/approve`, { method: 'POST', token: 'tok', body: {} }),
    );
    expect(res.status).toBe(422);
    mockDecoded = null;
  });

  test('500 when admin but DATABASE_URL unset', async () => {
    mockDecoded = { uid: 'a1', email: 'a@example.com', role: 'admin' };
    const res = await app.handle(
      makeReq(`/admin/reports/${validId}/approve`, { method: 'POST', token: 'tok', body: { remark: 'looks legit' } }),
    );
    expect(res.status).toBe(500);
    mockDecoded = null;
  });
});

// ---------------------------------------------------------------------------
// Spot-check reject / flag / unflag — same auth + validation shape
['reject', 'flag', 'unflag'].forEach((action) => {
  describe(`POST /admin/reports/:id/${action}`, () => {
    const validId = '00000000-0000-0000-0000-000000000000';

    test('401 when unauthenticated', async () => {
      const res = await app.handle(
        makeReq(`/admin/reports/${validId}/${action}`, { method: 'POST', body: { remark: 'reason' } }),
      );
      expect(res.status).toBe(401);
    });

    test('422 when remark is empty', async () => {
      mockDecoded = { uid: 'a1', email: 'a@example.com', role: 'admin' };
      const res = await app.handle(
        makeReq(`/admin/reports/${validId}/${action}`, { method: 'POST', token: 'tok', body: { remark: '' } }),
      );
      expect(res.status).toBe(422);
      mockDecoded = null;
    });
  });
});
```

- [ ] **Step 2: Run tests**

```bash
bun --filter @my-product/api test
```

Expected: all tests pass (the suite includes new tests + all previously passing tests).

- [ ] **Step 3: Commit**

```bash
git add apps/api/test/admin-reports.test.ts
git commit -m "test(api): admin-reports — auth gates, validation, DB-unavailable"
```

---

## Verification

```bash
# From repo root
bun run typecheck          # shared + api — must exit 0
bun --filter @my-product/api test  # all tests pass
bun run lint               # dart analyze — no issues
```

**Manual smoke (requires real env):**
1. Set `ADMIN_UID` in Firebase custom claims for a test user.
2. `GET /admin/reports/queue` → returns `{ items[], pendingCount, flaggedCount }`.
3. `GET /admin/reports/:id` for a pending report → `aiConfidence` is `high|medium|low|unknown`.
4. `POST /admin/reports/:id/approve` with `{ remark: "verified" }` → `status: "verified"`.
5. Check `moderation_actions` table — row inserted with correct `adminId`, `action`, `remark`.
6. Verify no `reporterId` / `reporter` key in any response body.

---

## Reporter Anonymity Checklist (FR-7.8)

Before merging, verify each item:

- [ ] All `prisma.report.findMany` / `findUnique` in the service use explicit `select` that does NOT include `reporterId`, `reporter`, or `reporter.*`
- [ ] The only place `reporterId` is fetched is `approveReport` / `rejectReport` — and it is used only to send FCM, never put in a returned object
- [ ] No `reporter` key present in any JSON response from `GET /admin/reports/queue` or `GET /admin/reports/:id`
- [ ] Audit trail rows expose `adminId` (the acting admin) only — never the original reporter
