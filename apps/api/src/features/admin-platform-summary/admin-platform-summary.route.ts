import { Elysia, t } from 'elysia';
import { PlatformSummaryResponse } from '@my-product/shared';
import { requireRole } from '../../core/middleware/require_role';
import { getPlatformSummary } from './admin-platform-summary.service';
import { renderPdf } from '../../core/pdf/pdf-generator';
import { platformTemplate } from '../../core/pdf/templates/platform';

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
  )
  .get(
    '/admin/reports/platform-summary/pdf',
    async ({ query }) => {
      const summary = await getPlatformSummary(query.from, query.to);
      const bytes = await renderPdf(platformTemplate(summary));
      return new Response(bytes as BodyInit, {
        status: 200,
        headers: {
          'Content-Type': 'application/pdf',
          'Content-Disposition': `attachment; filename="scamreport-platform-summary.pdf"`,
          'Cache-Control': 'no-store',
        },
      });
    },
    {
      query: t.Object({
        from: t.Optional(t.String({ format: 'date-time' })),
        to: t.Optional(t.String({ format: 'date-time' })),
      }),
    },
  );
