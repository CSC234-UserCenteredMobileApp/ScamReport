import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { Sparkline } from '@/features/scam-overview/components/sparkline';

describe('Sparkline', () => {
  it('renders nothing when daily is empty', () => {
    const { container } = render(<Sparkline daily={[]} />);
    expect(container.querySelector('svg')).toBeNull();
  });

  it('renders an SVG path with one segment per bucket', () => {
    const { container } = render(
      <Sparkline
        daily={[
          { date: '2026-05-01', count: 3 },
          { date: '2026-05-02', count: 7 },
          { date: '2026-05-03', count: 5 },
        ]}
      />,
    );
    const path = container.querySelector('path');
    expect(path).not.toBeNull();
    expect(path?.getAttribute('d')?.startsWith('M ')).toBe(true);
    expect(container.querySelectorAll('circle')).toHaveLength(3);
    expect(screen.getByText('2026-05-01')).toBeInTheDocument();
    expect(screen.getByText('2026-05-03')).toBeInTheDocument();
    expect(screen.getByText('peak 7/day')).toBeInTheDocument();
  });
});
