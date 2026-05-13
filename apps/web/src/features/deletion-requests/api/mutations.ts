import { useMutation, useQueryClient } from '@tanstack/react-query';
import type {
  AdminDeletionActionResponse,
  AdminDeletionRequestListResponse,
} from '@my-product/shared';
import { apiFetch } from '@/lib/api/client';
import { validators } from '@/lib/api/validators';
import { queryKeys } from '@/lib/api/query-keys';

interface ActionContext {
  // Snapshots taken before the optimistic write so onError can roll back.
  previousLists: Array<[readonly unknown[], AdminDeletionRequestListResponse | undefined]>;
}

function dropFromList(
  prev: AdminDeletionRequestListResponse | undefined,
  id: string,
): AdminDeletionRequestListResponse | undefined {
  if (!prev) return prev;
  const target = prev.items.find((it) => it.id === id);
  if (!target) return prev;
  const wasPending = target.status === 'pending';
  return {
    items: prev.items.filter((it) => it.id !== id),
    pendingCount: wasPending && prev.pendingCount > 0
      ? prev.pendingCount - 1
      : prev.pendingCount,
  };
}

function makeOptimistic(qc: ReturnType<typeof useQueryClient>) {
  return async (id: string): Promise<ActionContext> => {
    await qc.cancelQueries({ queryKey: queryKeys.deletionRequests.all });
    const previousLists = qc.getQueriesData<AdminDeletionRequestListResponse>({
      queryKey: queryKeys.deletionRequests.all,
    });
    qc.setQueriesData<AdminDeletionRequestListResponse>(
      { queryKey: queryKeys.deletionRequests.all },
      (prev) => dropFromList(prev, id),
    );
    return { previousLists };
  };
}

function rollback(qc: ReturnType<typeof useQueryClient>) {
  return (_err: unknown, _input: unknown, ctx: ActionContext | undefined) => {
    if (!ctx) return;
    for (const [key, snap] of ctx.previousLists) {
      qc.setQueryData(key, snap);
    }
  };
}

export function useApproveDeletion() {
  const qc = useQueryClient();
  return useMutation<AdminDeletionActionResponse, Error, { id: string }, ActionContext>({
    mutationFn: ({ id }) =>
      apiFetch(`/admin/deletion-requests/${id}/approve`, validators.adminDeletionAction, {
        method: 'POST',
      }),
    onMutate: ({ id }) => makeOptimistic(qc)(id),
    onError: rollback(qc),
    onSettled: () => {
      void qc.invalidateQueries({ queryKey: queryKeys.deletionRequests.all });
    },
  });
}

interface RejectInput {
  id: string;
  reason: string;
}

export function useRejectDeletion() {
  const qc = useQueryClient();
  return useMutation<AdminDeletionActionResponse, Error, RejectInput, ActionContext>({
    mutationFn: ({ id, reason }) =>
      apiFetch(`/admin/deletion-requests/${id}/reject`, validators.adminDeletionAction, {
        method: 'POST',
        body: { reason },
      }),
    onMutate: ({ id }) => makeOptimistic(qc)(id),
    onError: rollback(qc),
    onSettled: () => {
      void qc.invalidateQueries({ queryKey: queryKeys.deletionRequests.all });
    },
  });
}
