import { describe, it, expect, vi, beforeEach } from 'vitest';
import { http, HttpResponse } from 'msw';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { renderHook, waitFor } from '@testing-library/react';
import type { ReactNode } from 'react';
import { server } from '../mocks/server';
import { useScamOverview } from '@/features/scam-overview/api/scam-overview';
import { firebaseAuth } from '@/lib/auth/firebase';

Object.defineProperty(firebaseAuth, 'currentUser', {
  configurable: true,
  get: () => ({ getIdToken: vi.fn(async () => 'tok') }),
});

function wrapperFor(qc: QueryClient) {
  return ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={qc}>{children}</QueryClientProvider>
  );
}

beforeEach(() => {
  vi.clearAllMocks();
});

const baseUrl = 'http://localhost:3000';

const samplePayload = {
  totalReports: 228,
  totalScammers: 100,
  totalPersons: 93,
  byScamType: [
    { code: 'investment_fraud', labelEn: 'Investment fraud', labelTh: 'ลงทุนหลอกลวง', count: 49 },
  ],
  bySourceSite: [{ site: 'matichon', count: 80 }],
  byProvince: [{ thai: 'เชียงใหม่', english: 'Chiang Mai', count: 12 }],
  byNationality: [{ english: 'Thai', thai: 'ไทย', count: 130 }],
  byArrestStatus: [
    { code: 'arrested', labelEn: 'Arrested', labelTh: 'ถูกจับกุม', count: 90 },
  ],
  sourceSiteTotal: 120,
  provinceTotal: 40,
  nationalityTotal: 150,
  arrestStatusTotal: 100,
  dailyReports: [{ date: '2026-05-02', count: 141 }],
  generatedAt: new Date().toISOString(),
};

describe('useScamOverview', () => {
  it('fetches and returns the scam-overview payload', async () => {
    server.use(
      http.get(`${baseUrl}/admin/scam-overview`, () =>
        HttpResponse.json(samplePayload),
      ),
    );

    const qc = new QueryClient({
      defaultOptions: { queries: { retry: false } },
    });
    const { result } = renderHook(() => useScamOverview(), {
      wrapper: wrapperFor(qc),
    });

    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(result.current.data?.totalReports).toBe(228);
    expect(result.current.data?.byScamType[0]?.code).toBe('investment_fraud');
    expect(result.current.data?.byProvince[0]?.thai).toBe('เชียงใหม่');
  });
});
