import { useQuery } from '@tanstack/react-query';
import type {
  AdminAiEvalHistoryResponse,
  AdminAiEvalLatestResponse,
} from '@my-product/shared';
import { apiFetch } from '@/lib/api/client';
import { validators } from '@/lib/api/validators';
import { queryKeys } from '@/lib/api/query-keys';

export function useAiEvalLatest() {
  return useQuery<AdminAiEvalLatestResponse>({
    queryKey: queryKeys.aiEval.latest,
    queryFn: () => apiFetch('/admin/ai-eval/latest', validators.aiEvalLatest),
  });
}

export function useAiEvalHistory(limit = 30) {
  return useQuery<AdminAiEvalHistoryResponse>({
    queryKey: queryKeys.aiEval.history(limit),
    queryFn: () =>
      apiFetch(`/admin/ai-eval/history?limit=${limit}`, validators.aiEvalHistory),
  });
}
