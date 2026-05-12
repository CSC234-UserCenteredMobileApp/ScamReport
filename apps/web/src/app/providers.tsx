import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useState, type ReactNode } from 'react';
import { Toaster } from 'sonner';
import { AuthProvider } from '@/lib/auth/auth-context';
import { ThemeProvider } from '@/app/theme-provider';
import '@/lib/i18n';

export function AppProviders({ children }: { children: ReactNode }) {
  const [client] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 30_000,
            refetchOnWindowFocus: false,
            retry: 1,
          },
          mutations: { retry: 0 },
        },
      }),
  );
  return (
    <QueryClientProvider client={client}>
      <ThemeProvider>
        <AuthProvider>
          {children}
          <Toaster richColors closeButton position="bottom-right" />
        </AuthProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
}
