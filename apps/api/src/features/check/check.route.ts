import { Elysia } from 'elysia';
import { CheckRequest, CheckResponse, PhoneSyncResponse } from '@my-product/shared';
import { getScamPhones, checkText, checkPhone, checkUrl } from './check.service';

export const checkRoute = new Elysia()
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
