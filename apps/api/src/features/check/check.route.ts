import { Elysia } from 'elysia';
import { PhoneSyncResponse } from '@my-product/shared';
import { getScamPhones } from './check.service';

export const checkRoute = new Elysia().get(
  '/check/phones',
  async () => {
    const phones = await getScamPhones();
    return { phones, updatedAt: new Date().toISOString() };
  },
  { response: PhoneSyncResponse },
);
