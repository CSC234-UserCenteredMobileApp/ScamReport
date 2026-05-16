import { Elysia, t } from 'elysia';
import {
  AdminQueueResponse,
  AdminReportDetailResponse,
  AdminEvidenceUrlResponse,
  ApproveRejectFlagRequest,
  AdminActionResponse,
} from '@my-product/shared';
import { resolveInternalUserId } from '../../core/lib/resolve-user';
import { requireRole } from '../../core/middleware/require_role';
import {
  getQueue,
  getDetail,
  getEvidenceSignedUrl,
  approveReport,
  rejectReport,
  flagReport,
  unflagReport,
} from './admin-reports.service';
import { renderPdf, shortId } from '../../core/pdf/pdf-generator';
import { reportTemplate } from '../../core/pdf/templates/report';

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
    async ({ query }) => getQueue(query.scam_type),
    {
      query: t.Object({ scam_type: t.Optional(t.String()) }),
      response: AdminQueueResponse,
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
      const bytes = await renderPdf(reportTemplate(report));
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
