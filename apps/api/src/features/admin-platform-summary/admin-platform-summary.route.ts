import { Elysia, t } from 'elysia';
import { PlatformSummaryResponse } from '@my-product/shared';
import { requireRole } from '../../core/middleware/require_role';
import { getPlatformSummary } from './admin-platform-summary.service';

export const adminPlatformSummaryRoute = new Elysia()
  .use(requireRole('admin'))
  .get(
    '/admin/reports/platform-summary',
    async ({ query }) => getPlatformSummary(query.from, query.to),
    {
      query: t.Object({
        from: t.Optional(t.String({ format: 'date-time' })),
        to: t.Optional(t.String({ format: 'date-time' })),
      }),
      response: PlatformSummaryResponse,
    },
  );
