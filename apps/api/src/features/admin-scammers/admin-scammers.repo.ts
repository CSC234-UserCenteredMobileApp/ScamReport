// =============================================================================
// admin-scammers.repo — Prisma data layer for scammer profiles + dossier.
// =============================================================================
// Architecture rules (docs/architecture.md):
//   - This file is the only place in the admin-scammers feature that imports
//     `getPrisma`. The service must not call Prisma directly.

import type { ScammerIdentifierKind } from '@my-product/shared';
import { getPrisma } from '../../core/db/client';

export interface ScammerRow {
  id: string;
  displayName: string;
  suspectedName: string | null;
  aliases: string[];
  riskLevel: string;
  notes: string | null;
  reportCountCache: number;
  firstSeenAt: Date | null;
  lastSeenAt: Date | null;
  createdAt: Date;
  identifiers: {
    id: string;
    kind: string;
    valueRaw: string;
    valueNormalized: string;
  }[];
}

export async function findById(id: string): Promise<ScammerRow | null> {
  const prisma = getPrisma();
  return prisma.scammer.findUnique({
    where: { id },
    select: {
      id: true,
      displayName: true,
      suspectedName: true,
      aliases: true,
      riskLevel: true,
      notes: true,
      reportCountCache: true,
      firstSeenAt: true,
      lastSeenAt: true,
      createdAt: true,
      identifiers: {
        orderBy: { createdAt: 'asc' },
        select: {
          id: true,
          kind: true,
          valueRaw: true,
          valueNormalized: true,
        },
      },
    },
  }) as unknown as Promise<ScammerRow | null>;
}

export async function listLinkedReports(scammerId: string) {
  const prisma = getPrisma();
  const reports = await prisma.report.findMany({
    where: { scammerId },
    orderBy: [{ verifiedAt: 'desc' }, { createdAt: 'desc' }],
    include: {
      scamType: true,
      evidenceFiles: {
        select: { id: true, storagePath: true, kind: true, mimeType: true },
      },
    },
  });
  return reports;
}

export async function listRecentCheckHits(
  normalizedValues: string[],
  sinceDays = 30,
  limit = 30,
) {
  if (normalizedValues.length === 0) return [];
  const prisma = getPrisma();
  const since = new Date(Date.now() - sinceDays * 24 * 60 * 60 * 1000);
  return prisma.checkLog.findMany({
    where: {
      inputNormalized: { in: normalizedValues },
      createdAt: { gte: since },
    },
    orderBy: { createdAt: 'desc' },
    take: limit,
    select: {
      inputNormalized: true,
      inputKind: true,
      verdict: true,
      matchCount: true,
      createdAt: true,
    },
  });
}

export interface ScammerCandidate {
  id: string;
  displayName: string;
  suspectedName: string | null;
  aliases: string[];
  riskLevel: string;
  reportCountCache: number;
  matchKind: 'identifier' | 'displayName';
}

// Search by identifier (exact normalised) or fuzzy by display name / alias.
export async function searchCandidates(opts: {
  identifier?: string;
  q?: string;
  limit?: number;
}): Promise<ScammerCandidate[]> {
  const limit = opts.limit ?? 20;
  const prisma = getPrisma();
  const results = new Map<string, ScammerCandidate>();

  if (opts.identifier) {
    const idRows = await prisma.scammerIdentifier.findMany({
      where: { valueNormalized: opts.identifier },
      include: {
        scammer: {
          select: {
            id: true,
            displayName: true,
            suspectedName: true,
            aliases: true,
            riskLevel: true,
            reportCountCache: true,
          },
        },
      },
    });
    for (const r of idRows) {
      if (!results.has(r.scammer.id)) {
        results.set(r.scammer.id, {
          id: r.scammer.id,
          displayName: r.scammer.displayName,
          suspectedName: r.scammer.suspectedName,
          aliases: r.scammer.aliases,
          riskLevel: r.scammer.riskLevel,
          reportCountCache: r.scammer.reportCountCache,
          matchKind: 'identifier',
        });
      }
    }
  }

  if (opts.q && opts.q.trim().length > 0 && results.size < limit) {
    const q = opts.q.trim();
    const rows = await prisma.scammer.findMany({
      where: {
        OR: [
          { displayName: { contains: q, mode: 'insensitive' } },
          { suspectedName: { contains: q, mode: 'insensitive' } },
          { aliases: { has: q } },
        ],
      },
      orderBy: { reportCountCache: 'desc' },
      take: limit,
      select: {
        id: true,
        displayName: true,
        suspectedName: true,
        aliases: true,
        riskLevel: true,
        reportCountCache: true,
      },
    });
    for (const r of rows) {
      if (!results.has(r.id)) {
        results.set(r.id, {
          id: r.id,
          displayName: r.displayName,
          suspectedName: r.suspectedName,
          aliases: r.aliases,
          riskLevel: r.riskLevel,
          reportCountCache: r.reportCountCache,
          matchKind: 'displayName',
        });
      }
    }
  }

  return Array.from(results.values()).slice(0, limit);
}

export async function recomputeReportCount(scammerId: string): Promise<void> {
  const prisma = getPrisma();
  const count = await prisma.report.count({ where: { scammerId } });
  await prisma.scammer.update({
    where: { id: scammerId },
    data: { reportCountCache: count },
  });
}

export interface CreateScammerInput {
  displayName: string;
  aliases: string[];
  riskLevel?: 'low' | 'medium' | 'high' | 'unknown';
  notes?: string;
  identifiers?: Array<{ kind: ScammerIdentifierKind; valueRaw: string; valueNormalized: string }>;
}

export async function createScammer(input: CreateScammerInput): Promise<string> {
  const prisma = getPrisma();
  const row = await prisma.scammer.create({
    data: {
      displayName: input.displayName,
      aliases: input.aliases,
      riskLevel: input.riskLevel ?? 'unknown',
      notes: input.notes ?? null,
    },
    select: { id: true },
  });
  if (input.identifiers && input.identifiers.length > 0) {
    for (const id of input.identifiers) {
      await prisma.scammerIdentifier.upsert({
        where: {
          kind_valueNormalized: {
            kind: id.kind,
            valueNormalized: id.valueNormalized,
          },
        },
        update: { scammerId: row.id, valueRaw: id.valueRaw },
        create: {
          scammerId: row.id,
          kind: id.kind,
          valueRaw: id.valueRaw,
          valueNormalized: id.valueNormalized,
        },
      });
    }
  }
  return row.id;
}

export async function linkReportToScammer(
  reportId: string,
  scammerId: string,
): Promise<boolean> {
  const prisma = getPrisma();
  const existing = await prisma.report.findUnique({
    where: { id: reportId },
    select: { id: true, scammerId: true },
  });
  if (!existing) return false;
  await prisma.report.update({
    where: { id: reportId },
    data: { scammerId },
  });
  await recomputeReportCount(scammerId);
  if (existing.scammerId && existing.scammerId !== scammerId) {
    await recomputeReportCount(existing.scammerId);
  }
  return true;
}
