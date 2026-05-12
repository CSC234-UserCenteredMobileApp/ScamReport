import { Elysia, t } from 'elysia';
import {
  AdminAnnouncementListResponse,
  AdminAnnouncementDetailResponse,
  CreateAnnouncementRequest,
  UpdateAnnouncementRequest,
  PublishAnnouncementRequest,
  AdminAnnouncementActionResponse,
  AdminAnnouncementAttachmentResponse,
} from '@my-product/shared';
import { requireRole } from '../../core/middleware/require_role';
import {
  listAll,
  getDetail,
  createAnnouncement,
  updateAnnouncement,
  deleteAnnouncement,
  publishAnnouncement,
  unpublishAnnouncement,
  uploadAttachment,
  deleteAttachment,
} from './admin-announcements.service';

const uuidParam = t.Object({ id: t.String({ format: 'uuid' }) });
const notFound = t.Object({ error: t.String() });
const conflict = t.Object({ error: t.String() });

export const adminAnnouncementsRoute = new Elysia({ prefix: '/admin/announcements' })
  .use(requireRole('admin'))

  // GET /admin/announcements
  .get(
    '/',
    async () => {
      const items = await listAll();
      return { items };
    },
    {
      response: AdminAnnouncementListResponse,
    },
  )

  // GET /admin/announcements/:id
  .get(
    '/:id',
    async ({ params, set }) => {
      const item = await getDetail(params.id);
      if (!item) {
        set.status = 404;
        return { error: 'Not found' };
      }
      return { item };
    },
    {
      params: uuidParam,
      response: { 200: AdminAnnouncementDetailResponse, 404: notFound },
    },
  )

  // POST /admin/announcements
  .post(
    '/',
    async ({ body, user }) => {
      const item = await createAnnouncement(user!.uid, user!.email, body);
      return { item };
    },
    {
      body: CreateAnnouncementRequest,
      response: AdminAnnouncementDetailResponse,
    },
  )

  // PUT /admin/announcements/:id
  .put(
    '/:id',
    async ({ params, body, set }) => {
      const result = await updateAnnouncement(params.id, body);
      if (result === null) {
        set.status = 404;
        return { error: 'Not found' };
      }
      if (result === 'locked') {
        set.status = 409;
        return { error: 'Cannot edit a published announcement' };
      }
      return { item: result };
    },
    {
      params: uuidParam,
      body: UpdateAnnouncementRequest,
      response: { 200: AdminAnnouncementDetailResponse, 404: notFound, 409: conflict },
    },
  )

  // DELETE /admin/announcements/:id
  .delete(
    '/:id',
    async ({ params, set }) => {
      const result = await deleteAnnouncement(params.id);
      if (result === null) {
        set.status = 404;
        return { error: 'Not found' };
      }
      if (result === 'locked') {
        set.status = 409;
        return { error: 'Cannot delete a published announcement' };
      }
      return {
        id: params.id,
        status: 'deleted',
        updatedAt: new Date().toISOString(),
      };
    },
    {
      params: uuidParam,
      response: { 200: AdminAnnouncementActionResponse, 404: notFound, 409: conflict },
    },
  )

  // POST /admin/announcements/:id/publish
  .post(
    '/:id/publish',
    async ({ params, body, set }) => {
      const item = await publishAnnouncement(params.id, body.pushToFcm);
      if (!item) {
        set.status = 404;
        return { error: 'Not found' };
      }
      return { item };
    },
    {
      params: uuidParam,
      body: PublishAnnouncementRequest,
      response: { 200: AdminAnnouncementDetailResponse, 404: notFound },
    },
  )

  // POST /admin/announcements/:id/unpublish
  .post(
    '/:id/unpublish',
    async ({ params, set }) => {
      const result = await unpublishAnnouncement(params.id);
      if (result === null) {
        set.status = 404;
        return { error: 'Not found' };
      }
      if (result === 'not_published') {
        set.status = 409;
        return { error: 'Announcement is not published' };
      }
      return {
        id: result.id,
        status: result.status,
        updatedAt: result.updatedAt,
      };
    },
    {
      params: uuidParam,
      response: { 200: AdminAnnouncementActionResponse, 404: notFound, 409: conflict },
    },
  )

  // POST /admin/announcements/:id/attachments
  .post(
    '/:id/attachments',
    async ({ params, body, set }) => {
      const result = await uploadAttachment(params.id, body.file as File);
      if (result === null) { set.status = 404; return { error: 'Not found' }; }
      if (result === 'invalid_mime') { set.status = 422; return { error: 'Unsupported file type' }; }
      if (result === 'too_large') { set.status = 422; return { error: 'File exceeds 10 MB limit' }; }
      if (result === 'limit_reached') { set.status = 422; return { error: 'Maximum 10 attachments per announcement' }; }
      return { attachment: result };
    },
    {
      params: uuidParam,
      body: t.Object({ file: t.File({ maxSize: 10 * 1024 * 1024 }) }),
      response: { 200: AdminAnnouncementAttachmentResponse, 404: notFound, 422: notFound },
      type: 'multipart/form-data',
    },
  )

  // DELETE /admin/announcements/:id/attachments/:attachmentId
  .delete(
    '/:id/attachments/:attachmentId',
    async ({ params, set }) => {
      const result = await deleteAttachment(params.id, params.attachmentId);
      if (result === null) { set.status = 404; return { error: 'Not found' }; }
      return { id: params.attachmentId, status: 'deleted', updatedAt: new Date().toISOString() };
    },
    {
      params: t.Object({ id: t.String({ format: 'uuid' }), attachmentId: t.String({ format: 'uuid' }) }),
      response: { 200: AdminAnnouncementActionResponse, 404: notFound },
    },
  );
