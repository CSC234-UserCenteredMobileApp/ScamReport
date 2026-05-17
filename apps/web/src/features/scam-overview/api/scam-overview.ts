import { useQuery } from '@tanstack/react-query';
import type { AdminScamOverviewResponse } from '@my-product/shared';
import { apiFetch } from '@/lib/api/client';
import { validators } from '@/lib/api/validators';
import { queryKeys } from '@/lib/api/query-keys';

export function useScamOverview() {
  return useQuery<AdminScamOverviewResponse>({
    queryKey: queryKeys.scamOverview.all,
    queryFn: () => apiFetch('/admin/scam-overview', validators.scamOverview),
  });
}
