import { Elysia } from 'elysia';
import { AnnouncementListResponse, AnnouncementListQuery } from '@my-product/shared';
import { getPrisma } from '../../core/db/client';

export const announcementsRoute = new Elysia().get(
  '/announcements',
  async ({ query }) => {
    const prisma = getPrisma();
    const limit = Math.min(query.limit ?? 10, 50);

    const rows = await prisma.announcement.findMany({
      where: {
        status: 'published',
        ...(query.province ? { province: query.province } : {}),
      },
      orderBy: { publishedAt: 'desc' },
      take: limit,
      select: { id: true, title: true, category: true, province: true, publishedAt: true, createdAt: true },
    });

    return {
      items: rows.map((r) => ({
        id: r.id,
        title: r.title,
        category: r.category,
        publishedAt: (r.publishedAt ?? r.createdAt).toISOString(),
        ...(r.province ? { province: r.province } : {}),
      })),
    };
  },
  {
    query: AnnouncementListQuery,
    response: AnnouncementListResponse,
  },
);
