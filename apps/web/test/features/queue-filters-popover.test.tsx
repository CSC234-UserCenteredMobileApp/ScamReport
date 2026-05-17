import { describe, it, expect, vi } from 'vitest';
import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import type { ScamTypeItem } from '@my-product/shared';
import { QueueFiltersPopover } from '@/features/moderation/components/queue-filters-popover';
import type { QueueSearch } from '@/features/moderation/pages/queue-page';
import { renderWithProviders, makeQueryClient } from '../helpers';

const scamTypes: ScamTypeItem[] = [
  { code: 'phishing_sms', labelEn: 'Phishing SMS', labelTh: 'ฟิชชิ่ง SMS', displayOrder: 1 },
];

function render(initial: QueueSearch = {}, onChange = vi.fn()) {
  renderWithProviders(
    <QueueFiltersPopover
      search={initial}
      scamTypes={scamTypes}
      onChange={onChange}
    />,
    { client: makeQueryClient() },
  );
  return onChange;
}

describe('QueueFiltersPopover', () => {
  it('renders all four filter groups', () => {
    render();
    expect(screen.getByText(/^status$/i)).toBeInTheDocument();
    expect(screen.getByText(/priority only/i)).toBeInTheDocument();
    expect(screen.getByText(/ai confidence/i)).toBeInTheDocument();
    expect(screen.getByText(/scam type/i)).toBeInTheDocument();
  });

  it('reflects priority checkbox state from search prop', () => {
    render({ priority: 'true' });
    const cb = screen.getByLabelText(/priority only/i);
    expect(cb).toBeChecked();
  });

  it('toggles priority via the checkbox', async () => {
    const user = userEvent.setup();
    const onChange = render({});
    const cb = screen.getByLabelText(/priority only/i);
    await user.click(cb);
    expect(onChange).toHaveBeenCalledWith({ priority: 'true' });
  });

  it('Reset clears all four filter fields', async () => {
    const user = userEvent.setup();
    const onChange = render({
      status: 'flagged',
      priority: 'true',
      confidence: 'high',
      scam_type: 'phishing_sms',
    });
    const reset = screen.getByRole('button', { name: /reset/i });
    await user.click(reset);
    expect(onChange).toHaveBeenCalledWith({
      status: undefined,
      priority: undefined,
      confidence: undefined,
      scam_type: undefined,
    });
  });

  it('changing status Select emits onChange', async () => {
    const user = userEvent.setup();
    const onChange = render({});
    // Status is the first combobox (Selects in order: status, confidence, scam_type)
    const triggers = screen.getAllByRole('combobox');
    await user.click(triggers[0]!);
    const opt = await screen.findByRole('option', { name: /^flagged$/i });
    await user.click(opt);
    expect(onChange).toHaveBeenCalledWith({ status: 'flagged' });
  });

  it('changing confidence Select emits onChange', async () => {
    const user = userEvent.setup();
    const onChange = render({});
    const triggers = screen.getAllByRole('combobox');
    await user.click(triggers[1]!);
    const opt = await screen.findByRole('option', { name: /^high$/i });
    await user.click(opt);
    expect(onChange).toHaveBeenCalledWith({ confidence: 'high' });
  });

  it('changing scam-type Select to a code emits onChange with that code', async () => {
    const user = userEvent.setup();
    const onChange = render({});
    const triggers = screen.getAllByRole('combobox');
    await user.click(triggers[2]!);
    const opt = await screen.findByRole('option', { name: /phishing sms/i });
    await user.click(opt);
    expect(onChange).toHaveBeenCalledWith({ scam_type: 'phishing_sms' });
  });

  it('selecting "all" scam type clears the filter', async () => {
    const user = userEvent.setup();
    const onChange = render({ scam_type: 'phishing_sms' });
    const triggers = screen.getAllByRole('combobox');
    await user.click(triggers[2]!);
    const opt = await screen.findByRole('option', { name: /^all$/i });
    await user.click(opt);
    expect(onChange).toHaveBeenCalledWith({ scam_type: undefined });
  });
});
