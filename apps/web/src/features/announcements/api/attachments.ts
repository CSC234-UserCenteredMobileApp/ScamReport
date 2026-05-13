import { useMutation, useQueryClient } from '@tanstack/react-query';
import type {
  AdminAnnouncementActionResponse,
  AdminAnnouncementAttachmentResponse,
} from '@my-product/shared';
import { apiFetch } from '@/lib/api/client';
import { uploadWithProgress } from '@/lib/api/upload';
import { validators } from '@/lib/api/validators';
import { queryKeys } from '@/lib/api/query-keys';

interface UploadInput {
  announcementId: string;
  file: File;
  onProgress?: (loaded: number, total: number) => void;
}

export function useUploadAttachment() {
  const qc = useQueryClient();
  return useMutation<AdminAnnouncementAttachmentResponse, Error, UploadInput>({
    mutationFn: ({ announcementId, file, onProgress }) => {
      const fd = new FormData();
      fd.append('file', file);
      return uploadWithProgress(
        `/admin/announcements/${announcementId}/attachments`,
        fd,
        validators.adminAnnouncementAttachment,
        { onProgress },
      );
    },
    onSuccess: (_data, { announcementId }) => {
      void qc.invalidateQueries({
        queryKey: queryKeys.announcements.detail(announcementId),
      });
    },
  });
}

interface DeleteAttachmentInput {
  announcementId: string;
  attachmentId: string;
}

export function useDeleteAttachment() {
  const qc = useQueryClient();
  return useMutation<AdminAnnouncementActionResponse, Error, DeleteAttachmentInput>({
    mutationFn: ({ announcementId, attachmentId }) =>
      apiFetch(
        `/admin/announcements/${announcementId}/attachments/${attachmentId}`,
        validators.adminAnnouncementAction,
        { method: 'DELETE' },
      ),
    onSuccess: (_data, { announcementId }) => {
      void qc.invalidateQueries({
        queryKey: queryKeys.announcements.detail(announcementId),
      });
    },
  });
}
