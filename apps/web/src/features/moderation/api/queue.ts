import { useQuery, keepPreviousData } from '@tanstack/react-query';
import type { AdminQueueResponse } from '@my-product/shared';
import { apiFetch } from '@/lib/api/client';
import { validators } from '@/lib/api/validators';
import { queryKeys } from '@/lib/api/query-keys';

export interface QueueParams {
  q?: string;
  status?: 'pending' | 'flagged' | 'all';
  priority?: 'true' | 'false';
  confidence?: 'high' | 'medium' | 'low' | 'all';
  scam_type?: string;
  page: number;
  page_size: number;
}

export function buildQueuePath(p: QueueParams): string {
  const sp = new URLSearchParams();
  if (p.q) sp.set('q', p.q);
  if (p.status && p.status !== 'all') sp.set('status', p.status);
  if (p.priority) sp.set('priority', p.priority);
  if (p.confidence && p.confidence !== 'all') sp.set('confidence', p.confidence);
  if (p.scam_type) sp.set('scam_type', p.scam_type);
  if (p.page > 1) sp.set('page', String(p.page));
  if (p.page_size !== 25) sp.set('page_size', String(p.page_size));
  const qs = sp.toString();
  return qs ? `/admin/reports/queue?${qs}` : '/admin/reports/queue';
}

export function useQueue(params: QueueParams) {
  return useQuery<AdminQueueResponse>({
    queryKey: queryKeys.moderation.queue(params),
    queryFn: () => apiFetch(buildQueuePath(params), validators.adminQueue),
    placeholderData: keepPreviousData,
  });
}
