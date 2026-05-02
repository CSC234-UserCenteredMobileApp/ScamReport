import { Elysia, t } from 'elysia';
import { AnnouncementListResponse, AnnouncementDetailResponse } from '@my-product/shared';
import { getPrisma } from '../../core/db/client';

export const announcementsRoute = new Elysia()
  .get(
    '/announcements',
    async ({ query }) => {
      const prisma = getPrisma();
      const limit = Math.min(query.limit ?? 10, 50);

      const rows = await prisma.announcement.findMany({
        where: { status: 'published' },
        orderBy: { publishedAt: 'desc' },
        take: limit,
        select: { id: true, title: true, body: true, category: true, publishedAt: true, createdAt: true },
      });

      return {
        items: rows.map((r) => ({
          id: r.id,
          title: r.title,
          excerpt: r.body.slice(0, 120).trimEnd() + (r.body.length > 120 ? '…' : ''),
          category: r.category,
          publishedAt: (r.publishedAt ?? r.createdAt).toISOString(),
        })),
      };
    },
    {
      query: t.Object({ limit: t.Optional(t.Integer({ minimum: 1, maximum: 50 })) }),
      response: AnnouncementListResponse,
    },
  )
  .get(
    '/announcements/:id',
    async ({ params, status }) => {
      const prisma = getPrisma();

      const row = await prisma.announcement.findFirst({
        where: { id: params.id, status: 'published' },
        select: { id: true, title: true, body: true, category: true, publishedAt: true, createdAt: true, slug: true },
      });

      if (!row) {
        return status(404, { message: 'Not found' });
      }

      return {
        item: {
          id: row.id,
          title: row.title,
          body: row.body,
          category: row.category,
          slug: row.slug,
          publishedAt: (row.publishedAt ?? row.createdAt).toISOString(),
        },
      };
    },
    {
      params: t.Object({ id: t.String() }),
      response: {
        200: AnnouncementDetailResponse,
        404: t.Object({ message: t.String() }),
      },
    },
  );
