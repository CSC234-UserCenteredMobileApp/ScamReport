// Cursor-based generators for each export sheet. Caps memory at one batch +
// the materialised row regardless of dataset size.
//
// All Prisma `select` clauses here are the privacy enforcement point. Adding
// a new column requires also adding it to REPORTS_EXPORT_COLUMNS in privacy.ts
// — keep them in sync.

import type { Prisma, ReportStatus } from '../../generated/prisma/client';
import { getPrisma } from '../../core/db/client';
import { hashAdminId } from './privacy';
import type { ResolvedExportFilters } from './filters';

const BATCH = 1000;

export interface ReportRow {
  id: string;
  title: string;
  description: string;
  scamTypeCode: string;
  scamTypeLabelEn: string;
  scamTypeLabelTh: string;
  targetIdentifierKind: string | null;
  targetIdentifierNormalized: string | null;
  status: string;
  priorityFlag: boolean;
  rejectionRemark: string | null;
  aiScore: number | null;
  aiConfidence: string | null;
  suspectedNameAtSubmit: string | null;
  scammerId: string | null;
  createdAt: string;
  updatedAt: string;
  verifiedAt: string | null;
}

export function buildReportsWhere(filters: ResolvedExportFilters): Prisma.ReportWhereInput {
  const where: Prisma.ReportWhereInput = {};
  if (filters.status && filters.status.length > 0) {
    where.status = { in: filters.status as ReportStatus[] };
  }
  if (filters.scamType) {
    where.scamType = { code: filters.scamType };
  }
  if (filters.priorityOnly) {
    where.priorityFlag = true;
  }
  if (filters.confidence) {
    where.aiConfidence = filters.confidence;
  }
  if (filters.from || filters.to) {
    where.createdAt = {};
    if (filters.from) where.createdAt.gte = filters.from;
    if (filters.to) where.createdAt.lte = filters.to;
  }
  return where;
}

export async function* iterateReports(
  where: Prisma.ReportWhereInput,
  limit: number,
): AsyncGenerator<ReportRow> {
  const prisma = getPrisma();
  let cursor: string | undefined;
  let remaining = limit;

  while (remaining > 0) {
    const take = Math.min(BATCH, remaining);
    const batch = await prisma.report.findMany({
      where,
      take,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      orderBy: { id: 'asc' },
      select: {
        id: true,
        title: true,
        description: true,
        scamType: { select: { code: true, labelEn: true, labelTh: true } },
        targetIdentifierKind: true,
        targetIdentifierNormalized: true,
        status: true,
        priorityFlag: true,
        rejectionRemark: true,
        aiScore: true,
        aiConfidence: true,
        suspectedNameAtSubmit: true,
        scammerId: true,
        createdAt: true,
        updatedAt: true,
        verifiedAt: true,
      },
    });
    if (batch.length === 0) break;
    for (const r of batch) {
      yield {
        id: r.id,
        title: r.title,
        description: r.description,
        scamTypeCode: r.scamType.code,
        scamTypeLabelEn: r.scamType.labelEn,
        scamTypeLabelTh: r.scamType.labelTh,
        targetIdentifierKind: r.targetIdentifierKind ?? null,
        targetIdentifierNormalized: r.targetIdentifierNormalized ?? null,
        status: r.status,
        priorityFlag: r.priorityFlag,
        rejectionRemark: r.rejectionRemark ?? null,
        aiScore: r.aiScore ?? null,
        aiConfidence: r.aiConfidence ?? null,
        suspectedNameAtSubmit: r.suspectedNameAtSubmit ?? null,
        scammerId: r.scammerId ?? null,
        createdAt: r.createdAt.toISOString(),
        updatedAt: r.updatedAt.toISOString(),
        verifiedAt: r.verifiedAt ? r.verifiedAt.toISOString() : null,
      };
    }
    cursor = batch[batch.length - 1]!.id;
    remaining -= batch.length;
    if (batch.length < take) break;
  }
}

export interface ModerationActionRow {
  reportId: string;
  reportCreatedAt: string;
  adminIdHash: string;
  action: string;
  remark: string;
  createdAt: string;
  timeToActionSeconds: number;
}

