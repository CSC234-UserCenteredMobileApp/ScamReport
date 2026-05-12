import { useQuery } from '@tanstack/react-query';
import type { AdminQueueResponse } from '@my-product/shared';
import { apiFetch } from '@/lib/api/client';
import { validators } from '@/lib/api/validators';
import { queryKeys } from '@/lib/api/query-keys';

export function buildQueuePath(scamType?: string): string {
  return scamType
    ? `/admin/reports/queue?scam_type=${encodeURIComponent(scamType)}`
    : '/admin/reports/queue';
}

export function useQueue(scamType?: string) {
  return useQuery<AdminQueueResponse>({
    queryKey: queryKeys.moderation.queue(scamType),
    queryFn: () => apiFetch(buildQueuePath(scamType), validators.adminQueue),
  });
}
