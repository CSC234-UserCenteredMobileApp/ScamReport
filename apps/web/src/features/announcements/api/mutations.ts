import { useMutation, useQueryClient } from '@tanstack/react-query';
import type {
  AdminAnnouncementActionResponse,
  AdminAnnouncementDetailResponse,
  CreateAnnouncementRequest,
  PublishAnnouncementRequest,
  UpdateAnnouncementRequest,
} from '@my-product/shared';
import { apiFetch } from '@/lib/api/client';
import { validators } from '@/lib/api/validators';
import { queryKeys } from '@/lib/api/query-keys';

export function useCreateAnnouncement() {
  const qc = useQueryClient();
  return useMutation<AdminAnnouncementDetailResponse, Error, CreateAnnouncementRequest>({
    mutationFn: (body) =>
      apiFetch('/admin/announcements', validators.adminAnnouncementDetail, {
        method: 'POST',
        body,
      }),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: queryKeys.announcements.all });
    },
  });
}

interface UpdateInput {
  id: string;
  body: UpdateAnnouncementRequest;
}

export function useUpdateAnnouncement() {
  const qc = useQueryClient();
  return useMutation<AdminAnnouncementDetailResponse, Error, UpdateInput>({
    mutationFn: ({ id, body }) =>
      apiFetch(`/admin/announcements/${id}`, validators.adminAnnouncementDetail, {
        method: 'PUT',
        body,
      }),
    onSuccess: (_data, { id }) => {
      void qc.invalidateQueries({ queryKey: queryKeys.announcements.list });
      void qc.invalidateQueries({ queryKey: queryKeys.announcements.detail(id) });
    },
  });
}

interface PublishInput {
  id: string;
  body: PublishAnnouncementRequest;
}

export function usePublishAnnouncement() {
  const qc = useQueryClient();
  return useMutation<AdminAnnouncementDetailResponse, Error, PublishInput>({
    mutationFn: ({ id, body }) =>
      apiFetch(`/admin/announcements/${id}/publish`, validators.adminAnnouncementDetail, {
        method: 'POST',
        body,
      }),
    onSuccess: (_data, { id }) => {
      void qc.invalidateQueries({ queryKey: queryKeys.announcements.list });
      void qc.invalidateQueries({ queryKey: queryKeys.announcements.detail(id) });
    },
  });
}

export function useUnpublishAnnouncement() {
  const qc = useQueryClient();
  return useMutation<AdminAnnouncementActionResponse, Error, { id: string }>({
    mutationFn: ({ id }) =>
      apiFetch(`/admin/announcements/${id}/unpublish`, validators.adminAnnouncementAction, {
        method: 'POST',
      }),
    onSuccess: (_data, { id }) => {
      void qc.invalidateQueries({ queryKey: queryKeys.announcements.list });
      void qc.invalidateQueries({ queryKey: queryKeys.announcements.detail(id) });
    },
  });
}

export function useDeleteAnnouncement() {
  const qc = useQueryClient();
  return useMutation<AdminAnnouncementActionResponse, Error, { id: string }>({
    mutationFn: ({ id }) =>
      apiFetch(`/admin/announcements/${id}`, validators.adminAnnouncementAction, {
        method: 'DELETE',
      }),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: queryKeys.announcements.all });
    },
  });
}
