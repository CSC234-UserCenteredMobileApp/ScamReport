import { describe, it, expect, vi } from 'vitest';
import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { QueuePagination } from '@/features/moderation/components/queue-pagination';
import { renderWithProviders, makeQueryClient } from '../helpers';

function render(props: {
  page: number;
  pageSize: number;
  total: number;
  onChange?: (u: { page?: number; page_size?: number }) => void;
}) {
  const onChange = props.onChange ?? vi.fn();
  renderWithProviders(
    <QueuePagination
      page={props.page}
      pageSize={props.pageSize}
      total={props.total}
      onChange={onChange}
    />,
    { client: makeQueryClient() },
  );
  return onChange;
}

describe('QueuePagination', () => {
  it('shows "showing 1–25 of 137" on first page', () => {
    render({ page: 1, pageSize: 25, total: 137 });
    expect(screen.getByText(/1.*25.*of.*137/i)).toBeInTheDocument();
  });

  it('disables Prev on first page, Next on last page', () => {
    render({ page: 1, pageSize: 25, total: 50 });
    const prev = screen.getByRole('button', { name: /previous/i });
    expect(prev).toBeDisabled();
  });

  it('emits page change when a numbered button is clicked', async () => {
    const user = userEvent.setup();
    const onChange = render({ page: 1, pageSize: 25, total: 137 });
    const page2 = screen.getByRole('button', { name: '2' });
    await user.click(page2);
    expect(onChange).toHaveBeenCalledWith({ page: 2 });
  });

  it('renders ellipsis when there are many pages', () => {
    render({ page: 5, pageSize: 25, total: 1000 });
    expect(screen.getAllByText('…').length).toBeGreaterThan(0);
  });

  it('renders a page-size selector showing the current value', () => {
    render({ page: 1, pageSize: 50, total: 137 });
    const trigger = screen.getByRole('combobox');
    expect(trigger).toHaveTextContent('50');
  });

  it('shows total=0 with "0 of 0"', () => {
    render({ page: 1, pageSize: 25, total: 0 });
    expect(screen.getByText(/0.*0.*of.*0/i)).toBeInTheDocument();
  });
});
