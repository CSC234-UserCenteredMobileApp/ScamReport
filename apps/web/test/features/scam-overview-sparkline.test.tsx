import { describe, it, expect } from 'vitest';
import { render } from '@testing-library/react';
import { Sparkline } from '@/features/scam-overview/components/sparkline';

describe('Sparkline', () => {
  it('renders nothing when daily is empty', () => {
    const { container } = render(<Sparkline daily={[]} title="Daily" />);
    expect(container.querySelector('svg')).toBeNull();
  });

  it('renders the line path and one circle per bucket', () => {
    const { container } = render(
      <Sparkline
        title="Daily"
        daily={[
          { date: '2026-05-01', count: 3 },
          { date: '2026-05-02', count: 7 },
          { date: '2026-05-03', count: 5 },
        ]}
      />,
    );
    const paths = container.querySelectorAll('path');
    expect(paths.length).toBeGreaterThanOrEqual(1);
    expect(container.querySelectorAll('circle')).toHaveLength(3);
  });

  it('exposes a screen-reader data table mirroring the series', () => {
    const { container } = render(
      <Sparkline
        title="Daily reports"
        daily={[
          { date: '2026-05-01', count: 3 },
          { date: '2026-05-02', count: 7 },
        ]}
      />,
    );
    const srTable = container.querySelector('table.sr-only');
    expect(srTable).not.toBeNull();
    expect(srTable?.textContent).toContain('2026-05-01');
    expect(srTable?.textContent).toContain('7');
  });

  it('renders one focusable hover target per bucket', () => {
    const { container } = render(
      <Sparkline
        title="Daily"
        daily={[
          { date: '2026-05-01', count: 3 },
          { date: '2026-05-02', count: 7 },
          { date: '2026-05-03', count: 5 },
        ]}
      />,
    );
    const targets = container.querySelectorAll('button[aria-label]');
    expect(targets.length).toBe(3);
  });
});
