import { Navigate, useLocation } from 'react-router-dom';
import type { ReactNode } from 'react';
import { useAuth } from '@/lib/auth/auth-context';
import { SyncErrorScreen } from '@/lib/auth/sync-error-screen';

export function ProtectedRoute({
  role,
  children,
}: {
  role: 'admin';
  children: ReactNode;
}) {
  const { firebaseUser, role: actualRole, ready } = useAuth();
  const location = useLocation();

  if (!ready) {
    return (
      <div
        role="status"
        aria-live="polite"
        className="flex h-full items-center justify-center"
      >
        <div className="size-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
        <span className="sr-only">Loading…</span>
      </div>
    );
  }
  if (!firebaseUser) {
    return <Navigate to="/login" replace state={{ from: location }} />;
  }
  // Sync failed: firebaseUser exists but no Postgres role hydrated. Don't
  // conflate this with "not admin" — surface a retry instead of trapping
  // the user on /no-access.
  if (role === 'admin' && actualRole === null) {
    return <SyncErrorScreen />;
  }
  if (role === 'admin' && actualRole !== 'admin') {
    return <Navigate to="/no-access" replace />;
  }
  return <>{children}</>;
}
