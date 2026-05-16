import { useQuery } from '@tanstack/react-query';
import { apiFetch } from '@/lib/api/client';
import { queryKeys } from '@/lib/api/query-keys';
import { validators } from '@/lib/api/validators';

export function useReportSearch(q: string) {
  return useQuery({
    queryKey: queryKeys.reportSearch.results(q),
    queryFn: () =>
      apiFetch(
        `/admin/reports/search?q=${encodeURIComponent(q)}`,
        validators.adminReportSearch,
      ),
    enabled: q.trim().length >= 2,
    staleTime: 30 * 1000,
  });
}
