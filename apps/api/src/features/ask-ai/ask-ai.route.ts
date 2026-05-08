// Ask AI HTTP plugin. All routes gated by requireAuth — Ask AI is for
// signed-in users only (FR-4.1).

import { Elysia, t } from 'elysia';
import {
  AskAiConversationDetail,
  AskAiConversationListResponse,
  AskAiCreateConversationResponse,
  AskAiTurnRequest,
  AskAiTurnResponse,
} from '@my-product/shared';
import { requireAuth } from '../../core/middleware/auth.middleware';
import {
  AskAiError,
  createConversation,
  deleteConversation,
  getConversation,
  handleTurnJson,
  handleTurn,
  listConversations,
  type AttachmentUploadInput,
} from './ask-ai.service';
import {
  AskAiAttachmentError,
  AskAiRateLimitError,
  MAX_ATTACHMENTS_PER_MESSAGE,
} from './ask-ai.limits';

const idParam = t.Object({ id: t.String({ format: 'uuid' }) });
const errorBody = t.Object({ error: t.String(), code: t.String() });

export const askAiRoute = new Elysia({ prefix: '/ask-ai' })
  .use(requireAuth)
  .post(
    '/conversations',
    async ({ user }) => createConversation(user!.uid),
    {
      response: { 200: AskAiCreateConversationResponse },
    },
  )
  .get(
    '/conversations',
    async ({ user }) => listConversations(user!.uid),
    {
      response: { 200: AskAiConversationListResponse },
    },
  )
  .get(
    '/conversations/:id',
    async ({ params, user, set }) => {
      try {
        return await getConversation(user!.uid, params.id);
      } catch (err) {
        if (err instanceof AskAiError) {
          set.status = err.status;
          return { error: err.message, code: err.code };
        }
        throw err;
      }
    },
    {
      params: idParam,
      response: { 200: AskAiConversationDetail, 404: errorBody },
    },
  )
  .delete(
    '/conversations/:id',
    async ({ params, user, set }) => {
      try {
        await deleteConversation(user!.uid, params.id);
        return { ok: true as const };
      } catch (err) {
        if (err instanceof AskAiError) {
          set.status = err.status;
          return { error: err.message, code: err.code };
        }
        throw err;
      }
    },
    {
      params: idParam,
      response: {
        200: t.Object({ ok: t.Literal(true) }),
        404: errorBody,
      },
    },
  )
  .post(
    '/conversations/:id/messages',
    async ({ params, body, user, set }) => {
      try {
        return await handleTurnJson(user!.uid, params.id, body);
      } catch (err) {
        if (
          err instanceof AskAiError ||
          err instanceof AskAiAttachmentError ||
          err instanceof AskAiRateLimitError
        ) {
          set.status = err.status;
          return { error: err.message, code: err.code };
        }
        throw err;
      }
    },
    {
      params: idParam,
      body: AskAiTurnRequest,
      response: {
        200: AskAiTurnResponse,
        400: errorBody,
        404: errorBody,
        429: errorBody,
      },
    },
  )
  // Multipart variant for attachments. The text content lives in the
  // `content` form field; up to MAX_ATTACHMENTS_PER_MESSAGE files come in
  // as `file0` / `file1` / `file2`. Single endpoint instead of a separate
  // staging upload because evidence_files / ai_message_attachments rows
  // require their parent message id (NOT NULL FK).
  .post(
    '/conversations/:id/messages/multipart',
    async ({ params, body, user, set }) => {
      try {
        const b = body as Record<string, unknown>;
        const content = typeof b.content === 'string' ? b.content : '';
        if (content.trim().length === 0) {
          set.status = 400;
          return { error: 'content is required', code: 'missing_content' };
        }
        const attachments: AttachmentUploadInput[] = [];
        for (let i = 0; i < MAX_ATTACHMENTS_PER_MESSAGE; i++) {
          const f = b[`file${i}`];
          if (
            f &&
            typeof (f as File).arrayBuffer === 'function' &&
            (f as File).size > 0
          ) {
            attachments.push({
              bytes: new Uint8Array(await (f as File).arrayBuffer()),
              mimeType: (f as File).type,
            });
          }
        }
        return await handleTurn(user!.uid, params.id, content, attachments);
      } catch (err) {
        if (
          err instanceof AskAiError ||
          err instanceof AskAiAttachmentError ||
          err instanceof AskAiRateLimitError
        ) {
          set.status = err.status;
          return { error: err.message, code: err.code };
        }
        throw err;
      }
    },
    {
      params: idParam,
      body: t.Object({
        content: t.String({ minLength: 1, maxLength: 4000 }),
        file0: t.Optional(t.Any()),
        file1: t.Optional(t.Any()),
        file2: t.Optional(t.Any()),
      }),
      response: {
        200: AskAiTurnResponse,
        400: errorBody,
        404: errorBody,
        413: errorBody,
        415: errorBody,
        429: errorBody,
      },
    },
  );
