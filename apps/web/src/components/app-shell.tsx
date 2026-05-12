import { Outlet } from 'react-router-dom';
import { Sidebar } from '@/components/sidebar';
import { Topbar } from '@/components/topbar';

export function AppShell() {
  return (
    <div className="flex h-full w-full">
      <aside className="hidden h-full md:block">
        <Sidebar />
      </aside>
      <div className="flex h-full flex-1 flex-col overflow-hidden">
        <Topbar />
        <main className="flex-1 overflow-y-auto bg-background p-6 md:p-8">
          <div className="mx-auto max-w-7xl">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
}
