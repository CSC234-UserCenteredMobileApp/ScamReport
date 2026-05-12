import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import type { AuthUser } from '@my-product/shared';
import { ProtectedRoute } from '@/lib/auth/role-gate';

interface MockAuthState {
  firebaseUser: unknown;
  user: AuthUser | null;
  role: 'user' | 'admin' | null;
  ready: boolean;
}

let mockState: MockAuthState = {
  firebaseUser: null,
  user: null,
  role: null,
  ready: false,
};

vi.mock('@/lib/auth/auth-context', () => ({
  useAuth: () => mockState,
}));

function harness() {
  return render(
    <MemoryRouter initialEntries={['/secret']}>
      <Routes>
        <Route path="/login" element={<div>login page</div>} />
        <Route path="/no-access" element={<div>no access page</div>} />
        <Route
          path="/secret"
          element={
            <ProtectedRoute role="admin">
              <div>admin only</div>
            </ProtectedRoute>
          }
        />
      </Routes>
    </MemoryRouter>,
  );
}

describe('ProtectedRoute', () => {
  it('renders a loading splash while auth is hydrating', () => {
    mockState = { firebaseUser: null, user: null, role: null, ready: false };
    harness();
    expect(screen.getByRole('status')).toBeInTheDocument();
  });

  it('redirects to /login when ready but no firebase user', () => {
    mockState = { firebaseUser: null, user: null, role: null, ready: true };
    harness();
    expect(screen.getByText('login page')).toBeInTheDocument();
  });

  it('redirects to /no-access when authenticated but not admin', () => {
    mockState = {
      firebaseUser: { uid: 'x' },
      user: null,
      role: 'user',
      ready: true,
    };
    harness();
    expect(screen.getByText('no access page')).toBeInTheDocument();
  });

  it('renders children when authenticated and admin', () => {
    mockState = {
      firebaseUser: { uid: 'x' },
      user: null,
      role: 'admin',
      ready: true,
    };
    harness();
    expect(screen.getByText('admin only')).toBeInTheDocument();
  });
});
