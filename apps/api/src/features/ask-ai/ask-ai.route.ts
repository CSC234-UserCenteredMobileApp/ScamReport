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
  handleTurn,
  listConversations,
} from './ask-ai.service';

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
        return await handleTurn(user!.uid, params.id, body);
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
      body: AskAiTurnRequest,
      response: {
        200: AskAiTurnResponse,
        400: errorBody,
        404: errorBody,
      },
    },
  );
