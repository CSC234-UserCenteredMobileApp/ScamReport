// =============================================================================
// admin-reports.service — moderation orchestration
// =============================================================================
//
// Composes the repo layer (Prisma) with cross-cutting concerns: AI similarity
// scoring (RAG), FCM push to the reporter on terminal actions, and (in the
// follow-up commit) the My Reports Firestore mirror.
//
// PRD reporter-anonymity rules (FR-7.4 + FR-7.8 + §3.6):
//   - No reporter identity field appears in any returned payload. The shared
//     schemas (`AdminQueueItem`, `AdminReportDetail`) enforce this at the type
//     level; this file enforces it at the data level.
//   - `reporterId` is read internally only — to deliver FCM (and, in the
//     follow-up, to write to `my-reports/{uid}/items/{reportId}` in Firestore).
//     It is never copied into a return value.

import type {
  AdminEvidenceFile,
  AdminQueueItem,
  AdminReportDetail,
  AiConfidence,
  ModerationRecord,
} from '@my-product/shared';
import { searchSimilarReports } from '../../core/rag/retrieval';
import { sendFcmToUser } from '../../core/firebase/messaging';
import { mirrorMyReport } from '../../sync/firestore_sync';
import {
  applyAction as repoApplyAction,
  countByStatus,
  countDuplicates,
  findDetailRow,
  findQueueRows,
  type ActionKind,
  type ActionResult,
} from './admin-reports.repo';

// ---------------------------------------------------------------------------
// Queue
// ---------------------------------------------------------------------------

export async function getQueue(scamTypeCode?: string): Promise<{
  items: AdminQueueItem[];
  pendingCount: number;
  flaggedCount: number;
}> {
  const [rows, pendingCount, flaggedCount] = await Promise.all([
    findQueueRows(scamTypeCode),
    countByStatus('pending', scamTypeCode),
    countByStatus('flagged', scamTypeCode),
  ]);

  const items: AdminQueueItem[] = rows.map((r) => ({
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
  }));

  return { items, pendingCount, flaggedCount };
}

// ---------------------------------------------------------------------------
// Detail
// ---------------------------------------------------------------------------

export async function getDetail(reportId: string): Promise<AdminReportDetail | null> {
  const report = await findDetailRow(reportId);
  if (!report) return null;

  const duplicateCount = report.targetIdentifierNormalized
    ? await countDuplicates(report.targetIdentifierNormalized, reportId)
    : 0;

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
  };
}

// ---------------------------------------------------------------------------
// AI score (unchanged from the previous implementation)
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
// Actions — reporter identity used internally for FCM only, never returned
// ---------------------------------------------------------------------------

export interface PublicActionResult {
  id: string;
  status: string;
  updatedAt: Date;
}

export async function approveReport(
  reportId: string,
  adminId: string,
  remark: string,
): Promise<PublicActionResult | null> {
  const result = await repoApplyAction(reportId, adminId, 'approve', remark);
  if (!result) return null;
  await pushToReporter(result, {
    title: 'Your report was verified',
    body: 'Thank you — your report has been reviewed and verified.',
  });
  await mirrorReporterView(result);
  return strip(result);
}

export async function rejectReport(
  reportId: string,
  adminId: string,
  remark: string,
): Promise<PublicActionResult | null> {
  const result = await repoApplyAction(reportId, adminId, 'reject', remark);
  if (!result) return null;
  await pushToReporter(result, {
    title: 'Your report was reviewed',
    body: remark,
  });
  await mirrorReporterView(result);
  return strip(result);
}

export async function flagReport(
  reportId: string,
  adminId: string,
  remark: string,
): Promise<PublicActionResult | null> {
  const result = await repoApplyAction(reportId, adminId, 'flag', remark);
  if (!result) return null;
  await mirrorReporterView(result);
  return strip(result);
}

export async function unflagReport(
  reportId: string,
  adminId: string,
  remark: string,
): Promise<PublicActionResult | null> {
  const result = await repoApplyAction(reportId, adminId, 'unflag', remark);
  if (!result) return null;
  await mirrorReporterView(result);
  return strip(result);
}

// ---------------------------------------------------------------------------
// Internals
// ---------------------------------------------------------------------------

async function pushToReporter(
  result: ActionResult,
  notification: { title: string; body: string },
): Promise<void> {
  if (!result.reporterId) return;
  await sendFcmToUser(result.reporterId, notification);
}

// Push the post-action row to the My Reports Firestore mirror so the
// reporter's listener sees the new state without polling. The reporter-
// facing `flagged → pending` mapping (FR-6.1) is applied inside
// `firestore_sync.toReporterStatus` — pass the real DB status through.
// Mirror failure is logged + swallowed by `mirrorMyReport`; the admin's
// 200 response still ships even if Firestore is unreachable.
async function mirrorReporterView(result: ActionResult): Promise<void> {
  if (!result.reporterId) return;
  await mirrorMyReport({
    id: result.id,
    reporterId: result.reporterId,
    title: result.title,
    status: result.status as
      | 'pending'
      | 'verified'
      | 'rejected'
      | 'flagged'
      | 'withdrawn',
    scamTypeCode: result.scamTypeCode,
    createdAt: result.createdAt,
    updatedAt: result.updatedAt,
    verifiedAt: result.verifiedAt,
    rejectionRemark: result.rejectionRemark,
  });
}

function strip(result: ActionResult): PublicActionResult {
  return {
    id: result.id,
    status: result.status,
    updatedAt: result.updatedAt,
  };
}

// Re-export for the route file's type annotations.
export type { ActionKind };
