import { AppShell } from '@/components/app-shell';
import { ProtectedRoute } from '@/lib/auth/role-gate';

export function DashboardLayout() {
  return (
    <ProtectedRoute role="admin">
      <AppShell />
    </ProtectedRoute>
  );
}
