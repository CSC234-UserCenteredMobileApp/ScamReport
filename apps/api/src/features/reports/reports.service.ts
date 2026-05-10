// =============================================================================
// Reports submit pipeline (FR-5.x — POST /reports + POST /reports/evidence)
// =============================================================================
//
// PR-2 of the Ask AI plan. Builds the report-create flow shared by both:
//   - Future manual /submit-report screen (out of scope — UI is later).
//   - Ask AI's "Submit drafted report" inline-consent submit (PR-4).
//
// The handler:
//   1. Resolves scam_type by code → scam_type_id.
//   2. Idempotency check: if clientSubmissionId is present, look for a
//      recent report by the same reporter+id within RECENT_WINDOW_MS and
//      return it. Best-effort until a partial-unique index lands.
//   3. Inserts reports row (status='pending') + evidence_files rows in a
//      single $transaction.
//   4. If sourceConversationId is provided, sets ai_conversations.linked_report_id.
//   5. Calls mirrorMyReport(report) — failure is logged + swallowed.
//   6. Returns CreateReportResponse.
//
// Reporter PII: never returned. We accept reporterId from the auth layer;
// it is internal only.

import { randomUUID } from 'node:crypto';
import { Buffer } from 'node:buffer';
import type { CreateReportRequest, CreateReportResponse } from '@my-product/shared';
import { getPrisma } from '../../core/db/client';
import { Prisma } from '../../generated/prisma/client';
import { copyFile, uploadFile } from '../../core/supabase/storage';
import { mirrorMyReport } from '../../sync/firestore_sync';

const ATTACHMENTS_BUCKET = 'chat-attachments';
const MAX_EVIDENCE_PER_REPORT = 5;

export class ReportSubmitError extends Error {
  constructor(
    message: string,
    public readonly status: number,
    public readonly code: string,
  ) {
    super(message);
    this.name = 'ReportSubmitError';
  }
}

const ALLOWED_EVIDENCE_MIME = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
  'application/pdf',
]);
const MAX_EVIDENCE_BYTES = 10 * 1024 * 1024; // 10 MB
const EVIDENCE_BUCKET = 'evidence';
const RECENT_WINDOW_MS = 60_000; // 1 minute idempotency window

type EvidenceKind = 'image' | 'pdf';

export interface UploadedEvidence {
  storagePath: string;
  kind: EvidenceKind;
  mimeType: string;
  sizeBytes: number;
}

/**
 * Validate + upload a single evidence file. Returns the metadata the client
 * should pass back inside CreateReportRequest.evidenceFiles. **Does not**
 * insert an evidence_files row — that happens in createReport so the row is
 * always tied to a real report (the FK is NOT NULL).
 *
 * Storage path: evidence/{userId}/{uuid}.{ext}. Tying paths to userId means
 * an authenticated bucket policy can use the path prefix to gate listing.
 */
export async function uploadEvidence(
  userId: string,
  file: { name: string; type: string; bytes: Uint8Array | ArrayBuffer },
): Promise<UploadedEvidence> {
  const mimeType = file.type;
  if (!ALLOWED_EVIDENCE_MIME.has(mimeType)) {
    throw new ReportSubmitError(
      `Unsupported file type: ${mimeType}`,
      415,
      'unsupported_media_type',
    );
  }
  const bytes = file.bytes instanceof Uint8Array ? file.bytes : new Uint8Array(file.bytes);
  if (bytes.byteLength > MAX_EVIDENCE_BYTES) {
    throw new ReportSubmitError('File too large (max 10MB)', 413, 'file_too_large');
  }
  if (bytes.byteLength === 0) {
    throw new ReportSubmitError('File is empty', 400, 'empty_file');
  }

  const ext = extFromMime(mimeType);
  const storagePath = `${userId}/${randomUUID()}.${ext}`;
  await uploadFile(EVIDENCE_BUCKET, storagePath, Buffer.from(bytes), {
    contentType: mimeType,
    upsert: false,
  });

  return {
    storagePath,
    kind: mimeType === 'application/pdf' ? 'pdf' : 'image',
    mimeType,
    sizeBytes: bytes.byteLength,
  };
}

function extFromMime(mime: string): string {
  switch (mime) {
    case 'image/jpeg':
      return 'jpg';
    case 'image/png':
      return 'png';
    case 'image/webp':
      return 'webp';
    case 'image/gif':
      return 'gif';
    case 'application/pdf':
      return 'pdf';
    default:
      return 'bin';
  }
}

