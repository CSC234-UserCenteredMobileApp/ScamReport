import { describe, it, expect, vi, beforeEach } from 'vitest';
import { act, renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import type { ReactNode } from 'react';
import type * as FirebaseAuthModule from 'firebase/auth';
import { http, HttpResponse } from 'msw';
import { server } from '../mocks/server';
import { userSyncResponse } from '../mocks/handlers';

const onAuthStateChangedMock = vi.fn();
const signInEmailMock = vi.fn(async () => undefined);
const signOutMock = vi.fn(async () => undefined);

vi.mock('firebase/auth', async () => {
  const actual = await vi.importActual<typeof FirebaseAuthModule>('firebase/auth');
  return {
    ...actual,
    onAuthStateChanged: (...args: unknown[]) => onAuthStateChangedMock(...args),
    signInWithEmailAndPassword: () => signInEmailMock(),
    signOut: () => signOutMock(),
  };
});

vi.mock('@/lib/auth/firebase', () => ({
  firebaseApp: {},
  firebaseAuth: {
    currentUser: null,
    signOut: () => signOutMock(),
  },
}));

import { AuthProvider, useAuth } from '@/lib/auth/auth-context';

function wrapper({ children }: { children: ReactNode }) {
  const qc = new QueryClient();
  return (
    <QueryClientProvider client={qc}>
      <AuthProvider>{children}</AuthProvider>
    </QueryClientProvider>
  );
}

beforeEach(() => {
  onAuthStateChangedMock.mockReset();
  signOutMock.mockReset();
  signInEmailMock.mockReset();
});

describe('AuthProvider', () => {
  it('starts with ready=false until onAuthStateChanged fires', async () => {
    let fire: ((fb: unknown) => void) | null = null;
    onAuthStateChangedMock.mockImplementation((_auth, cb: (fb: unknown) => void) => {
      fire = cb;
      return () => undefined;
    });
    const { result } = renderHook(() => useAuth(), { wrapper });
    expect(result.current.ready).toBe(false);
    await act(async () => {
      fire?.(null);
    });
    await waitFor(() => expect(result.current.ready).toBe(true));
    expect(result.current.firebaseUser).toBeNull();
    expect(result.current.role).toBeNull();
  });

  it('resolves role from /auth/sync after firebase user appears', async () => {
    server.use(http.post('*/auth/sync', () => HttpResponse.json(userSyncResponse)));
    let fire: ((fb: unknown) => void) | null = null;
    onAuthStateChangedMock.mockImplementation((_auth, cb: (fb: unknown) => void) => {
      fire = cb;
      return () => undefined;
    });
    const { result } = renderHook(() => useAuth(), { wrapper });
    await act(async () => {
      fire?.({ uid: 'fb-uid' });
    });
    await waitFor(() => expect(result.current.ready).toBe(true));
    expect(result.current.user?.role).toBe('user');
    expect(result.current.role).toBe('user');
  });

  it('clears the user when /auth/sync returns 401', async () => {
    server.use(http.post('*/auth/sync', () => new HttpResponse(null, { status: 401 })));
    let fire: ((fb: unknown) => void) | null = null;
    onAuthStateChangedMock.mockImplementation((_auth, cb: (fb: unknown) => void) => {
      fire = cb;
      return () => undefined;
    });
    const { result } = renderHook(() => useAuth(), { wrapper });
    await act(async () => {
      fire?.({ uid: 'fb-uid' });
    });
    await waitFor(() => expect(result.current.ready).toBe(true));
    expect(result.current.user).toBeNull();
  });

  it('signIn helpers delegate to Firebase SDK', async () => {
    onAuthStateChangedMock.mockImplementation((_auth, cb: (fb: unknown) => void) => {
      cb(null);
      return () => undefined;
    });
    const { result } = renderHook(() => useAuth(), { wrapper });
    await waitFor(() => expect(result.current.ready).toBe(true));
    await act(async () => {
      await result.current.signInWithEmail('a@b.com', 'pw');
      await result.current.signOut();
    });
    expect(signInEmailMock).toHaveBeenCalledOnce();
    expect(signOutMock).toHaveBeenCalledOnce();
  });
});
