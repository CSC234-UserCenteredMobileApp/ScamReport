// Ask AI service — orchestrates conversation persistence + Gemini turn +
// RAG retrieval. The route layer in ask-ai.route.ts only handles HTTP
// concerns (auth, validation, status codes); all moving parts live here.

import { Buffer } from 'node:buffer';
import { randomUUID } from 'node:crypto';
import type {
  AskAiConversationDetail,
  AskAiConversationListResponse,
  AskAiConversationSummary,
  AskAiCreateConversationResponse,
  AskAiMessage,
  AskAiTurnRequest,
  AskAiTurnResponse,
} from '@my-product/shared';
import { searchSimilarReports } from '../../core/rag/retrieval';
import { getSignedUrl, uploadFile } from '../../core/supabase/storage';
import * as repo from './ask-ai.repository';
import { runTurn } from './ask-ai.gemini';
import {
  ATTACHMENTS_BUCKET,
  AskAiAttachmentError,
  MAX_ATTACHMENTS_PER_MESSAGE,
  assertWithinDailyTurnCap,
  extFromMime,
  validateAttachment,
} from './ask-ai.limits';

export class AskAiError extends Error {
  constructor(
    message: string,
    public readonly status: number,
    public readonly code: string,
  ) {
    super(message);
    this.name = 'AskAiError';
  }
}

const HISTORY_TURNS_FOR_PROMPT = 12;
const SIMILAR_REPORTS_TOP_K = 5;
const CONVERSATION_LIST_LIMIT = 50;

export async function createConversation(
  userId: string,
): Promise<AskAiCreateConversationResponse> {
  const row = await repo.createConversation(userId);
  return {
    conversationId: row.id,
    createdAt: row.createdAt.toISOString(),
  };
}

export async function listConversations(
  userId: string,
): Promise<AskAiConversationListResponse> {
  const rows = await repo.listConversations(userId, CONVERSATION_LIST_LIMIT);
  const items: AskAiConversationSummary[] = rows.map((r) => ({
    id: r.id,
    createdAt: r.createdAt.toISOString(),
    lastMessageAt: r.lastMessageAt.toISOString(),
    preview: r.preview,
    linkedReportId: r.linkedReportId,
  }));
  return { items };
}

export async function getConversation(
  userId: string,
  conversationId: string,
): Promise<AskAiConversationDetail> {
  const conv = await repo.findConversation(userId, conversationId);
  if (!conv) {
    throw new AskAiError('Conversation not found', 404, 'not_found');
  }
  const messages = await repo.loadMessages(conversationId);
  return {
    id: conv.id,
    createdAt: conv.createdAt.toISOString(),
    linkedReportId: conv.linkedReportId,
    messages: await Promise.all(messages.map(toAskAiMessage)),
  };
}

export async function deleteConversation(userId: string, conversationId: string): Promise<void> {
  const ok = await repo.deleteConversation(userId, conversationId);
  if (!ok) {
    throw new AskAiError('Conversation not found', 404, 'not_found');
  }
}

export interface AttachmentUploadInput {
  bytes: Uint8Array;
  mimeType: string;
}

