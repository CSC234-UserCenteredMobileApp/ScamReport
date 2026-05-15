import { Elysia, t } from 'elysia';
import {
  AiEvalListResponse,
  AiEvalRunResponse,
} from '@my-product/shared';
import { requireRole } from '../../core/middleware/require_role';
import { listRuns, runEvaluation } from './admin-ai-eval.service';

export const adminAiEvalRoute = new Elysia({ prefix: '/admin/ai-eval' })
  .use(requireRole('admin'))

  .post(
    '/run',
    async () => {
      const summary = await runEvaluation();
      return { summary };
    },
    { response: AiEvalRunResponse },
  )

  .get(
    '/runs',
    async ({ query }) => {
      const limit = Math.min(Math.max(query.limit ?? 20, 1), 100);
      return listRuns(limit);
    },
    {
      query: t.Object({ limit: t.Optional(t.Integer({ minimum: 1, maximum: 100 })) }),
      response: AiEvalListResponse,
    },
  );
