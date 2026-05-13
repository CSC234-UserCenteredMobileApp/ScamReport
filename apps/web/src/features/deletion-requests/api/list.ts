import { useQuery } from '@tanstack/react-query';
import type {
  AdminDeletionRequestListResponse,
  DeletionRequestStatus,
} from '@my-product/shared';
import { apiFetch } from '@/lib/api/client';
import { validators } from '@/lib/api/validators';
import { queryKeys } from '@/lib/api/query-keys';

export function buildListPath(status?: DeletionRequestStatus): string {
  return status ? `/admin/deletion-requests?status=${status}` : '/admin/deletion-requests';
}

export function useDeletionRequests(status?: DeletionRequestStatus) {
  return useQuery<AdminDeletionRequestListResponse>({
    queryKey: queryKeys.deletionRequests.list(status),
    queryFn: () => apiFetch(buildListPath(status), validators.adminDeletionList),
  });
}
