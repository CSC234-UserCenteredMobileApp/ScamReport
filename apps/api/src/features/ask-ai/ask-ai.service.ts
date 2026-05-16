// Ask AI service — orchestrates conversation persistence + Gemini turn +
// RAG retrieval. The route layer in ask-ai.route.ts only handles HTTP
// concerns (auth, validation, status codes); all moving parts live here.

import { Buffer } from 'node:buffer';
import { randomUUID } from 'node:crypto';
import type {
  AskAiAttachmentMeta,
  AskAiConversationDetail,
  AskAiConversationListResponse,
  AskAiConversationSummary,
  AskAiCreateConversationResponse,
  AskAiLocale,
  AskAiMessage,
  AskAiPersistedDraft,
  AskAiTurnRequest,
  AskAiTurnResponse,
  AskAiUpsertDraftRequest,
  ScammerProfileSummary,
} from '@my-product/shared';
import type { AskAiSimilarReport } from '@my-product/shared';
import { extractIdentifiers } from '../../core/lib/identifier-extractor';
import { searchSimilarReports } from '../../core/rag/retrieval';
import { TOP_K as SIMILAR_REPORTS_TOP_K } from '../../core/ai-score/constants';
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
  const draft = parseDraftState(conv.draftState);
  let evidenceAttachments: AskAiAttachmentMeta[] = [];
  if (draft && draft.evidenceAttachmentIds.length > 0) {
    const rows = await repo.findAttachmentsInConversation(
      conversationId,
      draft.evidenceAttachmentIds,
    );
    if (rows) {
      evidenceAttachments = await Promise.all(
        rows.map(async (a) => ({
          id: a.id,
          mimeType: a.mimeType,
          sizeBytes: Number(a.sizeBytes),
          signedUrl: await safeSignedUrl(a.storagePath),
        })),
      );
    }
  }
  return {
    id: conv.id,
    createdAt: conv.createdAt.toISOString(),
    linkedReportId: conv.linkedReportId,
    messages: await Promise.all(messages.map(toAskAiMessage)),
    draft,
    evidenceAttachments,
  };
}

/**
 * Upsert (or clear with null) the per-conversation draft. Validates ownership
 * and that any referenced evidence ids belong to messages in this conversation.
 * iter-5 server-side draft sync.
 */
export async function upsertDraft(
  userId: string,
  conversationId: string,
  payload: AskAiUpsertDraftRequest,
): Promise<{ draft: AskAiPersistedDraft | null }> {
  const conv = await repo.findConversation(userId, conversationId);
  if (!conv) {
    throw new AskAiError('Conversation not found', 404, 'not_found');
  }
  if (payload === null) {
    await repo.writeDraftState(conversationId, null);
    return { draft: null };
  }
  const ids = payload.evidenceAttachmentIds ?? [];
  if (ids.length > 0) {
    const owned = await repo.findAttachmentsInConversation(conversationId, ids);
    if (!owned) {
      throw new AskAiError(
        'evidenceAttachmentIds reference attachments not in this conversation',
        400,
        'invalid_evidence',
      );
    }
  }
  await repo.writeDraftState(conversationId, payload);
  return { draft: payload };
}

function parseDraftState(value: unknown): AskAiPersistedDraft | null {
  if (!value || typeof value !== 'object') return null;
  const v = value as Record<string, unknown>;
  if (typeof v.title !== 'string' || typeof v.description !== 'string') return null;
  if (typeof v.scamTypeCode !== 'string') return null;
  const targetIdentifier =
    typeof v.targetIdentifier === 'string' ? v.targetIdentifier : null;
  const tikRaw = v.targetIdentifierKind;
  const targetIdentifierKind: AskAiPersistedDraft['targetIdentifierKind'] =
    tikRaw === 'phone' || tikRaw === 'url' || tikRaw === 'other' ? tikRaw : null;
  const userEditedDraft = Boolean(v.userEditedDraft);
  const ids = Array.isArray(v.evidenceAttachmentIds)
    ? (v.evidenceAttachmentIds as unknown[]).filter(
        (x): x is string => typeof x === 'string',
      )
    : [];
  return {
    title: v.title,
    description: v.description,
    scamTypeCode: v.scamTypeCode,
    targetIdentifier,
    targetIdentifierKind,
    userEditedDraft,
    evidenceAttachmentIds: ids,
  };
}

