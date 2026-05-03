import { getPrisma } from '../../core/db/client';
import { searchSimilarReports } from '../../core/rag/retrieval';
import { sendFcmToUser } from '../../core/firebase/messaging';
import type {
  AdminQueueItem,
  AdminReportDetail,
  AdminEvidenceFile,
  ModerationRecord,
  AiConfidence,
} from '@my-product/shared';

// ---------------------------------------------------------------------------
// Queue
// ---------------------------------------------------------------------------

export async function getQueue(scamTypeCode?: string): Promise<{
  items: AdminQueueItem[];
  pendingCount: number;
  flaggedCount: number;
}> {
  const prisma = getPrisma();
  const scamTypeFilter = scamTypeCode ? { scamType: { code: scamTypeCode } } : {};

  const [reports, pendingCount, flaggedCount] = await Promise.all([
    prisma.report.findMany({
      where: { status: { in: ['pending', 'flagged'] }, ...scamTypeFilter },
      orderBy: [{ priorityFlag: 'desc' }, { createdAt: 'asc' }],
      select: {
        id: true,
        title: true,
        status: true,
        priorityFlag: true,
        createdAt: true,
        reporterId: true,
        scamType: { select: { code: true, labelEn: true, labelTh: true } },
        _count: { select: { evidenceFiles: true } },
        moderations: {
          where: { action: 'flag' },
          orderBy: { createdAt: 'desc' },
          take: 1,
          select: { remark: true },
        },
      },
    }),
    prisma.report.count({ where: { status: 'pending', ...scamTypeFilter } }),
    prisma.report.count({ where: { status: 'flagged', ...scamTypeFilter } }),
  ]);

  const items: AdminQueueItem[] = reports.map((r) => ({
    id: r.id,
    title: r.title,
    scamTypeCode: r.scamType.code,
    scamTypeLabelEn: r.scamType.labelEn,
    scamTypeLabelTh: r.scamType.labelTh,
    submittedAt: r.createdAt.toISOString(),
    status: r.status as 'pending' | 'flagged',
    priorityFlag: r.priorityFlag,
    evidenceCount: r._count.evidenceFiles,
    lastRemarkByAdmin: r.moderations[0]?.remark ?? null,
    reporterHandle: `User_${(r.reporterId ?? 'anon').substring(0, 4)}`,
  }));

  return { items, pendingCount, flaggedCount };
}

// ---------------------------------------------------------------------------
// Detail
// ---------------------------------------------------------------------------

export async function getDetail(reportId: string): Promise<AdminReportDetail | null> {
  const prisma = getPrisma();

  const report = await prisma.report.findUnique({
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
      createdAt: true,
      scamType: { select: { code: true, labelEn: true, labelTh: true } },
      evidenceFiles: {
        select: { id: true, storagePath: true, kind: true, mimeType: true, sizeBytes: true },
      },
      moderations: {
        orderBy: { createdAt: 'asc' },
        select: { adminId: true, action: true, remark: true, createdAt: true },
      },
    },
  });

  if (!report) return null;

  let duplicateCount = 0;
  if (report.targetIdentifierNormalized) {
    duplicateCount = await prisma.report.count({
      where: {
        status: 'verified',
        targetIdentifierNormalized: report.targetIdentifierNormalized,
        id: { not: reportId },
      },
    });
  }

  const { aiScore, aiConfidence } = await computeAiScore(
    `${report.title}\n${report.description}`,
  );

  const evidenceFiles: AdminEvidenceFile[] = report.evidenceFiles.map((f) => ({
    id: f.id,
    storagePath: f.storagePath,
    kind: f.kind as 'image' | 'pdf',
    mimeType: f.mimeType,
    sizeBytes: Number(f.sizeBytes),
  }));

  const auditTrail: ModerationRecord[] = report.moderations.map((m) => ({
    adminId: m.adminId,
    action: m.action as ModerationRecord['action'],
    remark: m.remark,
    createdAt: m.createdAt.toISOString(),
  }));

  return {
    id: report.id,
    title: report.title,
    description: report.description,
    scamTypeCode: report.scamType.code,
    scamTypeLabelEn: report.scamType.labelEn,
    scamTypeLabelTh: report.scamType.labelTh,
    submittedAt: report.createdAt.toISOString(),
    status: report.status as AdminReportDetail['status'],
    priorityFlag: report.priorityFlag,
    targetIdentifier: report.targetIdentifier,
    targetIdentifierKind: report.targetIdentifierKind as AdminReportDetail['targetIdentifierKind'],
    evidenceFiles,
    duplicateCount,
    aiScore,
    aiConfidence,
    auditTrail,
    reporterHandle: `User_${(report.reporterId ?? 'anon').substring(0, 4)}`,
  };
}

