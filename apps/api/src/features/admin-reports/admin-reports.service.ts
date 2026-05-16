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
  AdminSiblingCase,
  ModerationRecord,
  AiConfidence,
  ScammerProfileSummary,
} from '@my-product/shared';
import { canonicalEmbedInput, computeAiScore } from '../../core/ai-score';
import { getPrisma } from '../../core/db/client';
import { sendFcmToUser } from '../../core/firebase/messaging';
import { getSignedUrl } from '../../core/supabase/storage';
import { mirrorMyReport } from '../../sync/firestore_sync';
import { notifyReporter } from '../notifications/notifications.service';
import {
  applyAction as repoApplyAction,
  countByStatus,
  countDuplicates,
  findDetailRow,
  findEvidenceFile,
  findQueueRows,
  findSiblingCases,
  type ActionKind,
  type ActionResult,
} from './admin-reports.repo';

const EVIDENCE_BUCKET = 'evidence';
const EVIDENCE_URL_TTL_SECONDS = 3600;

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
    aiScore: r.aiScore,
    aiConfidence: (r.aiConfidence ?? null) as AdminQueueItem['aiConfidence'],
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

  // Lazy backfill: legacy reports submitted before the AI score column
  // existed (and reports whose submit-time scoring was rate-limited or
  // had no verified corpus to compare against) stay NULL forever. Compute
  // on-demand the first time an admin opens the report so subsequent
  // opens are free. Best-effort — any failure leaves the column NULL and
  // the response shows the "AI score pending" state.
  let aiScore = report.aiScore;
  let aiConfidence = (report.aiConfidence ?? null) as AiConfidence | null;
  if (aiScore === null && aiConfidence === null) {
    const backfilled = await backfillAiScore(report);
    aiScore = backfilled.aiScore;
    aiConfidence = backfilled.aiConfidence;
  }

  // Sign each evidence path so the admin review screen can render previews
  // directly. Storage hiccups degrade gracefully — the gallery falls back to
  // a typed-file placeholder when signedUrl is null.
  const evidenceFiles: AdminEvidenceFile[] = await Promise.all(
    report.evidenceFiles.map(async (f) => {
      let signedUrl: string | null = null;
      try {
        signedUrl = await getSignedUrl('evidence', f.storagePath, 3600);
      } catch (err) {
        console.error('[admin-reports] sign evidence failed', {
          reportId: report.id,
          fileId: f.id,
          err,
        });
      }
      return {
        id: f.id,
        storagePath: f.storagePath,
        signedUrl,
        kind: f.kind as 'image' | 'pdf',
        mimeType: f.mimeType,
        sizeBytes: Number(f.sizeBytes),
      };
    }),
  );

  const auditTrail: ModerationRecord[] = report.moderations.map((m) => ({
    adminId: m.adminId,
    action: m.action as ModerationRecord['action'],
    remark: m.remark,
    createdAt: m.createdAt.toISOString(),
  }));

  // Scammer profile + sibling cases (other reports attributed to the same
  // offender). Empty when the report hasn't been linked yet — a moderator
  // can attach via POST /admin/reports/:id/link-scammer.
  let scammer: ScammerProfileSummary | null = null;
  let siblingCases: AdminSiblingCase[] = [];
  if (report.scammer) {
    const top: string[] = [];
    for (const r of report.scammer.reports) {
      if (!top.includes(r.scamType.code)) top.push(r.scamType.code);
    }
    scammer = {
      id: report.scammer.id,
      displayName: report.scammer.displayName,
      suspectedName: report.scammer.suspectedName,
      person: report.scammer.person
        ? {
            id: report.scammer.person.id,
            fullName: report.scammer.person.fullName,
            riskLevel: report.scammer.person.riskLevel as ScammerProfileSummary['riskLevel'],
            campaignCount: report.scammer.person.campaignCountCache,
          }
        : null,
      aliases: report.scammer.aliases,
      riskLevel: report.scammer.riskLevel as ScammerProfileSummary['riskLevel'],
      reportCount: report.scammer.reportCountCache,
      topScamTypeCodes: top,
    };
    const siblings = await findSiblingCases(report.scammer.id, reportId);
    siblingCases = siblings.map((s) => ({
      id: s.id,
      title: s.title,
      status: s.status,
      scamTypeCode: s.scamTypeCode,
      verifiedAt: s.verifiedAt ? s.verifiedAt.toISOString() : null,
    }));
  }

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
    aiConfidence: aiConfidence as AdminReportDetail['aiConfidence'],
    suspectedNameAtSubmit: report.suspectedNameAtSubmit ?? null,
    auditTrail,
    scammer,
    siblingCases,
  };
}

interface DetailRowForBackfill {
  id: string;
  title: string;
  description: string;
  targetIdentifier: string | null;
  scamType: { labelEn: string; labelTh: string };
}

/**
 * Compute a score for a report whose `ai_score` / `ai_confidence` columns
 * are NULL and persist the result so subsequent opens are O(1) DB reads.
 * Errors are swallowed (and logged inside `computeAiScore`) so the detail
 * endpoint never fails because of an AI subsystem issue.
 */
async function backfillAiScore(
  report: DetailRowForBackfill,
): Promise<{ aiScore: number | null; aiConfidence: AiConfidence | null }> {
  try {
    const result = await computeAiScore(
      canonicalEmbedInput({
        title: report.title,
        description: report.description,
        targetIdentifier: report.targetIdentifier,
        scamType: report.scamType,
      }),
      { reportId: report.id },
    );
    if (result.aiScore !== null || result.aiConfidence !== null) {
      await getPrisma().report.update({
        where: { id: report.id },
        data: { aiScore: result.aiScore, aiConfidence: result.aiConfidence },
      });
    }
    return result;
  } catch (err) {
    console.error('[admin-reports] ai-score-backfill failed', {
      reportId: report.id,
      err,
    });
    return { aiScore: null, aiConfidence: null };
  }
}

// ---------------------------------------------------------------------------
// Evidence signed URL
// ---------------------------------------------------------------------------

export interface EvidenceSignedUrl {
  url: string;
  expiresAt: string;
}

export async function getEvidenceSignedUrl(
  reportId: string,
  fileId: string,
): Promise<EvidenceSignedUrl | null> {
  const file = await findEvidenceFile(reportId, fileId);
  if (!file) return null;
  const url = await getSignedUrl(EVIDENCE_BUCKET, file.storagePath, EVIDENCE_URL_TTL_SECONDS);
  const expiresAt = new Date(Date.now() + EVIDENCE_URL_TTL_SECONDS * 1000).toISOString();
  return { url, expiresAt };
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
  await notifyOwner(result, 'report_verified', {
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
  await notifyOwner(result, 'report_rejected', {
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

// Writes a persistent Notification row for the reporter + dispatches an FCM
// push carrying a deeplink in `data` for the mobile foreground listener.
// FCM is best-effort inside `notifyReporter` — failure does not roll back the
// inbox row, which is the source of truth for the user's notification history.
async function notifyOwner(
  result: ActionResult,
  kind: 'report_verified' | 'report_rejected' | 'report_flagged',
  notification: { title: string; body: string },
): Promise<void> {
  if (!result.reporterId) return;
  try {
    await notifyReporter(
      result.reporterId,
      kind,
      notification.title,
      notification.body,
      result.id,
    );
  } catch (err) {
    // Inbox write or FCM send failed. Already logged downstream; swallow so
    // the moderation HTTP 200 still ships.
    console.error('[admin-reports] notifyOwner failed', { reportId: result.id, err });
  }
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
