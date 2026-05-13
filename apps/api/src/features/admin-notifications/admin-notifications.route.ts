import { Elysia } from 'elysia';
import { SubscriberCountResponse } from '@my-product/shared';
import { requireRole } from '../../core/middleware/require_role';
import { countSubscribers } from './admin-notifications.service';

export const adminNotificationsRoute = new Elysia({ prefix: '/admin/notifications' })
  .use(requireRole('admin'))

  .get(
    '/subscribers/count',
    async () => ({ count: await countSubscribers() }),
    { response: SubscriberCountResponse },
  );
