// Pure Prisma calls for Ask AI. No business logic — service.ts orchestrates.

import { getPrisma } from '../../core/db/client';
import { Prisma } from '../../generated/prisma/client';

export interface PersistedMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  intentDetected: boolean;
  createdAt: Date;
  attachments: Array<{
    id: string;
    storagePath: string;
    mimeType: string;
    sizeBytes: bigint;
  }>;
}

export async function createConversation(userId: string) {
  const prisma = getPrisma();
  return prisma.aiConversation.create({
    data: { userId },
    select: { id: true, createdAt: true },
  });
}

export async function findConversation(userId: string, conversationId: string) {
  const prisma = getPrisma();
  return prisma.aiConversation.findFirst({
    where: { id: conversationId, userId },
    select: {
      id: true,
      createdAt: true,
      lastMessageAt: true,
      linkedReportId: true,
      draftState: true,
    },
  });
}

/**
 * Verify every id in `attachmentIds` belongs to a message inside the given
 * conversation. Returns the attachment metadata (storagePath, mimeType,
 * sizeBytes) for the matched ids — preserving input order. Returns `null` if
 * one or more ids are missing or owned by a different conversation; callers
 * should reject the request in that case.
 */
export async function findAttachmentsInConversation(
  conversationId: string,
  attachmentIds: string[],
): Promise<
  | Array<{ id: string; storagePath: string; mimeType: string; sizeBytes: bigint }>
  | null
> {
  if (attachmentIds.length === 0) return [];
  const prisma = getPrisma();
  const rows = await prisma.aiMessageAttachment.findMany({
    where: {
      id: { in: attachmentIds },
      message: { conversationId },
    },
    select: {
      id: true,
      storagePath: true,
      mimeType: true,
      sizeBytes: true,
    },
  });
  if (rows.length !== attachmentIds.length) return null;
  const byId = new Map(rows.map((r) => [r.id, r]));
  const ordered: typeof rows = [];
  for (const id of attachmentIds) {
    const r = byId.get(id);
    if (!r) return null;
    ordered.push(r);
  }
  return ordered;
}

export async function writeDraftState(
  conversationId: string,
  payload: unknown | null,
): Promise<void> {
  const prisma = getPrisma();
  await prisma.aiConversation.update({
    where: { id: conversationId },
    data: {
      draftState:
        payload === null
          ? Prisma.DbNull
          : (payload as Prisma.InputJsonValue),
    },
  });
}

export async function listConversations(userId: string, limit: number) {
  const prisma = getPrisma();
  const rows = await prisma.aiConversation.findMany({
    where: { userId },
    orderBy: { lastMessageAt: 'desc' },
    take: limit,
    select: {
      id: true,
      createdAt: true,
      lastMessageAt: true,
      linkedReportId: true,
      messages: {
        orderBy: { createdAt: 'asc' },
        take: 1,
        select: { content: true },
      },
    },
  });
  return rows.map((r) => ({
    id: r.id,
    createdAt: r.createdAt,
    lastMessageAt: r.lastMessageAt,
    linkedReportId: r.linkedReportId,
    preview: r.messages[0]?.content.slice(0, 120) ?? '',
  }));
}

export async function loadMessages(
  conversationId: string,
  limit?: number,
): Promise<PersistedMessage[]> {
  const prisma = getPrisma();
  const rows = await prisma.aiMessage.findMany({
    where: { conversationId },
    orderBy: { createdAt: 'asc' },
    ...(limit ? { take: limit } : {}),
    select: {
      id: true,
      role: true,
      content: true,
      intentDetected: true,
      createdAt: true,
      attachments: {
        select: {
          id: true,
          storagePath: true,
          mimeType: true,
          sizeBytes: true,
        },
      },
    },
  });
  return rows.map((r) => ({
    id: r.id,
    role: r.role as 'user' | 'assistant',
    content: r.content,
    intentDetected: r.intentDetected,
    createdAt: r.createdAt,
    attachments: r.attachments,
  }));
}

export interface AttachmentRowInput {
  storagePath: string;
  mimeType: string;
  sizeBytes: number;
}

export async function insertUserMessage(
  conversationId: string,
  content: string,
  attachments: AttachmentRowInput[] = [],
): Promise<PersistedMessage> {
  const prisma = getPrisma();
  return prisma.$transaction(async (tx) => {
    const row = await tx.aiMessage.create({
      data: {
        conversationId,
        role: 'user',
        content,
        intentDetected: false,
      },
      select: {
        id: true,
        role: true,
        content: true,
        intentDetected: true,
        createdAt: true,
      },
    });
    const attRows: PersistedMessage['attachments'] = [];
    if (attachments.length > 0) {
      for (const a of attachments) {
        const att = await tx.aiMessageAttachment.create({
          data: {
            messageId: row.id,
            storagePath: a.storagePath,
            mimeType: a.mimeType,
            sizeBytes: BigInt(a.sizeBytes),
          },
          select: {
            id: true,
            storagePath: true,
            mimeType: true,
            sizeBytes: true,
          },
        });
        attRows.push(att);
      }
    }
    return {
      id: row.id,
      role: 'user' as const,
      content: row.content,
      intentDetected: row.intentDetected,
      createdAt: row.createdAt,
      attachments: attRows,
    };
  });
}

