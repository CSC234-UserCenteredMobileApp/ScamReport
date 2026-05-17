import { Elysia, t } from 'elysia';
import {
  AdminQueueResponse,
  AdminReportDetailResponse,
  AdminReportSearchResponse,
  AdminEvidenceUrlResponse,
  ApproveRejectFlagRequest,
  AdminActionResponse,
} from '@my-product/shared';
import { resolveInternalUserId } from '../../core/lib/resolve-user';
import { requireRole } from '../../core/middleware/require_role';
import {
  getQueue,
  getDetail,
  searchReports,
  getEvidenceSignedUrl,
  approveReport,
  rejectReport,
  flagReport,
  unflagReport,
} from './admin-reports.service';
import { renderPdf, shortId } from '../../core/pdf/pdf-generator';
import { reportTemplate, type EvidenceImageMap } from '../../core/pdf/templates/report';
import { downloadFile } from '../../core/supabase/storage';

const EVIDENCE_BUCKET = 'evidence';
const MAX_EMBEDDED_IMAGES = 5;
const MAX_EMBEDDED_BYTES = 4 * 1024 * 1024; // 4 MB cap per file
const SAFE_IMAGE_MIME = new Set(['image/jpeg', 'image/jpg', 'image/png']);

const uuidParam = t.Object({ id: t.String({ format: 'uuid' }) });
const evidenceParams = t.Object({
  id: t.String({ format: 'uuid' }),
  fileId: t.String({ format: 'uuid' }),
});
const notFound = t.Object({ error: t.String() });

