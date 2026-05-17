import { Elysia, t } from 'elysia';
import {
  AdminAiEvalHistoryResponse,
  AdminAiEvalLatestResponse,
} from '@my-product/shared';
import { requireRole } from '../../core/middleware/require_role';
import { getHistory, getLatestSummary } from './admin-ai-eval.service';

export const adminAiEvalRoute = new Elysia()
  .use(requireRole('admin'))
  .get('/admin/ai-eval/latest', () => getLatestSummary(), {
    response: AdminAiEvalLatestResponse,
  })
  .get(
    '/admin/ai-eval/history',
    ({ query }) => getHistory(query.limit),
    {
      query: t.Object({
        limit: t.Optional(t.Integer({ minimum: 1, maximum: 365 })),
      }),
      response: AdminAiEvalHistoryResponse,
    },
  );
