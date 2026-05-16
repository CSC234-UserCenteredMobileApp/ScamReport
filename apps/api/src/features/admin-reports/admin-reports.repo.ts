// =============================================================================
// admin-reports.repo — Prisma data layer for the moderation feature
// =============================================================================
//
// Pure data access. No business rules, no formatting, no reporter masking.
// Only raw rows + relations are returned; the service layer composes them
// into payloads, applies anonymity rules, and triggers side effects.
//
// Architecture rules (docs/architecture.md, .claude/agents/architect.md):
//   - This file is the only place in the moderation feature that imports
//     `getPrisma`. The service must not call Prisma directly.

import { getPrisma } from '../../core/db/client';

export type ActionKind = 'approve' | 'reject' | 'flag' | 'unflag';

export interface QueueRow {
  id: string;
  title: string;
  status: string;
  priorityFlag: boolean;
  createdAt: Date;
  reporterId: string | null;
  aiScore: number | null;
  aiConfidence: string | null;
  scamType: { code: string; labelEn: string; labelTh: string };
  _count: { evidenceFiles: number };
  moderations: { remark: string }[];
}

export interface DetailRow {
  id: string;
  title: string;
  description: string;
  status: string;
  priorityFlag: boolean;
  targetIdentifier: string | null;
  targetIdentifierKind: string | null;
  targetIdentifierNormalized: string | null;
  reporterId: string | null;
  scammerId: string | null;
  aiScore: number | null;
  aiConfidence: string | null;
  createdAt: Date;
  updatedAt: Date;
  verifiedAt: Date | null;
  rejectionRemark: string | null;
  scamType: { code: string; labelEn: string; labelTh: string };
  scammer: {
    id: string;
    displayName: string;
    suspectedName: string | null;
    person: {
      id: string;
      fullName: string;
      riskLevel: string;
      campaignCountCache: number;
    } | null;
    aliases: string[];
    riskLevel: string;
    reportCountCache: number;
    reports: { scamType: { code: string } }[];
  } | null;
  evidenceFiles: {
    id: string;
    storagePath: string;
    kind: string;
    mimeType: string;
    sizeBytes: bigint;
  }[];
  moderations: {
    adminId: string | null;
    action: string;
    remark: string;
    createdAt: Date;
  }[];
}

export interface SiblingCaseRow {
  id: string;
  title: string;
  status: string;
  scamTypeCode: string;
  verifiedAt: Date | null;
}

export interface ActionResult {
  id: string;
  status: string;
  updatedAt: Date;
  reporterId: string | null;
  title: string;
  scamTypeCode: string;
  createdAt: Date;
  verifiedAt: Date | null;
  rejectionRemark: string | null;
}

export async function findQueueRows(scamTypeCode?: string): Promise<QueueRow[]> {
  const prisma = getPrisma();
  const scamTypeFilter = scamTypeCode ? { scamType: { code: scamTypeCode } } : {};
  return prisma.report.findMany({
    where: { status: { in: ['pending', 'flagged'] }, ...scamTypeFilter },
    orderBy: [{ priorityFlag: 'desc' }, { createdAt: 'asc' }],
    select: {
      id: true,
      title: true,
      status: true,
      priorityFlag: true,
      createdAt: true,
      reporterId: true,
      aiScore: true,
      aiConfidence: true,
      scamType: { select: { code: true, labelEn: true, labelTh: true } },
      _count: { select: { evidenceFiles: true } },
      moderations: {
        where: { action: 'flag' },
        orderBy: { createdAt: 'desc' },
        take: 1,
        select: { remark: true },
      },
    },
  }) as unknown as Promise<QueueRow[]>;
}

export async function countByStatus(
  status: 'pending' | 'flagged',
  scamTypeCode?: string,
): Promise<number> {
  const prisma = getPrisma();
  const scamTypeFilter = scamTypeCode ? { scamType: { code: scamTypeCode } } : {};
  return prisma.report.count({ where: { status, ...scamTypeFilter } });
}

