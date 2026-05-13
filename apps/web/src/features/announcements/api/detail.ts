import { useQuery } from '@tanstack/react-query';
import type { AdminAnnouncementDetailResponse } from '@my-product/shared';
import { apiFetch } from '@/lib/api/client';
import { validators } from '@/lib/api/validators';
import { queryKeys } from '@/lib/api/query-keys';

export function buildDetailPath(id: string): string {
  return `/admin/announcements/${id}`;
}

export function useAnnouncement(id: string) {
  return useQuery<AdminAnnouncementDetailResponse>({
    queryKey: queryKeys.announcements.detail(id),
    queryFn: () => apiFetch(buildDetailPath(id), validators.adminAnnouncementDetail),
    enabled: Boolean(id),
  });
}