export async function createReport(
  reporterId: string,
  input: CreateReportRequest,
): Promise<CreateReportResponse> {
  const prisma = getPrisma();

  // Resolve scam type code → id (validates that the taxonomy entry exists).
  const scamType = await prisma.scamType.findUnique({
    where: { code: input.scamTypeCode },
    select: { id: true, isActive: true },
  });
  if (!scamType || !scamType.isActive) {
    throw new ReportSubmitError(
      `Unknown scam type: ${input.scamTypeCode}`,
      400,
      'invalid_scam_type',
    );
  }

  // Best-effort idempotency on (reporterId, clientSubmissionId) within a
  // recent window. A unique partial index is the durable solution; this is
  // the app-side stop-gap noted in the plan.
  if (input.clientSubmissionId) {
    const since = new Date(Date.now() - RECENT_WINDOW_MS);
    const existing = await prisma.report.findFirst({
      where: {
        reporterId,
        createdAt: { gte: since },
        // `client_submission_id` is not yet a column. Best-effort: match by
        // (reporterId, title, scamTypeId) within RECENT_WINDOW_MS as a
        // conservative dedupe. When the column lands, replace this with an
        // exact lookup. The mobile client relies on a correct status field
        // either way.
        title: input.title,
        scamTypeId: scamType.id,
      },
      select: { id: true, status: true, createdAt: true },
      orderBy: { createdAt: 'desc' },
    });
    if (existing) {
      return {
        id: existing.id,
        status: 'pending',
        createdAt: existing.createdAt.toISOString(),
      };
    }
  }

  const targetIdentifier = input.targetIdentifier ?? null;
  const targetIdentifierKind = input.targetIdentifierKind ?? null;
  const targetIdentifierNormalized = normalizeIdentifier(
    targetIdentifier,
    targetIdentifierKind,
  );

  // Promote any chat-attachment evidence the user curated in a restored draft
  // — copy bytes from chat-attachments → evidence bucket and convert to
  // EvidenceMetadata. iter-5 server-side draft sync.
  const promotedIds = input.promotedEvidenceAttachmentIds ?? [];
  const promoted: Array<{
    storagePath: string;
    kind: 'image' | 'pdf';
    mimeType: string;
    sizeBytes: number;
  }> = [];
  if (promotedIds.length > 0) {
    if (!input.sourceConversationId) {
      throw new ReportSubmitError(
        'promotedEvidenceAttachmentIds requires sourceConversationId',
        400,
        'missing_source_conversation',
      );
    }
    const owned = await prisma.aiMessageAttachment.findMany({
      where: {
        id: { in: promotedIds },
        message: {
          conversation: {
            id: input.sourceConversationId,
            userId: reporterId,
          },
        },
      },
      select: {
        id: true,
        storagePath: true,
        mimeType: true,
        sizeBytes: true,
      },
    });
    if (owned.length !== promotedIds.length) {
      throw new ReportSubmitError(
        'One or more promotedEvidenceAttachmentIds were not found in the source conversation',
        400,
        'invalid_promoted_evidence',
      );
    }
    const byId = new Map(owned.map((r) => [r.id, r]));
    for (const id of promotedIds) {
      const src = byId.get(id);
      if (!src) continue;
      const ext = extFromMime(src.mimeType);
      const dstPath = `${reporterId}/${randomUUID()}.${ext}`;
      await copyFile(ATTACHMENTS_BUCKET, src.storagePath, EVIDENCE_BUCKET, dstPath, {
        contentType: src.mimeType,
      });
      promoted.push({
        storagePath: dstPath,
        kind: src.mimeType === 'application/pdf' ? 'pdf' : 'image',
        mimeType: src.mimeType,
        sizeBytes: Number(src.sizeBytes),
      });
    }
  }

  const totalEvidenceCount = input.evidenceFiles.length + promoted.length;
  if (totalEvidenceCount > MAX_EVIDENCE_PER_REPORT) {
    throw new ReportSubmitError(
      `Too many evidence files (max ${MAX_EVIDENCE_PER_REPORT})`,
      400,
      'too_many_evidence_files',
    );
  }

  // Atomic insert: report + evidence_files. The 5-row evidence trigger fires
  // on each insert, so even at exactly 5 the trigger should pass (it raises
  // when an *existing* row count >=5; at insert time count is 0..4).
  const reportId = randomUUID();
  const now = new Date();
  const evidenceCreates = [
    ...input.evidenceFiles.map((f) => ({
      reportId,
      storagePath: f.storagePath,
      kind: f.kind,
      mimeType: f.mimeType,
      sizeBytes: BigInt(f.sizeBytes),
    })),
    ...promoted.map((f) => ({
      reportId,
      storagePath: f.storagePath,
      kind: f.kind,
      mimeType: f.mimeType,
      sizeBytes: BigInt(f.sizeBytes),
    })),
  ];

  const created = await prisma.$transaction(async (tx) => {
    const report = await tx.report.create({
      data: {
        id: reportId,
        reporterId,
        title: input.title,
        description: input.description,
        scamTypeId: scamType.id,
        targetIdentifier,
        targetIdentifierKind,
        targetIdentifierNormalized,
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      },
      select: {
        id: true,
        status: true,
        createdAt: true,
        title: true,
        scamType: { select: { code: true } },
      },
    });

    if (evidenceCreates.length > 0) {
      await tx.evidenceFile.createMany({ data: evidenceCreates });
    }

    if (input.sourceConversationId) {
      // Only link if the conversation is owned by the same user. We update
      // conditionally to avoid leaking other users' conversations. Also
      // clear the in-progress draft now that it has been submitted.
      await tx.aiConversation.updateMany({
        where: { id: input.sourceConversationId, userId: reporterId },
        data: { linkedReportId: report.id, draftState: Prisma.DbNull },
      });
    }

    return report;
  });

  // Firestore mirror — non-fatal on failure (Postgres is authoritative).
  await mirrorMyReport({
    id: created.id,
    reporterId,
    title: created.title,
    status: 'pending',
    scamTypeCode: created.scamType.code,
    createdAt: created.createdAt,
    updatedAt: created.createdAt,
  });

  return {
    id: created.id,
    status: 'pending',
    createdAt: created.createdAt.toISOString(),
  };
}

// Lightweight normalisation for the verdict-lookup index. A heavier pass
// (E.164 phone, full URL canonicalisation) lives in the check pipeline.
function normalizeIdentifier(
  raw: string | null,
  kind: 'phone' | 'url' | 'other' | null,
): string | null {
  if (!raw) return null;
  const trimmed = raw.trim();
  if (!trimmed) return null;
  if (kind === 'phone') return trimmed.replace(/[^\d+]/g, '');
  if (kind === 'url') {
    try {
      const u = new URL(trimmed.startsWith('http') ? trimmed : `https://${trimmed}`);
      return u.host.toLowerCase();
    } catch {
      return trimmed.toLowerCase();
    }
  }
  return trimmed.toLowerCase();
}
