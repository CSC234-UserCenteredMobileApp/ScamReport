// Ask AI service — orchestrates conversation persistence + Gemini turn +
// RAG retrieval. The route layer in ask-ai.route.ts only handles HTTP
// concerns (auth, validation, status codes); all moving parts live here.

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
import * as repo from './ask-ai.repository';
import { runTurn } from './ask-ai.gemini';

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
    messages: messages.map(toAskAiMessage),
  };
}

export async function deleteConversation(userId: string, conversationId: string): Promise<void> {
  const ok = await repo.deleteConversation(userId, conversationId);
  if (!ok) {
    throw new AskAiError('Conversation not found', 404, 'not_found');
  }
}

export async function handleTurn(
  userId: string,
  conversationId: string,
  body: AskAiTurnRequest,
): Promise<AskAiTurnResponse> {
  const conv = await repo.findConversation(userId, conversationId);
  if (!conv) {
    throw new AskAiError('Conversation not found', 404, 'not_found');
  }
  // PR-3 ships text-only. Attachments are accepted in the schema but
  // stubbed out here — PR-5 wires them to multimodal Gemini parts.
  if (body.attachmentIds.length > 0) {
    throw new AskAiError(
      'Attachments are not yet supported',
      400,
      'attachments_unsupported',
    );
  }

  const userMessage = await repo.insertUserMessage(conversationId, body.content);

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
    const similar = await searchSimilarReports(body.content, SIMILAR_REPORTS_TOP_K);
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
    latestUserMessage: body.content,
  });

  const assistantMessage = await repo.insertAssistantMessage(
    conversationId,
    turn.reply,
    turn.intentDetected,
  );

  await repo.touchConversation(conversationId);

  return {
    userMessage: toAskAiMessage(userMessage),
    assistantMessage: toAskAiMessage(assistantMessage),
    intentDetected: turn.intentDetected,
    reportable: turn.reportable,
    hasEnoughInfo: turn.hasEnoughInfo,
    draft: turn.draft,
    similarReportIds: turn.similarReportIds,
  };
}

function toAskAiMessage(m: repo.PersistedMessage): AskAiMessage {
  return {
    id: m.id,
    role: m.role,
    content: m.content,
    intentDetected: m.intentDetected,
    createdAt: m.createdAt.toISOString(),
    attachments: m.attachments.map((a) => ({
      id: a.id,
      mimeType: a.mimeType,
      sizeBytes: Number(a.sizeBytes),
      // PR-5 will sign attachment URLs here.
      signedUrl: null,
    })),
  };
}
