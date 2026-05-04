import { Elysia } from 'elysia';
import { CheckRequest, CheckResponse, PhoneSyncResponse } from '@my-product/shared';
import { getScamPhones, checkText, checkPhone, checkUrl } from './check.service';

export const checkRoute = new Elysia()
import { authMiddleware } from '../../core/middleware/auth.middleware';
import { getScamPhones, runCheck } from './check.service';

export const checkRoute = new Elysia()
  .use(authMiddleware)

  // POST /check — Quick Verdict (FR-2.1). Guests allowed (FR-2.4).
  .post(
    '/check',
    async ({ body, user }) => {
      return runCheck(body.payload, body.type, user?.uid);
    },
    {
      body: CheckRequest,
      response: CheckResponse,
    },
  )

  // GET /check/phones — offline call-screening cache (FR-9.x)
  .get(
    '/check/phones',
    async () => {
      const phones = await getScamPhones();
      return { phones, updatedAt: new Date().toISOString() };
    },
    { response: PhoneSyncResponse },
  )
  .post(
    '/check',
    async ({ body }) => {
      if (body.type === 'text') return checkText(body.payload);
      if (body.type === 'phone') return checkPhone(body.payload);
      return checkUrl(body.payload);
    },
    { body: CheckRequest, response: CheckResponse },
  );
