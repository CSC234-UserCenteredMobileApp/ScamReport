import { Elysia, t } from 'elysia';
import { AnnouncementListResponse } from '@my-product/shared';
import { getPrisma } from '../../core/db/client';

export const announcementsRoute = new Elysia().get(
  '/announcements',
  async ({ query }) => {
    const prisma = getPrisma();
    const limit = Math.min(query.limit ?? 10, 50);

    const rows = await prisma.announcement.findMany({
      where: { status: 'published' },
      orderBy: { publishedAt: 'desc' },
      take: limit,
      select: { id: true, title: true, category: true, publishedAt: true },
    });

    return {
      items: rows.map((r) => ({
        id: r.id,
        title: r.title,
        category: r.category,
        publishedAt: r.publishedAt!.toISOString(),
      })),
    };
  },
  {
    query: t.Object({ limit: t.Optional(t.Integer({ minimum: 1, maximum: 50 })) }),
    response: AnnouncementListResponse,
  },
);
