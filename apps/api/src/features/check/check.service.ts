import { getPrisma } from '../../core/db/client';

export async function getScamPhones(): Promise<string[]> {
  const prisma = getPrisma();
  const rows = await prisma.report.findMany({
    where: {
      status: 'verified',
      targetIdentifierKind: 'phone',
      targetIdentifierNormalized: { not: null },
    },
    select: { targetIdentifierNormalized: true },
  });

  const phones = [
    ...new Set(rows.map((r) => r.targetIdentifierNormalized as string)),
  ];
  return phones;
}
