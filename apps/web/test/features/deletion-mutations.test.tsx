import { describe, expect, it, vi } from 'vitest';
import type { ReactNode } from 'react';
import { http, HttpResponse } from 'msw';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { renderHook, waitFor } from '@testing-library/react';
import {
  useApproveDeletion,
  useRejectDeletion,
} from '@/features/deletion-requests/api/mutations';
import { firebaseAuth } from '@/lib/auth/firebase';
import { server } from '../mocks/server';
import { samplePendingDeletion } from '../mocks/handlers';

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

describe('deletion mutations', () => {
  it('useApproveDeletion calls the approve endpoint', async () => {
    const { result } = renderHook(() => useApproveDeletion(), { wrapper: wrapper() });
    const data = await result.current.mutateAsync({ id: samplePendingDeletion.id });
    await waitFor(() => expect(data.status).toBe('approved'));
  });

  it('useRejectDeletion forwards the reason body', async () => {
    let bodyReason: string | null = null;
    server.use(
      http.post(`*/admin/deletion-requests/${samplePendingDeletion.id}/reject`, async ({ request }) => {
        const body = (await request.json()) as { reason: string };
        bodyReason = body.reason;
        return HttpResponse.json({
          id: samplePendingDeletion.id,
          status: 'rejected',
          reviewedAt: new Date().toISOString(),
        });
      }),
    );
    const { result } = renderHook(() => useRejectDeletion(), { wrapper: wrapper() });
    await result.current.mutateAsync({
      id: samplePendingDeletion.id,
      reason: 'Identity verification failed.',
    });
    await waitFor(() => expect(bodyReason).toBe('Identity verification failed.'));
  });

  it('useApproveDeletion surfaces 409 already-reviewed errors', async () => {
    server.use(
      http.post(`*/admin/deletion-requests/${samplePendingDeletion.id}/approve`, () =>
        HttpResponse.json({ error: 'Already reviewed' }, { status: 409 }),
      ),
    );
    const { result } = renderHook(() => useApproveDeletion(), { wrapper: wrapper() });
    await expect(
      result.current.mutateAsync({ id: samplePendingDeletion.id }),
    ).rejects.toMatchObject({ status: 409 });
  });
});
