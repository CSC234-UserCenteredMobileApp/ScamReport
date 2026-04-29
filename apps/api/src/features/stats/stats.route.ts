import { Elysia } from 'elysia';
import { HomeStatsResponse } from '@my-product/shared';
import { getPrisma } from '../../core/db/client';

export const statsRoute = new Elysia().get(
  '/stats',
  async () => {
    const prisma = getPrisma();
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

    const [verifiedTotal, newThisWeek, topGroup] = await Promise.all([
      prisma.report.count({ where: { status: 'verified' } }),
      prisma.report.count({
        where: { status: 'verified', verifiedAt: { gte: sevenDaysAgo } },
      }),
      prisma.report.groupBy({
        by: ['scamTypeId'],
        where: { status: 'verified' },
        _count: { scamTypeId: true },
        orderBy: { _count: { scamTypeId: 'desc' } },
        take: 1,
      }),
    ]);

    let topScamType = 'Unknown';
    const [topEntry] = topGroup;
    if (topEntry !== undefined) {
      const scamType = await prisma.scamType.findUnique({
        where: { id: topEntry.scamTypeId },
      });
      topScamType = scamType?.labelEn ?? 'Unknown';
    }

    return { data: { verifiedTotal, newThisWeek, topScamType } };
  },
  { response: HomeStatsResponse },
);
