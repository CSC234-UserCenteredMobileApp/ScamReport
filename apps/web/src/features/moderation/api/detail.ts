import { useQuery } from '@tanstack/react-query';
import type { AdminReportDetailResponse } from '@my-product/shared';
import { apiFetch } from '@/lib/api/client';
import { validators } from '@/lib/api/validators';
import { queryKeys } from '@/lib/api/query-keys';

export function buildDetailPath(id: string): string {
  return `/admin/reports/${id}`;
}

export function useReportDetail(id: string) {
  return useQuery<AdminReportDetailResponse>({
    queryKey: queryKeys.moderation.detail(id),
    queryFn: () => apiFetch(buildDetailPath(id), validators.adminReportDetail),
    enabled: Boolean(id),
  });
}
