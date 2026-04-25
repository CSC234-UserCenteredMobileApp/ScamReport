import { Elysia } from 'elysia';
import { HealthResponse } from '@my-product/shared';

export const healthRoute = new Elysia().get(
  '/health',
  () => ({ ok: true }),
  { response: HealthResponse },
);