export async function findDetailRow(reportId: string): Promise<DetailRow | null> {
  const prisma = getPrisma();
  return prisma.report.findUnique({
    where: { id: reportId },
    select: {
      id: true,
      title: true,
      description: true,
      status: true,
      priorityFlag: true,
      targetIdentifier: true,
      targetIdentifierKind: true,
      targetIdentifierNormalized: true,
      reporterId: true,
      scammerId: true,
      aiScore: true,
      aiConfidence: true,
      createdAt: true,
      updatedAt: true,
      verifiedAt: true,
      rejectionRemark: true,
      scamType: { select: { code: true, labelEn: true, labelTh: true } },
      scammer: {
        select: {
          id: true,
          displayName: true,
          suspectedName: true,
          person: {
            select: { id: true, fullName: true, riskLevel: true, campaignCountCache: true },
          },
          aliases: true,
          riskLevel: true,
          reportCountCache: true,
          // Top scam-type codes — derive from latest verified linked cases.
          reports: {
            where: { status: 'verified' },
            orderBy: { verifiedAt: 'desc' },
            take: 5,
            select: { scamType: { select: { code: true } } },
          },
        },
      },
      evidenceFiles: {
        select: { id: true, storagePath: true, kind: true, mimeType: true, sizeBytes: true },
      },
      moderations: {
        orderBy: { createdAt: 'asc' },
        select: { adminId: true, action: true, remark: true, createdAt: true },
      },
    },
  }) as unknown as Promise<DetailRow | null>;
}

/**
 * Sibling cases attributed to the same scammer profile, excluding the
 * requested report. Limited to 5 most-recent (verified first, then
 * pending/flagged) so the admin detail page renders quickly.
 */
export async function findSiblingCases(
  scammerId: string,
  excludeReportId: string,
  limit = 5,
): Promise<SiblingCaseRow[]> {
  const prisma = getPrisma();
  const rows = await prisma.report.findMany({
    where: {
      scammerId,
      id: { not: excludeReportId },
    },
    orderBy: [{ verifiedAt: 'desc' }, { createdAt: 'desc' }],
    take: limit,
    select: {
      id: true,
      title: true,
      status: true,
      verifiedAt: true,
      scamType: { select: { code: true } },
    },
  });
  return rows.map((r) => ({
    id: r.id,
    title: r.title,
    status: r.status,
    scamTypeCode: r.scamType.code,
    verifiedAt: r.verifiedAt,
  }));
}

export interface EvidenceFileRow {
  id: string;
  storagePath: string;
  kind: string;
  mimeType: string;
}

// Returns the evidence file iff it belongs to the given report. Cross-report
// lookups (admin guessing fileId from a different reportId) return null and
// the route layer maps that to 404 — a guard against URL-tampering.
export async function findEvidenceFile(
  reportId: string,
  fileId: string,
): Promise<EvidenceFileRow | null> {
  const prisma = getPrisma();
  return prisma.evidenceFile.findFirst({
    where: { id: fileId, reportId },
    select: { id: true, storagePath: true, kind: true, mimeType: true },
  });
}

export async function countDuplicates(
  normalizedIdentifier: string,
  excludeReportId: string,
): Promise<number> {
  const prisma = getPrisma();
  return prisma.report.count({
    where: {
      status: 'verified',
      targetIdentifierNormalized: normalizedIdentifier,
      id: { not: excludeReportId },
    },
  });
}

// Atomic state-transition + audit-log append. Returns the post-transition row
// shape the service needs to push to FCM and to the Firestore mirror.
export async function applyAction(
  reportId: string,
  adminId: string,
  kind: ActionKind,
  remark: string,
): Promise<ActionResult | null> {
  const prisma = getPrisma();
  const exists = await prisma.report.findUnique({
    where: { id: reportId },
    select: { id: true },
  });
  if (!exists) return null;

  const update = stateUpdateFor(kind, remark);
  const [updated] = await prisma.$transaction([
    prisma.report.update({
      where: { id: reportId },
      data: update,
      select: {
        id: true,
        status: true,
        updatedAt: true,
        reporterId: true,
        title: true,
        createdAt: true,
        verifiedAt: true,
        rejectionRemark: true,
        scamType: { select: { code: true } },
      },
    }),
    prisma.moderationAction.create({
      data: { reportId, adminId, action: kind, remark },
    }),
  ]);

  return {
    id: updated.id,
    status: updated.status,
    updatedAt: updated.updatedAt,
    reporterId: updated.reporterId,
    title: updated.title,
    scamTypeCode: updated.scamType.code,
    createdAt: updated.createdAt,
    verifiedAt: updated.verifiedAt,
    rejectionRemark: updated.rejectionRemark,
  };
}

function stateUpdateFor(kind: ActionKind, remark: string) {
  switch (kind) {
    case 'approve':
      return { status: 'verified' as const, verifiedAt: new Date() };
    case 'reject':
      return { status: 'rejected' as const, rejectionRemark: remark };
    case 'flag':
      return { status: 'flagged' as const, priorityFlag: true };
    case 'unflag':
      return { status: 'pending' as const, priorityFlag: false };
  }
}
