import { useQuery } from '@tanstack/react-query';
import type { AdminAnnouncementListResponse } from '@my-product/shared';
import { apiFetch } from '@/lib/api/client';
import { validators } from '@/lib/api/validators';
import { queryKeys } from '@/lib/api/query-keys';

export function useAnnouncements() {
  return useQuery<AdminAnnouncementListResponse>({
    queryKey: queryKeys.announcements.list,
    queryFn: () => apiFetch('/admin/announcements', validators.adminAnnouncementList),
  });
}
