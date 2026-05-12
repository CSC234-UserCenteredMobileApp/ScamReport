import { useMutation, useQueryClient } from '@tanstack/react-query';
import type { AdminActionResponse, AdminQueueResponse } from '@my-product/shared';
import { apiFetch } from '@/lib/api/client';
import { validators } from '@/lib/api/validators';
import { queryKeys } from '@/lib/api/query-keys';

export type ModerationActionKind = 'approve' | 'reject' | 'flag' | 'unflag';

interface ActionInput {
  id: string;
  remark: string;
}

interface MutationContext {
  previousQueues: Array<[readonly unknown[], AdminQueueResponse | undefined]>;
}

function actionPath(id: string, kind: ModerationActionKind): string {
  return `/admin/reports/${id}/${kind}`;
}

function shouldRemoveFromQueue(kind: ModerationActionKind): boolean {
  return kind === 'approve' || kind === 'reject' || kind === 'unflag';
}

export function useModerationAction(kind: ModerationActionKind) {
  const qc = useQueryClient();
  return useMutation<AdminActionResponse, Error, ActionInput, MutationContext>({
    mutationFn: ({ id, remark }) =>
      apiFetch(actionPath(id, kind), validators.adminAction, {
        method: 'POST',
        body: { remark },
      }),
    onMutate: async ({ id }) => {
      await qc.cancelQueries({ queryKey: queryKeys.moderation.all });
      const previousQueues = qc.getQueriesData<AdminQueueResponse>({
        queryKey: queryKeys.moderation.all,
      });
      qc.setQueriesData<AdminQueueResponse>(
        { queryKey: queryKeys.moderation.all },
        (prev) => {
          if (!prev) return prev;
          if (shouldRemoveFromQueue(kind)) {
            const target = prev.items.find((it) => it.id === id);
            if (!target) return prev;
            const wasFlagged = target.status === 'flagged';
            return {
              ...prev,
              items: prev.items.filter((it) => it.id !== id),
              pendingCount:
                !wasFlagged && prev.pendingCount > 0
                  ? prev.pendingCount - 1
                  : prev.pendingCount,
              flaggedCount:
                wasFlagged && prev.flaggedCount > 0
                  ? prev.flaggedCount - 1
                  : prev.flaggedCount,
            };
          }
          if (kind === 'flag') {
            return {
              ...prev,
              items: prev.items.map((it) =>
                it.id === id ? { ...it, status: 'flagged' as const } : it,
              ),
              pendingCount:
                prev.items.find((it) => it.id === id)?.status === 'pending' &&
                prev.pendingCount > 0
                  ? prev.pendingCount - 1
                  : prev.pendingCount,
              flaggedCount: prev.flaggedCount + 1,
            };
          }
          return prev;
        },
      );
      return { previousQueues };
    },
    onError: (_err, _input, ctx) => {
      if (!ctx) return;
      for (const [key, snap] of ctx.previousQueues) {
        qc.setQueryData(key, snap);
      }
    },
    onSettled: () => {
      void qc.invalidateQueries({ queryKey: queryKeys.moderation.all });
    },
  });
}
