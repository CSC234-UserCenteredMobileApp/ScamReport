// Pure Prisma calls for Ask AI. No business logic — service.ts orchestrates.

import { getPrisma } from '../../core/db/client';

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
      scamType: { select: { code: true, labelEn: true } },
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
      scamTypeLabel: r.scamType.labelEn,
    }));
}