// Streams moderation actions for the report set defined by `where`. Joins
// each action against its parent report for time-to-action computation and
// hashes the admin id at the boundary so raw UUIDs never enter the writer.
export async function* iterateModerationActions(
  where: Prisma.ReportWhereInput,
  limit: number,
): AsyncGenerator<ModerationActionRow> {
  const prisma = getPrisma();
  let cursor: string | undefined;
  let remaining = limit;

  while (remaining > 0) {
    const take = Math.min(BATCH, remaining);
    const batch = await prisma.moderationAction.findMany({
      where: { report: where },
      take,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      orderBy: { id: 'asc' },
      select: {
        id: true,
        reportId: true,
        adminId: true,
        action: true,
        remark: true,
        createdAt: true,
        report: { select: { createdAt: true } },
      },
    });
    if (batch.length === 0) break;
    for (const a of batch) {
      const reportCreatedAtMs = a.report.createdAt.getTime();
      const actionCreatedAtMs = a.createdAt.getTime();
      yield {
        reportId: a.reportId,
        reportCreatedAt: a.report.createdAt.toISOString(),
        adminIdHash: hashAdminId(a.adminId),
        action: a.action,
        remark: a.remark,
        createdAt: a.createdAt.toISOString(),
        timeToActionSeconds: Math.max(
          0,
          Math.floor((actionCreatedAtMs - reportCreatedAtMs) / 1000),
        ),
      };
    }
    cursor = batch[batch.length - 1]!.id;
    remaining -= batch.length;
    if (batch.length < take) break;
  }
}

export interface EvidenceSummaryRow {
  reportId: string;
  kind: string;
  fileCount: number;
  totalSizeBytes: number;
}

export async function iterateEvidenceSummary(
  where: Prisma.ReportWhereInput,
): Promise<EvidenceSummaryRow[]> {
  const prisma = getPrisma();
  // groupBy on evidence_files filtered to the report set; storage paths and
  // signed URLs are categorically omitted by virtue of not being selected.
  const rows = await prisma.evidenceFile.groupBy({
    by: ['reportId', 'kind'],
    where: { report: where },
    _count: { _all: true },
    _sum: { sizeBytes: true },
    orderBy: [{ reportId: 'asc' }, { kind: 'asc' }],
  });
  return rows.map((r) => ({
    reportId: r.reportId,
    kind: r.kind,
    fileCount: r._count._all,
    totalSizeBytes: Number(r._sum.sizeBytes ?? 0n),
  }));
}

export interface CheckLogDailyRow {
  day: string;
  verdict: string;
  calls: number;
  p95LatencyMs: number | null;
}

// Aggregates POST /check call volume into one row per (day × verdict). Inputs
// are already hashed at write time (DATABASE_DESIGN §4.10), so this sheet has
// no user-content PII. percentile_disc gives a tail-latency view per bucket.
export async function fetchCheckLogsDaily(
  from: Date | undefined,
  to: Date | undefined,
): Promise<CheckLogDailyRow[]> {
  const prisma = getPrisma();
  const fromIso = (from ?? new Date(0)).toISOString();
  const toIso = (to ?? new Date()).toISOString();

  const rows = await prisma.$queryRaw<
    Array<{ day: Date; verdict: string; calls: bigint; p95_latency_ms: number | null }>
  >`
    SELECT
      date_trunc('day', created_at) AS day,
      verdict::text                  AS verdict,
      COUNT(*)                       AS calls,
      percentile_disc(0.95) WITHIN GROUP (ORDER BY latency_ms) AS p95_latency_ms
    FROM check_logs
    WHERE created_at >= ${fromIso}::timestamptz
      AND created_at <= ${toIso}::timestamptz
    GROUP BY day, verdict
    ORDER BY day ASC, verdict ASC
  `;

  return rows.map((r) => ({
    day: r.day.toISOString().slice(0, 10),
    verdict: r.verdict,
    calls: Number(r.calls),
    p95LatencyMs: r.p95_latency_ms ?? null,
  }));
}

export interface ScamTypeRow {
  code: string;
  labelEn: string;
  labelTh: string;
}

export async function fetchScamTypes(): Promise<ScamTypeRow[]> {
  const prisma = getPrisma();
  const rows = await prisma.scamType.findMany({
    select: { code: true, labelEn: true, labelTh: true },
    orderBy: { code: 'asc' },
  });
  return rows;
}
