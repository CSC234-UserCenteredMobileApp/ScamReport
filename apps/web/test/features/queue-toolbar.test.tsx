import { describe, it, expect, vi } from 'vitest';
import { screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import type { ScamTypeItem } from '@my-product/shared';
import { QueueToolbar } from '@/features/moderation/components/queue-toolbar';
import type { QueueSearch } from '@/features/moderation/pages/queue-page';
import { renderWithProviders, makeQueryClient } from '../helpers';

const scamTypes: ScamTypeItem[] = [
  { code: 'phishing_sms', labelEn: 'Phishing SMS', labelTh: 'ฟิชชิ่ง SMS', displayOrder: 1 },
];

function render(initial: QueueSearch = {}, onChange = vi.fn()) {
  renderWithProviders(
    <QueueToolbar search={initial} scamTypes={scamTypes} onChange={onChange} />,
    { client: makeQueryClient() },
  );
  return onChange;
}

describe('QueueToolbar', () => {
  it('renders search input + filters button', () => {
    render();
    expect(screen.getByPlaceholderText(/search title/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /filters/i })).toBeInTheDocument();
  });

  it('shows active filter count badge when filters are set', () => {
    render({ status: 'flagged', priority: 'true' });
    const btn = screen.getByRole('button', { name: /filters/i });
    expect(btn).toHaveTextContent('2');
  });

  it('renders chips for confidence + scam_type filters', () => {
    render({ confidence: 'high', scam_type: 'phishing_sms' });
    // Confidence chip: includes the localized confidence label
    expect(screen.getByText(/ai confidence/i, { selector: '.gap-1' })).toBeInTheDocument();
    // Scam type chip: includes the resolved scam-type label
    expect(screen.getByText(/scam type/i, { selector: '.gap-1' })).toBeInTheDocument();
  });

  it('falls back to the raw code when scam type is unknown', () => {
    render({ scam_type: 'unknown_code' });
    expect(
      screen.getByText(/scam type: unknown_code/i, { selector: '.gap-1' }),
    ).toBeInTheDocument();
  });

  it('renders chips for each active filter and removes them on X click', async () => {
    const user = userEvent.setup();
    const onChange = render({ status: 'flagged' });
    const chip = screen.getByText(/flagged/i, { selector: '.gap-1' });
    expect(chip).toBeInTheDocument();
    const removeBtn = screen.getByLabelText(/remove/i);
    await user.click(removeBtn);
    expect(onChange).toHaveBeenCalledWith({ status: undefined });
  });

  it('Clear all wipes every filter and the search input', async () => {
    const user = userEvent.setup();
    const onChange = render({ status: 'flagged', priority: 'true', q: 'foo' });
    const clearBtn = screen.getByRole('button', { name: /clear all/i });
    await user.click(clearBtn);
    expect(onChange).toHaveBeenCalledWith({
      q: undefined,
      status: undefined,
      priority: undefined,
      confidence: undefined,
      scam_type: undefined,
    });
  });

  it('commits debounced search to URL via onChange after typing', async () => {
    const onChange = vi.fn();
    renderWithProviders(
      <QueueToolbar search={{}} scamTypes={scamTypes} onChange={onChange} />,
      { client: makeQueryClient() },
    );
    const input = screen.getByPlaceholderText(/search title/i);
    fireEvent.change(input, { target: { value: 'phish' } });
    // Immediately after typing, commit hasn't fired yet (debounce window).
    expect(onChange).not.toHaveBeenCalled();
    await waitFor(
      () =>
        expect(onChange).toHaveBeenCalledWith({ q: 'phish' }, { replace: true }),
      { timeout: 1000 },
    );
  });
});
