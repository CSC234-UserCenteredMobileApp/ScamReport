import { Type, type Static } from '@sinclair/typebox';

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
export const AskAiTargetIdentifierKind = Type.Union([
  Type.Literal('phone'),
  Type.Literal('url'),
  Type.Literal('other'),
  Type.Null(),
]);
export type AskAiTargetIdentifierKind = Static<typeof AskAiTargetIdentifierKind>;

export const AskAiDraft = Type.Object({
  title: Type.String({ minLength: 4, maxLength: 200 }),
  description: Type.String({ minLength: 10, maxLength: 2000 }),
  scamTypeCode: Type.String({ minLength: 1 }),
  targetIdentifier: Type.Union([Type.String(), Type.Null()]),
  targetIdentifierKind: AskAiTargetIdentifierKind,
});
export type AskAiDraft = Static<typeof AskAiDraft>;

// AskAiTurnRequest — body of POST /ask-ai/conversations/:id/messages.
export const AskAiTurnRequest = Type.Object({
  content: Type.String({ minLength: 1, maxLength: 4000 }),
  attachmentIds: Type.Array(Type.String({ format: 'uuid' }), { maxItems: 3 }),
});
export type AskAiTurnRequest = Static<typeof AskAiTurnRequest>;

// AskAiTurnResponse — what /messages returns. The user/assistant messages are
// persisted Postgres rows. intentDetected/reportable/hasEnoughInfo are
// server-derived flags from the structured Gemini call. draft is set when
// reportable && hasEnoughInfo. similarReportIds are the verified-report
// matches surfaced by the AI bubble inline.
export const AskAiMissingFact = Type.Union([
  Type.Literal('description'),
  Type.Literal('targetIdentifier'),
  Type.Literal('scamTypeCue'),
  Type.Literal('userAction'),
]);
export type AskAiMissingFact = Static<typeof AskAiMissingFact>;

export const AskAiTurnResponse = Type.Object({
  userMessage: AskAiMessage,
  assistantMessage: AskAiMessage,
  intentDetected: Type.Boolean(),
  reportable: Type.Boolean(),
  hasEnoughInfo: Type.Boolean(),
  draft: Type.Union([AskAiDraft, Type.Null()]),
  similarReportIds: Type.Array(Type.String({ format: 'uuid' }), { maxItems: 5 }),
  // The four required facts the AI must collect before it can draft. Empty
  // ⇔ hasEnoughInfo=true. Drives AI question rigor (iter-4 plan).
  missingFacts: Type.Array(AskAiMissingFact, { maxItems: 4, default: [] }),
});
export type AskAiTurnResponse = Static<typeof AskAiTurnResponse>;
