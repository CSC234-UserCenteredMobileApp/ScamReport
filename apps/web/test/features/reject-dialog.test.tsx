import { describe, expect, it, vi } from 'vitest';
import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { RejectDialog } from '@/features/deletion-requests/components/reject-dialog';
import { renderWithProviders } from '../helpers';

describe('RejectDialog', () => {
  it('keeps submit disabled until reason has content', async () => {
    renderWithProviders(
      <RejectDialog
        open
        onOpenChange={() => undefined}
        submitting={false}
        handle="User_abc"
        onSubmit={() => undefined}
      />,
    );
    const submit = screen.getByRole('button', { name: 'Reject' });
    expect(submit).toBeDisabled();
    const user = userEvent.setup();
    await user.type(screen.getByLabelText(/Reason/i), 'Cannot verify identity.');
    expect(submit).toBeEnabled();
  });

  it('emits onSubmit with the typed reason', async () => {
    const onSubmit = vi.fn();
    renderWithProviders(
      <RejectDialog
        open
        onOpenChange={() => undefined}
        submitting={false}
        handle="User_abc"
        onSubmit={onSubmit}
      />,
    );
    const user = userEvent.setup();
    await user.type(screen.getByLabelText(/Reason/i), 'Identity unverified.');
    await user.click(screen.getByRole('button', { name: 'Reject' }));
    expect(onSubmit).toHaveBeenCalledWith('Identity unverified.');
  });

  it('cancel button fires onOpenChange(false)', async () => {
    const onOpenChange = vi.fn();
    renderWithProviders(
      <RejectDialog
        open
        onOpenChange={onOpenChange}
        submitting={false}
        handle="User_abc"
        onSubmit={() => undefined}
      />,
    );
    const user = userEvent.setup();
    await user.click(screen.getByRole('button', { name: 'Cancel' }));
    expect(onOpenChange).toHaveBeenCalledWith(false);
  });

  it('renders the live character counter', async () => {
    renderWithProviders(
      <RejectDialog
        open
        onOpenChange={() => undefined}
        submitting={false}
        handle="User_abc"
        onSubmit={() => undefined}
      />,
    );
    const user = userEvent.setup();
    await user.type(screen.getByLabelText(/Reason/i), 'Hi');
    expect(screen.getByText('2/500')).toBeInTheDocument();
  });
});
