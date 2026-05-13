import { describe, expect, it, vi } from 'vitest';
import { http, HttpResponse } from 'msw';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { renderHook, waitFor } from '@testing-library/react';
import type { ReactNode } from 'react';
import {
  useDeleteAnnouncement,
  usePublishAnnouncement,
  useUnpublishAnnouncement,
  useUpdateAnnouncement,
} from '@/features/announcements/api/mutations';
import { useDeleteAttachment } from '@/features/announcements/api/attachments';
import { firebaseAuth } from '@/lib/auth/firebase';
import { server } from '../mocks/server';
import { sampleAnnouncementDraft } from '../mocks/handlers';

Object.defineProperty(firebaseAuth, 'currentUser', {
  configurable: true,
  get: () => ({ getIdToken: vi.fn(async () => 'tok') }),
});

function wrapper() {
  const qc = new QueryClient({
    defaultOptions: {
      queries: { retry: false, gcTime: 0, staleTime: 0 },
      mutations: { retry: false },
    },
  });
  return ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={qc}>{children}</QueryClientProvider>
  );
}

describe('announcement mutations', () => {
  it('useUpdateAnnouncement resolves with the announcement detail', async () => {
    const { result } = renderHook(() => useUpdateAnnouncement(), { wrapper: wrapper() });
    const data = await result.current.mutateAsync({
      id: sampleAnnouncementDraft.id,
      body: { title: 'Renamed' },
    });
    expect(data.item.id).toBe(sampleAnnouncementDraft.id);
  });

  it('usePublishAnnouncement resolves with the published item', async () => {
    const { result } = renderHook(() => usePublishAnnouncement(), { wrapper: wrapper() });
    const data = await result.current.mutateAsync({
      id: sampleAnnouncementDraft.id,
      body: { pushToFcm: false },
    });
    expect(data.item.status).toBe('published');
  });

  it('useUnpublishAnnouncement returns the action receipt', async () => {
    const { result } = renderHook(() => useUnpublishAnnouncement(), { wrapper: wrapper() });
    const data = await result.current.mutateAsync({ id: sampleAnnouncementDraft.id });
    expect(data.id).toBe(sampleAnnouncementDraft.id);
  });

  it('useDeleteAnnouncement returns the action receipt', async () => {
    const { result } = renderHook(() => useDeleteAnnouncement(), { wrapper: wrapper() });
    const data = await result.current.mutateAsync({ id: sampleAnnouncementDraft.id });
    expect(data.status).toBe('deleted');
  });

  it('useDeleteAttachment hits the DELETE attachment endpoint', async () => {
    const attachmentId = '55555555-5555-5555-5555-555555555555';
    server.use(
      http.delete(
        `*/admin/announcements/${sampleAnnouncementDraft.id}/attachments/${attachmentId}`,
        () =>
          HttpResponse.json({
            id: attachmentId,
            status: 'deleted',
            updatedAt: new Date().toISOString(),
          }),
      ),
    );
    const { result } = renderHook(() => useDeleteAttachment(), { wrapper: wrapper() });
    const data = await result.current.mutateAsync({
      announcementId: sampleAnnouncementDraft.id,
      attachmentId,
    });
    await waitFor(() => expect(data.status).toBe('deleted'));
  });
});
