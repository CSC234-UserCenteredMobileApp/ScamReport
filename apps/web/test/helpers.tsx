import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter } from 'react-router-dom';
import type { ReactElement, ReactNode } from 'react';
import { render, type RenderOptions } from '@testing-library/react';

export function makeQueryClient(): QueryClient {
  return new QueryClient({
    defaultOptions: {
      queries: { retry: false, gcTime: 0, staleTime: 0 },
      mutations: { retry: false },
    },
  });
}

interface ProvidersProps {
  children: ReactNode;
  client?: QueryClient;
  initialRoute?: string;
}

export function TestProviders({ children, client, initialRoute = '/' }: ProvidersProps) {
  const qc = client ?? makeQueryClient();
  return (
    <QueryClientProvider client={qc}>
      <MemoryRouter initialEntries={[initialRoute]}>{children}</MemoryRouter>
    </QueryClientProvider>
  );
}

export function renderWithProviders(
  ui: ReactElement,
  opts: { client?: QueryClient; initialRoute?: string } & Omit<RenderOptions, 'wrapper'> = {},
) {
  const { client, initialRoute, ...rest } = opts;
  return render(ui, {
    wrapper: ({ children }) => (
      <TestProviders client={client} initialRoute={initialRoute}>
        {children}
      </TestProviders>
    ),
    ...rest,
  });
}
