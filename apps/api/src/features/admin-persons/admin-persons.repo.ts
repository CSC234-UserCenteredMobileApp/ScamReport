// admin-persons.repo — Prisma data layer for Person dossiers. Only place in
// the feature that imports getPrisma.

import { getPrisma } from '../../core/db/client';

export interface PersonRow {
  id: string;
  fullName: string;
  aliases: string[];
  riskLevel: string;
  notes: string | null;
  reportCountCache: number;
  campaignCountCache: number;
  firstSeenAt: Date | null;
  lastSeenAt: Date | null;
  createdAt: Date;
  scammers: Array<{
    id: string;
    displayName: string;
    suspectedName: string | null;
    riskLevel: string;
    reportCountCache: number;
    firstSeenAt: Date | null;
    lastSeenAt: Date | null;
    reports: Array<{ scamType: { code: string }; verifiedAt: Date | null }>;
  }>;
}

export async function findPersonById(id: string): Promise<PersonRow | null> {
  const prisma = getPrisma();
  return prisma.person.findUnique({
    where: { id },
    select: {
      id: true,
      fullName: true,
      aliases: true,
      riskLevel: true,
      notes: true,
      reportCountCache: true,
      campaignCountCache: true,
      firstSeenAt: true,
      lastSeenAt: true,
      createdAt: true,
      scammers: {
        orderBy: { reportCountCache: 'desc' },
        select: {
          id: true,
          displayName: true,
          suspectedName: true,
          riskLevel: true,
          reportCountCache: true,
          firstSeenAt: true,
          lastSeenAt: true,
          reports: {
            where: { status: 'verified' },
            orderBy: { verifiedAt: 'desc' },
            take: 10,
            select: { scamType: { select: { code: true } }, verifiedAt: true },
          },
        },
      },
    },
  }) as unknown as Promise<PersonRow | null>;
}
