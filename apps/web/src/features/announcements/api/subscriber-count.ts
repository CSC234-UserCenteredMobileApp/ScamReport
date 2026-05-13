import { useQuery } from '@tanstack/react-query';
import type { SubscriberCountResponse } from '@my-product/shared';
import { apiFetch } from '@/lib/api/client';
import { validators } from '@/lib/api/validators';
import { queryKeys } from '@/lib/api/query-keys';

// Drives the "Send push to ~N users?" confirmation copy in the editor.
// 60s staleTime is generous — the number rarely shifts within a single
// editing session and freshness is not load-bearing.
const ONE_MINUTE_MS = 60_000;

export function useSubscriberCount() {
  return useQuery<SubscriberCountResponse>({
    queryKey: queryKeys.notifications.subscriberCount,
    queryFn: () =>
      apiFetch('/admin/notifications/subscribers/count', validators.subscriberCount),
    staleTime: ONE_MINUTE_MS,
  });
}