async function safeSignedUrl(path: string): Promise<string | null> {
  try {
    return await getSignedUrl(ATTACHMENTS_BUCKET, path, 3600);
  } catch (err) {
    console.error('[ask-ai] sign-url-failed', { storagePath: path, err });
    return null;
  }
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
  locale?: AskAiLocale,
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

  // Similar verified reports for RAG context. Two parallel paths:
  //   - exact identifier match (phones + URLs in the user message). Cheap
  //     index lookup; high precision; ordered first so Gemini treats them
  //     as the most likely reference.
  //   - semantic similarity via Gemini embedding + pgvector cosine. Wider
  //     net for free-text questions like "weird parcel SMS".
  // Both are best-effort — any failure leaves the array shorter; the turn
  // still produces a reply, just without that flavour of context.
  let similarHydrated: Awaited<ReturnType<typeof repo.hydrateSimilarReports>> = [];
  let knownScammers: Awaited<ReturnType<typeof repo.findScammersByIdentifiers>> = [];
  try {
    const { phones, urls } = extractIdentifiers(content);
    const normalisedIds = [...phones, ...urls];

    const [exactMatches, semantic, scammers] = await Promise.all([
      normalisedIds.length > 0
        ? repo.findReportsByIdentifiers(normalisedIds)
        : Promise.resolve([] as Awaited<ReturnType<typeof repo.findReportsByIdentifiers>>),
      searchSimilarReports(content, SIMILAR_REPORTS_TOP_K)
        .then((r) => repo.hydrateSimilarReports(r.map((s) => s.reportId)))
        .catch((err) => {
          console.error('[ask-ai] semantic-rag-failure', { err });
          return [] as Awaited<ReturnType<typeof repo.hydrateSimilarReports>>;
        }),
      normalisedIds.length > 0
        ? repo.findScammersByIdentifiers(normalisedIds).catch((err) => {
            console.error('[ask-ai] scammer-lookup-failure', { err });
            return [] as Awaited<ReturnType<typeof repo.findScammersByIdentifiers>>;
          })
        : Promise.resolve([] as Awaited<ReturnType<typeof repo.findScammersByIdentifiers>>),
    ]);

    knownScammers = scammers;

    // Merge — exact matches first, then semantic, deduped by report id.
    const seen = new Set<string>();
    for (const r of [...exactMatches, ...semantic]) {
      if (seen.has(r.id) || similarHydrated.length >= SIMILAR_REPORTS_TOP_K) continue;
      seen.add(r.id);
      similarHydrated.push(r);
    }
  } catch (err) {
    // Catch-all for unexpected failures (e.g. extractor regex crashes on
    // pathological input). Keep the chat alive.
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
    knownScammers: knownScammers.map((s) => ({
      id: s.id,
      displayName: s.displayName,
      suspectedName: s.suspectedName,
      person: s.person,
      aliases: s.aliases,
      riskLevel: s.riskLevel,
      reportCount: s.reportCount,
      topScamTypeCodes: s.topScamTypeCodes,
    })),
    latestUserMessage: content,
    attachments: attachments.length > 0
      ? attachments.map((a) => ({ bytes: a.bytes, mimeType: a.mimeType }))
      : undefined,
    locale,
  });

  const assistantMessage = await repo.insertAssistantMessage(
    conversationId,
    turn.reply,
    turn.intentDetected,
  );

  await repo.touchConversation(conversationId);

  // Hydrate Gemini's curated `similarReportIds` into full cards. Gemini may
  // echo IDs in any order it judges most relevant; preserve that order.
  // IDs the model invented (not present in `similarHydrated`) are dropped —
  // same anti-hallucination guarantee the previous response had.
  const hydratedById = new Map(similarHydrated.map((r) => [r.id, r]));
  const similarReports: AskAiSimilarReport[] = turn.similarReportIds
    .map((id) => hydratedById.get(id))
    .filter((r): r is NonNullable<typeof r> => Boolean(r))
    .map((r) => ({
      id: r.id,
      title: r.title,
      scamTypeCode: r.scamTypeCode,
      scamTypeLabelEn: r.scamTypeLabelEn,
      scamTypeLabelTh: r.scamTypeLabelTh,
      verifiedAt: r.verifiedAt,
    }));

  const matchedScammers: ScammerProfileSummary[] = knownScammers.map((s) => ({
    id: s.id,
    displayName: s.displayName,
    suspectedName: s.suspectedName,
    person: s.person,
    aliases: s.aliases,
    riskLevel: s.riskLevel,
    reportCount: s.reportCount,
    topScamTypeCodes: s.topScamTypeCodes,
  }));

  return {
    userMessage: await toAskAiMessage(userMessage),
    assistantMessage: await toAskAiMessage(assistantMessage),
    intentDetected: turn.intentDetected,
    reportable: turn.reportable,
    hasEnoughInfo: turn.hasEnoughInfo,
    draft: turn.draft,
    similarReports,
    matchedScammers,
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
  return handleTurn(userId, conversationId, body.content, [], body.locale);
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
