import { useQuery } from '@tanstack/react-query';
import type { PlatformSummaryResponse } from '@my-product/shared';
import { apiFetch } from '@/lib/api/client';
import { validators } from '@/lib/api/validators';
import { queryKeys } from '@/lib/api/query-keys';

export function usePlatformSummary(from?: string, to?: string) {
  const params = new URLSearchParams();
  if (from) params.set('from', from);
  if (to) params.set('to', to);
  const qs = params.toString();
  const path = qs
    ? `/admin/reports/platform-summary?${qs}`
    : '/admin/reports/platform-summary';

  return useQuery<PlatformSummaryResponse>({
    queryKey: queryKeys.platformSummary.inRange(from, to),
    queryFn: () => apiFetch(path, validators.platformSummary),
  });
}
