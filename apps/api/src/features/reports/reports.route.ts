import { Elysia, t } from 'elysia';
import {
  CreateReportRequest,
  CreateReportResponse,
  EvidenceUploadResponse,
  ReportDetailResponse,
  ReportListResponse,
} from '@my-product/shared';
import { getPrisma } from '../../core/db/client';
import { resolveInternalUserId } from '../../core/lib/resolve-user';
import { getSignedUrl } from '../../core/supabase/storage';
import { requireAuth } from '../../core/middleware/auth.middleware';
import {
  createReport,
  ReportSubmitError,
  uploadEvidence,
} from './reports.service';

export const reportsRoute = new Elysia().get(
  '/reports',
  async ({ query }) => {
    const prisma = getPrisma();
    const limit = Math.min(query.limit ?? 10, 50);

    const rows = await prisma.report.findMany({
      where: { status: 'verified' },
      orderBy: { verifiedAt: 'desc' },
      take: limit,
      include: { scamType: true },
    });

    const items = await Promise.all(
      rows.map(async (r) => {
        let reportCount = 1;
        if (r.targetIdentifierNormalized) {
          reportCount = await prisma.report.count({
            where: {
              status: 'verified',
              targetIdentifierNormalized: r.targetIdentifierNormalized,
            },
          });
        }
        return {
          id: r.id,
          title: r.title,
          excerpt: r.description.slice(0, 150),
          scamTypeCode: r.scamType.code,
          scamTypeLabelEn: r.scamType.labelEn,
          scamTypeLabelTh: r.scamType.labelTh,
          verifiedAt: (r.verifiedAt ?? r.createdAt).toISOString(),
          reportCount,
        };
      }),
    );

    return { items };
  },
  {
    query: t.Object({ limit: t.Optional(t.Integer({ minimum: 1, maximum: 50 })) }),
    response: ReportListResponse,
  },
)
.get(
  '/reports/:id',
  async ({ params: { id }, set }) => {
    const prisma = getPrisma();

    const report = await prisma.report.findFirst({
      where: { id, status: 'verified' },
      include: { scamType: true, evidenceFiles: true },
    });

    if (!report) { set.status = 404; return { error: 'Not found' }; }

    const reportCount = report.targetIdentifierNormalized
      ? await prisma.report.count({
          where: {
            status: 'verified',
            targetIdentifierNormalized: report.targetIdentifierNormalized,
          },
        })
      : 1;

    const evidenceFiles = await Promise.all(
      report.evidenceFiles.map(async (f) => {
        let signedUrl: string | null = null;
        try {
          signedUrl = await getSignedUrl('evidence', f.storagePath, 3600);
        } catch {
          // storage hiccup — degrade gracefully, page still usable
        }
        return {
          id: f.id,
          signedUrl,
          kind: f.kind as 'image' | 'pdf',
          mimeType: f.mimeType,
        };
      }),
    );

    return {
      id: report.id,
      title: report.title,
      description: report.description,
      scamTypeCode: report.scamType.code,
      scamTypeLabelEn: report.scamType.labelEn,
      scamTypeLabelTh: report.scamType.labelTh,
      verifiedAt: (report.verifiedAt ?? report.createdAt).toISOString(),
      reportCount,
      targetIdentifier: report.targetIdentifier ?? null,
      targetIdentifierKind: (report.targetIdentifierKind as 'phone' | 'url' | 'other' | null) ?? null,
      evidenceFiles,
    };
  },
  {
    params: t.Object({ id: t.String() }),
    response: {
      200: ReportDetailResponse,
      404: t.Object({ error: t.String() }),
    },
  },
)
// POST /reports/evidence — upload a single evidence file. Returns metadata
// the client passes back inside CreateReportRequest.evidenceFiles.
//
// Body validation lives in the handler (uploadEvidence) rather than the
// route schema: Elysia 1.x's t.File requires the optional `file-type`
// package for runtime MIME sniffing, and we want clear 415/413 codes
// regardless. The Authorization gate runs before body parsing because
// auth is `requireAuth`'s onBeforeHandle hook.
.use(requireAuth)
.post(
  '/reports/evidence',
  async ({ body, user, set }) => {
    const file = (body as { file?: File }).file;
    if (!file || typeof (file as File).arrayBuffer !== 'function') {
      set.status = 400;
      return { error: 'Missing file', code: 'missing_file' };
    }
    try {
      const bytes = new Uint8Array(await file.arrayBuffer());
      const uid = await resolveInternalUserId(user!.uid, user!.email);
      const meta = await uploadEvidence(uid, {
        name: file.name,
        type: file.type,
        bytes,
      });
      return meta;
    } catch (err) {
      if (err instanceof ReportSubmitError) {
        set.status = err.status;
        return { error: err.message, code: err.code };
      }
      throw err;
    }
  },
  {
    body: t.Object({
      file: t.Any(),
    }),
    response: {
      200: EvidenceUploadResponse,
      400: t.Object({ error: t.String(), code: t.String() }),
      413: t.Object({ error: t.String(), code: t.String() }),
      415: t.Object({ error: t.String(), code: t.String() }),
    },
  },
)
// POST /reports — create a new pending report. Authoritative submit path
// for both the manual /submit-report screen and Ask AI's drafted submission.
.post(
  '/reports',
  async ({ body, user, set }) => {
    try {
      const uid = await resolveInternalUserId(user!.uid, user!.email);
      return await createReport(uid, body);
    } catch (err) {
      if (err instanceof ReportSubmitError) {
        set.status = err.status;
        return { error: err.message, code: err.code };
      }
      throw err;
    }
  },
  {
    body: CreateReportRequest,
    response: {
      200: CreateReportResponse,
      400: t.Object({ error: t.String(), code: t.String() }),
    },
  },
);
