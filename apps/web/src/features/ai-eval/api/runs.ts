import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import type { AiEvalListResponse, AiEvalRunResponse } from '@my-product/shared';
import { apiFetch } from '@/lib/api/client';
import { validators } from '@/lib/api/validators';
import { queryKeys } from '@/lib/api/query-keys';

export function useEvalRuns() {
  return useQuery<AiEvalListResponse>({
    queryKey: queryKeys.aiEval.runs,
    queryFn: () => apiFetch('/admin/ai-eval/runs?limit=20', validators.aiEvalList),
  });
}

export function useRunEvaluation() {
  const qc = useQueryClient();
  return useMutation<AiEvalRunResponse>({
    mutationFn: () =>
      apiFetch('/admin/ai-eval/run', validators.aiEvalRun, { method: 'POST' }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: queryKeys.aiEval.runs });
      qc.invalidateQueries({ queryKey: queryKeys.platformSummary.all });
    },
  });
}
