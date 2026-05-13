import { Elysia, t } from 'elysia';
import {
  MarkNotificationReadRequest,
  MarkNotificationReadResponse,
  NotificationListResponse,
  RegisterFcmTokenRequest,
  RegisterFcmTokenResponse,
} from '@my-product/shared';
import { requireAuth } from '../../core/middleware/auth.middleware';
import { resolveInternalUserId } from '../../core/lib/resolve-user';
import {
  listInbox,
  markRead,
  registerDevice,
  unregisterDevice,
} from './notifications.service';

export const notificationsRoute = new Elysia({ prefix: '/me' })
  .use(requireAuth)

  .post(
    '/fcm-tokens',
    async ({ body, user }) => {
      const userId = await resolveInternalUserId(user!.uid, user!.email);
      await registerDevice(userId, body.fcmToken, body.platform, body.appVersion);
      return { registered: true };
    },
    {
      body: RegisterFcmTokenRequest,
      response: RegisterFcmTokenResponse,
    },
  )

  .delete(
    '/fcm-tokens/:token',
    async ({ params, user, set }) => {
      const userId = await resolveInternalUserId(user!.uid, user!.email);
      const removed = await unregisterDevice(userId, params.token);
      if (removed === 0) {
        set.status = 404;
        return { error: 'Token not found' };
      }
      return { registered: false };
    },
    {
      params: t.Object({ token: t.String({ minLength: 1 }) }),
      response: {
        200: RegisterFcmTokenResponse,
        404: t.Object({ error: t.String() }),
      },
    },
  )

  .get(
    '/notifications',
    async ({ user }) => {
      const userId = await resolveInternalUserId(user!.uid, user!.email);
      return listInbox(userId);
    },
    { response: NotificationListResponse },
  )

  .post(
    '/notifications/read',
    async ({ body, user }) => {
      const userId = await resolveInternalUserId(user!.uid, user!.email);
      return markRead(userId, body.ids);
    },
    {
      body: MarkNotificationReadRequest,
      response: MarkNotificationReadResponse,
    },
  );