export async function handleTurn(
  userId: string,
  conversationId: string,
  content: string,
  attachments: AttachmentUploadInput[] = [],
): Promise<AskAiTurnResponse> {
  const conv = await repo.findConversation(userId, conversationId);
  if (!conv) {
    throw new AskAiError('Conversation not found', 404, 'not_found');
  }

  // Daily turn cap — enforced before doing any expensive work (Gemini call,
  // Supabase upload). Throws 429 on cap.
  await assertWithinDailyTurnCap(userId);

  if (attachments.length > MAX_ATTACHMENTS_PER_MESSAGE) {
    throw new AskAiAttachmentError(
      'Too many attachments (max 3)',
      400,
      'too_many_attachments',
    );
  }
  for (const a of attachments) {
    validateAttachment(a);
  }

  // Upload attachments to Supabase Storage. Each lands at
  //   chat-attachments/{conversationId}/{uuid}.{ext}
  // so RLS policies can scope reads by conversation prefix later.
  const uploadedAttachments: repo.AttachmentRowInput[] = [];
  for (const a of attachments) {
    const storagePath = `${conversationId}/${randomUUID()}.${extFromMime(a.mimeType)}`;
    await uploadFile(ATTACHMENTS_BUCKET, storagePath, Buffer.from(a.bytes), {
      contentType: a.mimeType,
      upsert: false,
    });
    uploadedAttachments.push({
      storagePath,
      mimeType: a.mimeType,
      sizeBytes: a.bytes.byteLength,
    });
  }

  const userMessage = await repo.insertUserMessage(
    conversationId,
    content,
    uploadedAttachments,
  );

  // Pull recent history for prompt context (excluding the just-inserted row,
  // because we'll pass `latestUserMessage` separately).
  const recent = await repo.loadMessages(conversationId);
  const historyForPrompt = recent
    .filter((m) => m.id !== userMessage.id)
    .slice(-HISTORY_TURNS_FOR_PROMPT)
    .map((m) => ({ role: m.role, content: m.content }));

  // Similar verified reports for RAG context.
  let similarHydrated: Awaited<ReturnType<typeof repo.hydrateSimilarReports>> = [];
  try {
    const similar = await searchSimilarReports(content, SIMILAR_REPORTS_TOP_K);
    similarHydrated = await repo.hydrateSimilarReports(similar.map((s) => s.reportId));
  } catch (err) {
    // RAG failure is non-fatal — we just don't pass similar context to Gemini.
    console.error('[ask-ai] rag-failure', { err });
  }

  const turn = await runTurn({
    history: historyForPrompt,
    similarReports: similarHydrated.map((r) => ({
      id: r.id,
      title: r.title,
      scamTypeCode: r.scamTypeCode,
      scamTypeLabel: r.scamTypeLabel,
      verifiedAt: r.verifiedAt,
    })),
    latestUserMessage: content,
    attachments: attachments.length > 0
      ? attachments.map((a) => ({ bytes: a.bytes, mimeType: a.mimeType }))
      : undefined,
  });

  const assistantMessage = await repo.insertAssistantMessage(
    conversationId,
    turn.reply,
    turn.intentDetected,
  );

  await repo.touchConversation(conversationId);

  return {
    userMessage: await toAskAiMessage(userMessage),
    assistantMessage: await toAskAiMessage(assistantMessage),
    intentDetected: turn.intentDetected,
    reportable: turn.reportable,
    hasEnoughInfo: turn.hasEnoughInfo,
    draft: turn.draft,
    similarReportIds: turn.similarReportIds,
    missingFacts: turn.missingFacts,
  };
}

// Legacy JSON wrapper. Keeps PR-3 callers compiling.
export async function handleTurnJson(
  userId: string,
  conversationId: string,
  body: AskAiTurnRequest,
): Promise<AskAiTurnResponse> {
  // Multipart endpoint is the path for attachments. JSON path stays
  // text-only; reject if any attachmentIds are present.
  if (body.attachmentIds.length > 0) {
    throw new AskAiError(
      'Use the multipart endpoint to send attachments',
      400,
      'use_multipart',
    );
  }
  return handleTurn(userId, conversationId, body.content, []);
}

async function toAskAiMessage(m: repo.PersistedMessage): Promise<AskAiMessage> {
  const attachments = await Promise.all(
    m.attachments.map(async (a) => {
      let signedUrl: string | null = null;
      try {
        signedUrl = await getSignedUrl(ATTACHMENTS_BUCKET, a.storagePath, 3600);
      } catch (err) {
        // Fall back to null URL — message body still renders. Logged so the
        // sign-failure rate is observable in production.
        console.error('[ask-ai] sign-url-failed', {
          storagePath: a.storagePath,
          err,
        });
      }
      return {
        id: a.id,
        mimeType: a.mimeType,
        sizeBytes: Number(a.sizeBytes),
        signedUrl,
      };
    }),
  );
  return {
    id: m.id,
    role: m.role,
    content: m.content,
    intentDetected: m.intentDetected,
    createdAt: m.createdAt.toISOString(),
    attachments,
  };
}
