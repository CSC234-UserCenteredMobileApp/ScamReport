import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import type { UseQueryResult } from '@tanstack/react-query';
import type { AdminScamOverviewResponse } from '@my-product/shared';
import { ScamOverviewSection } from '@/features/scam-overview/components/scam-overview-section';
import { useScamOverview } from '@/features/scam-overview/api/scam-overview';
import i18n from '@/lib/i18n';

vi.mock('@/features/scam-overview/api/scam-overview', () => ({
  useScamOverview: vi.fn(),
}));

const mockedUse = vi.mocked(useScamOverview);

function asQueryResult(
  partial: Partial<UseQueryResult<AdminScamOverviewResponse>>,
): UseQueryResult<AdminScamOverviewResponse> {
  return partial as UseQueryResult<AdminScamOverviewResponse>;
}

const fullPayload: AdminScamOverviewResponse = {
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
  dailyReports: [
    { date: '2026-05-01', count: 10 },
    { date: '2026-05-02', count: 20 },
  ],
  generatedAt: new Date().toISOString(),
};

beforeEach(() => {
  mockedUse.mockReset();
});

describe('ScamOverviewSection', () => {
  it('shows loading state', () => {
    mockedUse.mockReturnValue(asQueryResult({ isLoading: true }));
    render(<ScamOverviewSection />);
    expect(screen.getByText(/loading/i)).toBeInTheDocument();
  });

  it('shows error state', () => {
    mockedUse.mockReturnValue(
      asQueryResult({ isError: true, data: undefined }),
    );
    render(<ScamOverviewSection />);
    expect(
      screen.getByText(/could not load scam overview/i),
    ).toBeInTheDocument();
  });

  it('renders KPI tiles + breakdowns under EN locale', async () => {
    await i18n.changeLanguage('en');
    mockedUse.mockReturnValue(asQueryResult({ data: fullPayload }));
    render(<ScamOverviewSection />);
    expect(screen.getByText('228')).toBeInTheDocument();
    expect(screen.getByText('100')).toBeInTheDocument();
    expect(screen.getByText('93')).toBeInTheDocument();
    expect(screen.getByText('Investment fraud')).toBeInTheDocument();
    expect(screen.getByText('Chiang Mai')).toBeInTheDocument();
    expect(screen.getByText('Thai')).toBeInTheDocument();
    expect(screen.getByText('Arrested')).toBeInTheDocument();
    expect(screen.getByText('matichon')).toBeInTheDocument();
  });

  it('swaps primary labels under TH locale', async () => {
    await i18n.changeLanguage('th');
    mockedUse.mockReturnValue(asQueryResult({ data: fullPayload }));
    render(<ScamOverviewSection />);
    expect(screen.getByText('ลงทุนหลอกลวง')).toBeInTheDocument();
    expect(screen.getByText('เชียงใหม่')).toBeInTheDocument();
    expect(screen.getByText('ไทย')).toBeInTheDocument();
    expect(screen.getByText('ถูกจับกุม')).toBeInTheDocument();
  });
});
