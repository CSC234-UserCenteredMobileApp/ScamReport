import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { BarList, type BarListRow } from '@/features/scam-overview/components/bar-list';

const rows: BarListRow[] = [
  { key: 'investment_fraud', primaryLabel: 'Investment fraud', secondaryLabel: 'ลงทุนหลอกลวง', count: 49 },
  { key: 'phone_impersonation', primaryLabel: 'Phone impersonation', secondaryLabel: 'แอบอ้างทางโทรศัพท์', count: 28 },
];

describe('BarList', () => {
  it('renders primary + secondary labels with counts', () => {
    render(<BarList rows={rows} emptyLabel="No data." ariaLabel="Test list" />);
    expect(screen.getByText('Investment fraud')).toBeInTheDocument();
    expect(screen.getByText('ลงทุนหลอกลวง')).toBeInTheDocument();
    expect(screen.getByText('Phone impersonation')).toBeInTheDocument();
  });

  it('omits the visible secondary label when same as primary', () => {
    const sameRows: BarListRow[] = [
      { key: 'matichon', primaryLabel: 'matichon', secondaryLabel: 'matichon', count: 100 },
    ];
    render(<BarList rows={sameRows} emptyLabel="No data." ariaLabel="Test list" />);
    expect(screen.getAllByText('matichon').length).toBeGreaterThanOrEqual(1);
  });

  it('renders empty label when rows is empty', () => {
    render(<BarList rows={[]} emptyLabel="No data." ariaLabel="Test list" />);
    expect(screen.getByText('No data.')).toBeInTheDocument();
  });

  it('largest row gets a 100% width bar', () => {
    const { container } = render(
      <BarList rows={rows} emptyLabel="No data." ariaLabel="Test list" />,
    );
    const bars = container.querySelectorAll<HTMLDivElement>(
      '.bg-primary.rounded-full.h-full',
    );
    expect(bars[0]?.style.width).toBe('100%');
    expect(bars[1]?.style.width.startsWith('57')).toBe(true);
  });

  it('exposes the list with the supplied aria-label', () => {
    render(
      <BarList rows={rows} emptyLabel="No data." ariaLabel="Top categories" />,
    );
    expect(screen.getByRole('list', { name: 'Top categories' })).toBeInTheDocument();
  });
});
