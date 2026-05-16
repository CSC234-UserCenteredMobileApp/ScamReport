import { Type, type Static } from '@sinclair/typebox';
import { ScammerProfileSummary } from './scammers';

// =============================================================================
// Ask AI (P-09 / FR-4.x) — conversational AI chat
// =============================================================================
//
// Schemas in this file follow the data flow:
//   1. User opens the screen → POST /ask-ai/conversations.
//   2. User attaches files → POST /ask-ai/conversations/:id/attachments
//      (multipart, returns AskAiAttachmentUploadResponse). Staged until bound.
//   3. User sends a message → POST /ask-ai/conversations/:id/messages with
//      AskAiTurnRequest. Server: persists user msg, runs single structured
//      Gemini call, persists assistant msg, returns AskAiTurnResponse.
//   4. If reportable && intentDetected: client surfaces ConsentCard, then
//      POST /reports (see reports.ts) with the AskAiDraft contents +
//      sourceConversationId. Server links conversation → report.
//
// Reportable / hasEnoughInfo are server-side-only signals. UI surfaces them
// via the presence/absence of the draft + the AI bubble's CTA — never as a
// verdict label (FR-4.3 forbids Scam/Safe/Suspicious/Unknown labels here).

export const AskAiAttachmentMeta = Type.Object({
  id: Type.String({ format: 'uuid' }),
  mimeType: Type.String(),
  sizeBytes: Type.Integer({ minimum: 1 }),
  signedUrl: Type.Union([Type.String(), Type.Null()]),
});
export type AskAiAttachmentMeta = Static<typeof AskAiAttachmentMeta>;

// Target-identifier kind. Hoisted above AskAiConversationDetail because the
// detail's draft sub-schema (iter-5) references it.
export const AskAiTargetIdentifierKind = Type.Union([
  Type.Literal('phone'),
  Type.Literal('url'),
  Type.Literal('other'),
  Type.Null(),
]);
export type AskAiTargetIdentifierKind = Static<typeof AskAiTargetIdentifierKind>;

export const AskAiMessageRole = Type.Union([
  Type.Literal('user'),
  Type.Literal('assistant'),
]);
export type AskAiMessageRole = Static<typeof AskAiMessageRole>;

export const AskAiMessage = Type.Object({
  id: Type.String({ format: 'uuid' }),
  role: AskAiMessageRole,
  content: Type.String(),
  intentDetected: Type.Boolean(),
  createdAt: Type.String({ format: 'date-time' }),
  attachments: Type.Array(AskAiAttachmentMeta),
});
export type AskAiMessage = Static<typeof AskAiMessage>;

export const AskAiConversationSummary = Type.Object({
  id: Type.String({ format: 'uuid' }),
  createdAt: Type.String({ format: 'date-time' }),
  lastMessageAt: Type.String({ format: 'date-time' }),
  preview: Type.String(),
  linkedReportId: Type.Union([Type.String({ format: 'uuid' }), Type.Null()]),
});
export type AskAiConversationSummary = Static<typeof AskAiConversationSummary>;

export const AskAiConversationListResponse = Type.Object({
  items: Type.Array(AskAiConversationSummary),
});
export type AskAiConversationListResponse = Static<typeof AskAiConversationListResponse>;

export const AskAiConversationDetail = Type.Object({
  id: Type.String({ format: 'uuid' }),
  createdAt: Type.String({ format: 'date-time' }),
  linkedReportId: Type.Union([Type.String({ format: 'uuid' }), Type.Null()]),
  messages: Type.Array(AskAiMessage),
  // Server-persisted active draft for cross-device sync (iter-5). Null when
  // the user hasn't started a draft for this conversation.
  draft: Type.Optional(Type.Union([
    Type.Object({
      title: Type.String(),
      description: Type.String(),
      scamTypeCode: Type.String(),
      targetIdentifier: Type.Union([Type.String(), Type.Null()]),
      targetIdentifierKind: AskAiTargetIdentifierKind,
      userEditedDraft: Type.Boolean(),
      evidenceAttachmentIds: Type.Array(Type.String({ format: 'uuid' })),
    }),
    Type.Null(),
  ])),
  // Hydrated metadata for evidenceAttachmentIds — signed URLs so the editor can
  // render restored evidence without raw bytes.
  evidenceAttachments: Type.Optional(Type.Array(AskAiAttachmentMeta)),
});
export type AskAiConversationDetail = Static<typeof AskAiConversationDetail>;

export const AskAiCreateConversationResponse = Type.Object({
  conversationId: Type.String({ format: 'uuid' }),
  createdAt: Type.String({ format: 'date-time' }),
});
export type AskAiCreateConversationResponse = Static<typeof AskAiCreateConversationResponse>;

export const AskAiAttachmentUploadResponse = Type.Object({
  attachmentId: Type.String({ format: 'uuid' }),
  mimeType: Type.String(),
  sizeBytes: Type.Integer({ minimum: 1 }),
});
export type AskAiAttachmentUploadResponse = Static<typeof AskAiAttachmentUploadResponse>;

