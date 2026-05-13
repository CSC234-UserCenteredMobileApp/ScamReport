import { useQuery } from '@tanstack/react-query';
import type { AdminEvidenceUrlResponse } from '@my-product/shared';
import { apiFetch } from '@/lib/api/client';
import { validators } from '@/lib/api/validators';
import { queryKeys } from '@/lib/api/query-keys';

// Server signs the URL for 1h. Keep the client cache slightly under the TTL
// so we don't ever hand a stale URL to a thumb that's about to render.
const FIFTY_MINUTES_MS = 50 * 60 * 1000;

export function buildEvidenceUrlPath(reportId: string, fileId: string): string {
  return `/admin/reports/${reportId}/evidence/${fileId}/url`;
}

export function useEvidenceUrl(reportId: string, fileId: string) {
  return useQuery<AdminEvidenceUrlResponse>({
    queryKey: queryKeys.moderation.evidenceUrl(reportId, fileId),
    queryFn: () =>
      apiFetch(buildEvidenceUrlPath(reportId, fileId), validators.adminEvidenceUrl),
    enabled: Boolean(reportId) && Boolean(fileId),
    staleTime: FIFTY_MINUTES_MS,
    gcTime: FIFTY_MINUTES_MS,
  });
}
