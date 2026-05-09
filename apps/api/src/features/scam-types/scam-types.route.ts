import { Elysia } from 'elysia';
import { ScamTypeListResponse } from '@my-product/shared';
import { getPrisma } from '../../core/db/client';

export const scamTypesRoute = new Elysia().get(
  '/scam-types',
  async () => {
    const prisma = getPrisma();
    const rows = await prisma.scamType.findMany({
      where: { isActive: true },
      orderBy: { displayOrder: 'asc' },
    });
    return {
      items: rows.map((r) => ({
        code: r.code,
        labelEn: r.labelEn,
        labelTh: r.labelTh,
        displayOrder: r.displayOrder,
      })),
    };
  },
  { response: ScamTypeListResponse },
);