// AskAiDraft — shape of an AI-drafted report. Mirrors CreateReportRequest
// payload fields the AI can populate. The submit action posts these fields
// to /reports (along with consent + sourceConversationId).
export const AskAiDraft = Type.Object({
  title: Type.String({ minLength: 4, maxLength: 200 }),
  description: Type.String({ minLength: 10, maxLength: 2000 }),
  scamTypeCode: Type.String({ minLength: 1 }),
  targetIdentifier: Type.Union([Type.String(), Type.Null()]),
  targetIdentifierKind: AskAiTargetIdentifierKind,
  // Name the user said the offender claimed (or the AI inferred from a known
  // scammer match). Null when no name surfaced. Moderators read this directly.
  suspectedScammerName: Type.Union([Type.String(), Type.Null()]),
});
export type AskAiDraft = Static<typeof AskAiDraft>;

// Locale — UI language the user is currently chatting in. Server forwards
// this to Gemini as a hard "RESPOND IN" rule so the AI doesn't drift between
// languages. iter-5.
export const AskAiLocale = Type.Union([
  Type.Literal('th'),
  Type.Literal('en'),
]);
export type AskAiLocale = Static<typeof AskAiLocale>;

// AskAiTurnRequest — body of POST /ask-ai/conversations/:id/messages.
export const AskAiTurnRequest = Type.Object({
  content: Type.String({ minLength: 1, maxLength: 4000 }),
  attachmentIds: Type.Array(Type.String({ format: 'uuid' }), { maxItems: 3 }),
  locale: Type.Optional(AskAiLocale),
});
export type AskAiTurnRequest = Static<typeof AskAiTurnRequest>;

// Server-persisted draft. Bytes are NOT stored on the server — `evidenceAttachmentIds`
// references existing ai_message_attachments.id rows (chat-attachments bucket),
// which is what the user curated in the editor's evidence section. iter-5 server-sync.
export const AskAiPersistedDraft = Type.Object({
  title: Type.String({ minLength: 0, maxLength: 200 }),
  description: Type.String({ minLength: 0, maxLength: 5000 }),
  scamTypeCode: Type.String({ maxLength: 64 }),
  targetIdentifier: Type.Union([Type.String({ maxLength: 512 }), Type.Null()]),
  targetIdentifierKind: AskAiTargetIdentifierKind,
  userEditedDraft: Type.Boolean(),
  evidenceAttachmentIds: Type.Array(Type.String({ format: 'uuid' }), { maxItems: 5, default: [] }),
});
export type AskAiPersistedDraft = Static<typeof AskAiPersistedDraft>;

// PATCH /ask-ai/conversations/:id/draft body. Pass null to clear.
export const AskAiUpsertDraftRequest = Type.Union([
  AskAiPersistedDraft,
  Type.Null(),
]);
export type AskAiUpsertDraftRequest = Static<typeof AskAiUpsertDraftRequest>;

// AskAiTurnResponse — what /messages returns. The user/assistant messages are
// persisted Postgres rows. intentDetected/reportable/hasEnoughInfo are
// server-derived flags from the structured Gemini call. draft is set when
// reportable && hasEnoughInfo. similarReports are the verified-report
// matches the AI bubble renders inline (title + type + verifiedAt + tap-
// through to /report-detail/:id).
export const AskAiMissingFact = Type.Union([
  Type.Literal('description'),
  Type.Literal('targetIdentifier'),
  Type.Literal('scamTypeCue'),
  Type.Literal('userAction'),
  // Set when the AI suspects a known scammer profile matches the user's
  // identifier and wants to confirm the alias by name.
  Type.Literal('scammerAlias'),
]);
export type AskAiMissingFact = Static<typeof AskAiMissingFact>;

// Compact verified-report card surfaced in the chat. Reporter identity is
// intentionally absent (FR-7.4 + FR-7.8) — this shape is shown to any
// authenticated Ask AI user, including guests-elevated-to-user.
export const AskAiSimilarReport = Type.Object({
  id: Type.String({ format: 'uuid' }),
  title: Type.String(),
  scamTypeCode: Type.String(),
  scamTypeLabelEn: Type.String(),
  scamTypeLabelTh: Type.String(),
  verifiedAt: Type.Union([Type.String({ format: 'date-time' }), Type.Null()]),
});
export type AskAiSimilarReport = Static<typeof AskAiSimilarReport>;

export const AskAiTurnResponse = Type.Object({
  userMessage: AskAiMessage,
  assistantMessage: AskAiMessage,
  intentDetected: Type.Boolean(),
  reportable: Type.Boolean(),
  hasEnoughInfo: Type.Boolean(),
  draft: Type.Union([AskAiDraft, Type.Null()]),
  similarReports: Type.Array(AskAiSimilarReport, { maxItems: 5 }),
  // Known scammer profiles whose identifiers appeared in the user message
  // (phone/URL match). Drives the "this looks like a known scammer named X"
  // affordance and lets the AI ask follow-ups by alias rather than generic.
  matchedScammers: Type.Array(ScammerProfileSummary, { maxItems: 5, default: [] }),
  // The five required facts the AI may collect before it can draft.
  // `scammerAlias` is optional — only fires when a known scammer is in context.
  missingFacts: Type.Array(AskAiMissingFact, { maxItems: 5, default: [] }),
});
export type AskAiTurnResponse = Static<typeof AskAiTurnResponse>;
