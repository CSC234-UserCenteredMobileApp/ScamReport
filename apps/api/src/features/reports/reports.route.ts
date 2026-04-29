import { Elysia, t } from 'elysia';
import { ReportListResponse } from '@my-product/shared';
import { getPrisma } from '../../core/db/client';

export const reportsRoute = new Elysia().get(
  '/reports',
  async ({ query }) => {
    const prisma = getPrisma();
    const limit = Math.min(query.limit ?? 10, 50);

    const rows = await prisma.report.findMany({
      where: { status: 'verified' },
      orderBy: { verifiedAt: 'desc' },
      take: limit,
      include: { scamType: true },
    });

    const items = await Promise.all(
      rows.map(async (r) => {
        let reportCount = 1;
        if (r.targetIdentifierNormalized) {
          reportCount = await prisma.report.count({
            where: {
              status: 'verified',
              targetIdentifierNormalized: r.targetIdentifierNormalized,
            },
          });
        }
        return {
          id: r.id,
          title: r.title,
          excerpt: r.description.slice(0, 150),
          scamTypeCode: r.scamType.code,
          scamTypeLabelEn: r.scamType.labelEn,
          scamTypeLabelTh: r.scamType.labelTh,
          verifiedAt: r.verifiedAt!.toISOString(),
          reportCount,
        };
      }),
    );

    return { items };
  },
  {
    query: t.Object({ limit: t.Optional(t.Integer({ minimum: 1, maximum: 50 })) }),
    response: ReportListResponse,
  },
);
