import { Elysia, t } from 'elysia';
import {
  AdminDeletionRequestListResponse,
  AdminDeletionActionResponse,
  AdminDeletionRejectRequest,
} from '@my-product/shared';
import { requireRole } from '../../core/middleware/require_role';
import { listRequests, approveRequest, rejectRequest } from './admin-deletion-requests.service';

const uuidParam = t.Object({ id: t.String({ format: 'uuid' }) });
const notFound = t.Object({ error: t.String() });
const conflict = t.Object({ error: t.String() });

export const adminDeletionRequestsRoute = new Elysia({ prefix: '/admin/deletion-requests' })
  .use(requireRole('admin'))

  // GET /admin/deletion-requests
  .get(
    '/',
    async ({ query }) => {
      return listRequests(query.status);
    },
    {
      query: t.Object({ status: t.Optional(t.String()) }),
      response: AdminDeletionRequestListResponse,
    },
  )

  // POST /admin/deletion-requests/:id/approve
  .post(
    '/:id/approve',
    async ({ params, user, set }) => {
      const result = await approveRequest(params.id, user!.uid);
      if (result === null) { set.status = 404; return { error: 'Not found' }; }
      if (result === 'already_reviewed') { set.status = 409; return { error: 'Already reviewed' }; }
      return result;
    },
    {
      params: uuidParam,
      response: { 200: AdminDeletionActionResponse, 404: notFound, 409: conflict },
    },
  )

  // POST /admin/deletion-requests/:id/reject
  .post(
    '/:id/reject',
    async ({ params, body, user, set }) => {
      const result = await rejectRequest(params.id, user!.uid, body.reason);
      if (result === null) { set.status = 404; return { error: 'Not found' }; }
      if (result === 'already_reviewed') { set.status = 409; return { error: 'Already reviewed' }; }
      return result;
    },
    {
      params: uuidParam,
      body: AdminDeletionRejectRequest,
      response: { 200: AdminDeletionActionResponse, 404: notFound, 409: conflict },
    },
  );