// ---------------------------------------------------------------------------
// AI score
// ---------------------------------------------------------------------------

const TOP_K = 5;
const AVG_TOP_K = 3;

export async function computeAiScore(text: string): Promise<{
  aiScore: number | null;
  aiConfidence: AiConfidence | null;
}> {
  try {
    const results = await searchSimilarReports(text, TOP_K);
    if (results.length === 0) return { aiScore: null, aiConfidence: 'unknown' };

    const top = results.slice(0, AVG_TOP_K);
    const avg = top.reduce((sum, r) => sum + r.similarity, 0) / top.length;
    const score = Math.round(avg * 100);
    const confidence: AiConfidence = avg >= 0.85 ? 'high' : avg >= 0.70 ? 'medium' : 'low';

    return { aiScore: score, aiConfidence: confidence };
  } catch {
    return { aiScore: null, aiConfidence: 'unknown' };
  }
}

// ---------------------------------------------------------------------------
// Actions — reporter identity never returned; fetched internally for FCM only
// ---------------------------------------------------------------------------

type ActionResult = { id: string; status: string; updatedAt: Date };

export async function approveReport(
  reportId: string,
  adminId: string,
  remark: string,
): Promise<ActionResult | null> {
  const prisma = getPrisma();
  const report = await prisma.report.findUnique({
    where: { id: reportId },
    select: { id: true, reporterId: true },
  });
  if (!report) return null;

  const [updated] = await prisma.$transaction([
    prisma.report.update({
      where: { id: reportId },
      data: { status: 'verified', verifiedAt: new Date() },
      select: { id: true, status: true, updatedAt: true },
    }),
    prisma.moderationAction.create({
      data: { reportId, adminId, action: 'approve', remark },
    }),
  ]);

  if (report.reporterId) {
    await sendFcmToUser(report.reporterId, {
      title: 'Your report was verified',
      body: 'Thank you — your report has been reviewed and verified.',
    });
  }

  return { id: updated.id, status: updated.status, updatedAt: updated.updatedAt };
}

export async function rejectReport(
  reportId: string,
  adminId: string,
  remark: string,
): Promise<ActionResult | null> {
  const prisma = getPrisma();
  const report = await prisma.report.findUnique({
    where: { id: reportId },
    select: { id: true, reporterId: true },
  });
  if (!report) return null;

  const [updated] = await prisma.$transaction([
    prisma.report.update({
      where: { id: reportId },
      data: { status: 'rejected', rejectionRemark: remark },
      select: { id: true, status: true, updatedAt: true },
    }),
    prisma.moderationAction.create({
      data: { reportId, adminId, action: 'reject', remark },
    }),
  ]);

  if (report.reporterId) {
    await sendFcmToUser(report.reporterId, {
      title: 'Your report was reviewed',
      body: remark,
    });
  }

  return { id: updated.id, status: updated.status, updatedAt: updated.updatedAt };
}

export async function flagReport(
  reportId: string,
  adminId: string,
  remark: string,
): Promise<ActionResult | null> {
  const prisma = getPrisma();
  const exists = await prisma.report.findUnique({
    where: { id: reportId },
    select: { id: true },
  });
  if (!exists) return null;

  const [updated] = await prisma.$transaction([
    prisma.report.update({
      where: { id: reportId },
      data: { status: 'flagged', priorityFlag: true },
      select: { id: true, status: true, updatedAt: true },
    }),
    prisma.moderationAction.create({
      data: { reportId, adminId, action: 'flag', remark },
    }),
  ]);

  return { id: updated.id, status: updated.status, updatedAt: updated.updatedAt };
}

export async function unflagReport(
  reportId: string,
  adminId: string,
  remark: string,
): Promise<ActionResult | null> {
  const prisma = getPrisma();
  const exists = await prisma.report.findUnique({
    where: { id: reportId },
    select: { id: true },
  });
  if (!exists) return null;

  const [updated] = await prisma.$transaction([
    prisma.report.update({
      where: { id: reportId },
      data: { status: 'pending', priorityFlag: false },
      select: { id: true, status: true, updatedAt: true },
    }),
    prisma.moderationAction.create({
      data: { reportId, adminId, action: 'unflag', remark },
    }),
  ]);

  return { id: updated.id, status: updated.status, updatedAt: updated.updatedAt };
}
