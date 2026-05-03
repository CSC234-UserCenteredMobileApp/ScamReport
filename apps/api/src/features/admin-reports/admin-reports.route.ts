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
      response: { 200: AdminActionResponse, 404: notFound },
    },
  )

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
      response: { 200: AdminActionResponse, 404: notFound },
    },
  )

  .post(
    '/:id/flag',
    async ({ params, body, user, set }) => {
      const result = await flagReport(params.id, user!.uid, body.remark);
      if (!result) { set.status = 404; return { error: 'Not found' }; }
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
      const result = await unflagReport(params.id, user!.uid, body.remark);
      if (!result) { set.status = 404; return { error: 'Not found' }; }
      return { id: result.id, status: result.status, updatedAt: result.updatedAt.toISOString() };
    },
    {
      params: uuidParam,
      body: ApproveRejectFlagRequest,
      response: { 200: AdminActionResponse, 404: notFound },
    },
  );