export const adminReportsRoute = new Elysia({ prefix: '/admin/reports' })
  .use(requireRole('admin'))

  .get(
    '/queue',
    async ({ query }) =>
      getQueue({
        q: query.q,
        status: query.status,
        priority:
          query.priority === 'true'
            ? true
            : query.priority === 'false'
              ? false
              : undefined,
        confidence: query.confidence,
        scamType: query.scam_type,
        page: query.page ? Math.max(1, parseInt(query.page, 10)) : 1,
        pageSize: query.page_size ? parseInt(query.page_size, 10) : 25,
      }),
    {
      query: t.Object({
        q: t.Optional(t.String({ maxLength: 200 })),
        status: t.Optional(
          t.Union([t.Literal('pending'), t.Literal('flagged'), t.Literal('all')]),
        ),
        priority: t.Optional(t.Union([t.Literal('true'), t.Literal('false')])),
        confidence: t.Optional(
          t.Union([
            t.Literal('high'),
            t.Literal('medium'),
            t.Literal('low'),
            t.Literal('all'),
          ]),
        ),
        scam_type: t.Optional(t.String()),
        page: t.Optional(t.String({ pattern: '^[0-9]+$' })),
        page_size: t.Optional(
          t.Union([t.Literal('25'), t.Literal('50'), t.Literal('100')]),
        ),
      }),
      response: AdminQueueResponse,
    },
  )

  .get(
    '/search',
    async ({ query }) => searchReports(query.q, query.limit ? Number(query.limit) : undefined),
    {
      query: t.Object({
        q: t.String({ minLength: 1 }),
        limit: t.Optional(t.String()),
      }),
      response: AdminReportSearchResponse,
    },
  )

  .get(
    '/:id',
    async ({ params, set }) => {
      const report = await getDetail(params.id);
      if (!report) { set.status = 404; return { error: 'Not found' }; }
      return { report };
    },
    {
      params: uuidParam,
      response: { 200: AdminReportDetailResponse, 404: notFound },
    },
  )

  .get(
    '/:id/pdf',
    async ({ params, set }) => {
      const report = await getDetail(params.id);
      if (!report) {
        set.status = 404;
        return { error: 'Not found' };
      }

      // Download evidence images so the PDF embeds the actual screenshots
      // instead of just a filename. PDFs / other kinds stay as table rows.
      // Bounded to MAX_EMBEDDED_IMAGES so a report with many huge photos
      // can't produce a 50 MB document.
      const images: EvidenceImageMap = {};
      const candidates = report.evidenceFiles
        .filter((f) => f.kind === 'image' && SAFE_IMAGE_MIME.has(f.mimeType))
        .slice(0, MAX_EMBEDDED_IMAGES);
      await Promise.all(
        candidates.map(async (f) => {
          try {
            const bytes = await downloadFile(EVIDENCE_BUCKET, f.storagePath);
            if (bytes.length > MAX_EMBEDDED_BYTES) return;
            const b64 = Buffer.from(bytes).toString('base64');
            images[f.id] = `data:${f.mimeType};base64,${b64}`;
          } catch (err) {
            console.warn('[pdf] could not embed evidence', f.id, err);
          }
        }),
      );

      const bytes = await renderPdf(reportTemplate(report, images));
      return new Response(bytes as BodyInit, {
        status: 200,
        headers: {
          'Content-Type': 'application/pdf',
          'Content-Disposition': `attachment; filename="scamreport-report-${shortId(report.id)}.pdf"`,
          'Cache-Control': 'no-store',
        },
      });
    },
    { params: uuidParam },
  )

  .get(
    '/:id/evidence/:fileId/url',
    async ({ params, set }) => {
      const signed = await getEvidenceSignedUrl(params.id, params.fileId);
      if (!signed) { set.status = 404; return { error: 'Not found' }; }
      return signed;
    },
    {
      params: evidenceParams,
      response: { 200: AdminEvidenceUrlResponse, 404: notFound },
    },
  )

  .post(
    '/:id/approve',
    async ({ params, body, user, set }) => {
      const adminInternalId = await resolveInternalUserId(user!.uid, user!.email);
      const result = await approveReport(params.id, adminInternalId, body.remark);
      if (!result) {
        warnMissing('approve', params.id);
        set.status = 404;
        return { error: 'Not found' };
      }
      return { id: result.id, status: result.status, updatedAt: result.updatedAt.toISOString() };
    },
    {
      params: uuidParam,
      body: ApproveRejectFlagRequest,
      response: { 200: AdminActionResponse, 404: notFound },
    },
  )

  .post(
    '/:id/reject',
    async ({ params, body, user, set }) => {
      const adminInternalId = await resolveInternalUserId(user!.uid, user!.email);
      const result = await rejectReport(params.id, adminInternalId, body.remark);
      if (!result) {
        warnMissing('reject', params.id);
        set.status = 404;
        return { error: 'Not found' };
      }
      return { id: result.id, status: result.status, updatedAt: result.updatedAt.toISOString() };
    },
    {
      params: uuidParam,
      body: ApproveRejectFlagRequest,
      response: { 200: AdminActionResponse, 404: notFound },
    },
  )

  .post(
    '/:id/flag',
    async ({ params, body, user, set }) => {
      const adminInternalId = await resolveInternalUserId(user!.uid, user!.email);
      const result = await flagReport(params.id, adminInternalId, body.remark);
      if (!result) {
        warnMissing('flag', params.id);
        set.status = 404;
        return { error: 'Not found' };
      }
      return { id: result.id, status: result.status, updatedAt: result.updatedAt.toISOString() };
    },
    {
      params: uuidParam,
      body: ApproveRejectFlagRequest,
      response: { 200: AdminActionResponse, 404: notFound },
    },
  )

  .post(
    '/:id/unflag',
    async ({ params, body, user, set }) => {
      const adminInternalId = await resolveInternalUserId(user!.uid, user!.email);
      const result = await unflagReport(params.id, adminInternalId, body.remark);
      if (!result) {
        warnMissing('unflag', params.id);
        set.status = 404;
        return { error: 'Not found' };
      }
      return { id: result.id, status: result.status, updatedAt: result.updatedAt.toISOString() };
    },
    {
      params: uuidParam,
      body: ApproveRejectFlagRequest,
      response: { 200: AdminActionResponse, 404: notFound },
    },
  );

// Surfaced when a service action returns null — either the report id is
// unknown or it was deleted between detail load and action. Logging it
// once per occurrence makes the 404 path debuggable from server logs.
function warnMissing(action: string, id: string): void {
  console.warn(`[admin-reports] action '${action}' on ${id} → report not found or already actioned`);
}
