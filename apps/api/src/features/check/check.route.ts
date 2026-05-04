import { Elysia } from 'elysia';
import { CheckRequest, CheckResponse, PhoneSyncResponse } from '@my-product/shared';
import { authMiddleware } from '../../core/middleware/auth.middleware';
import { getScamPhones, runCheck } from './check.service';

export const checkRoute = new Elysia()
  .use(authMiddleware)

  .post(
    '/check',
    async ({ body, user }) => {
      return runCheck(body.payload, body.type, user?.uid);
    },
    { body: CheckRequest, response: CheckResponse },
  )

  .get(
    '/check/phones',
    async () => {
      const phones = await getScamPhones();
      return { phones, updatedAt: new Date().toISOString() };
    },
    { response: PhoneSyncResponse },
  );