export async function insertAssistantMessage(
  conversationId: string,
  content: string,
  intentDetected: boolean,
): Promise<PersistedMessage> {
  const prisma = getPrisma();
  const row = await prisma.aiMessage.create({
    data: {
      conversationId,
      role: 'assistant',
      content,
      intentDetected,
    },
    select: {
      id: true,
      role: true,
      content: true,
      intentDetected: true,
      createdAt: true,
    },
  });
  return {
    id: row.id,
    role: 'assistant',
    content: row.content,
    intentDetected: row.intentDetected,
    createdAt: row.createdAt,
    attachments: [],
  };
}

export async function touchConversation(conversationId: string) {
  const prisma = getPrisma();
  await prisma.aiConversation.update({
    where: { id: conversationId },
    data: { lastMessageAt: new Date() },
  });
}

export async function deleteConversation(userId: string, conversationId: string) {
  const prisma = getPrisma();
  // updateMany returns count; only deletes when ownership matches.
  const owned = await prisma.aiConversation.findFirst({
    where: { id: conversationId, userId },
    select: { id: true },
  });
  if (!owned) return false;
  await prisma.aiConversation.delete({ where: { id: conversationId } });
  return true;
}

export async function hydrateSimilarReports(reportIds: string[]) {
  if (reportIds.length === 0) return [];
  const prisma = getPrisma();
  const rows = await prisma.report.findMany({
    where: { id: { in: reportIds }, status: 'verified' },
    select: {
      id: true,
      title: true,
      verifiedAt: true,
      scamType: { select: { code: true, labelEn: true, labelTh: true } },
    },
  });
  // Preserve the input ordering (RAG results are already ranked by similarity).
  const byId = new Map(rows.map((r) => [r.id, r]));
  return reportIds
    .map((id) => byId.get(id))
    .filter((r): r is NonNullable<typeof r> => Boolean(r))
    .map((r) => ({
      id: r.id,
      title: r.title,
      verifiedAt: r.verifiedAt?.toISOString() ?? null,
      scamTypeCode: r.scamType.code,
      scamTypeLabelEn: r.scamType.labelEn,
      scamTypeLabelTh: r.scamType.labelTh,
      // Kept for downstream callers that still want a single locale label
      // (Gemini prompt context). Picks `labelEn` to match prior behaviour.
      scamTypeLabel: r.scamType.labelEn,
    }));
}

/**
 * Look up verified reports by exact-match against
 * `target_identifier_normalized`. Used by Ask AI to lift the recall on
 * questions that contain a phone number or URL (where semantic similarity
 * over a 10-digit string is noisy). Returns the same shape as
 * `hydrateSimilarReports` for trivial merging.
 *
 * Caller passes already-normalised identifiers; see
 * `core/lib/identifier-extractor.ts`.
 */
/**
 * Look up scammer profiles whose identifier `value_normalized` is in
 * `normalized`. Loads enough information to render a `ScammerProfileSummary`
 * for the Ask AI response and to prime Gemini's prompt.
 */
export async function findScammersByIdentifiers(normalized: string[]) {
  if (normalized.length === 0) return [];
  const prisma = getPrisma();
  const idRows = await prisma.scammerIdentifier.findMany({
    where: { valueNormalized: { in: normalized } },
    select: { scammerId: true },
  });
  const scammerIds = [...new Set(idRows.map((r) => r.scammerId))];
  if (scammerIds.length === 0) return [];
  const scammers = await prisma.scammer.findMany({
    where: { id: { in: scammerIds } },
    include: {
      reports: {
        where: { status: 'verified' },
        orderBy: { verifiedAt: 'desc' },
        take: 5,
        select: { scamType: { select: { code: true } } },
      },
    },
  });
  return scammers.map((s) => {
    const top: string[] = [];
    for (const r of s.reports) {
      if (!top.includes(r.scamType.code)) top.push(r.scamType.code);
    }
    return {
      id: s.id,
      displayName: s.displayName,
      suspectedName: s.suspectedName,
      aliases: s.aliases,
      riskLevel: s.riskLevel as 'low' | 'medium' | 'high' | 'unknown',
      reportCount: s.reportCountCache,
      topScamTypeCodes: top,
    };
  });
}

export async function findReportsByIdentifiers(normalized: string[]) {
  if (normalized.length === 0) return [];
  const prisma = getPrisma();
  const rows = await prisma.report.findMany({
    where: {
      status: 'verified',
      targetIdentifierNormalized: { in: normalized },
    },
    orderBy: { verifiedAt: 'desc' },
    select: {
      id: true,
      title: true,
      verifiedAt: true,
      scamType: { select: { code: true, labelEn: true, labelTh: true } },
    },
  });
  return rows.map((r) => ({
    id: r.id,
    title: r.title,
    verifiedAt: r.verifiedAt?.toISOString() ?? null,
    scamTypeCode: r.scamType.code,
    scamTypeLabelEn: r.scamType.labelEn,
    scamTypeLabelTh: r.scamType.labelTh,
    scamTypeLabel: r.scamType.labelEn,
  }));
}
