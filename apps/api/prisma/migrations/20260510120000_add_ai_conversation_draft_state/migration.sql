-- AskAi iter-5: per-conversation draft state for cross-device sync.
-- Shape stored here is AskAiPersistedDraft (see packages/shared/src/schemas/ask-ai.ts).
-- evidenceAttachmentIds inside the JSON references existing
-- ai_message_attachments.id rows (chat-attachments bucket); raw bytes are
-- never stored in this column.

ALTER TABLE "ai_conversations" ADD COLUMN "draft_state" JSONB;
