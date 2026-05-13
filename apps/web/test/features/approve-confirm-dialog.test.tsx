import { describe, expect, it, vi } from 'vitest';
import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ApproveConfirmDialog } from '@/features/deletion-requests/components/approve-confirm-dialog';
import { renderWithProviders } from '../helpers';

describe('ApproveConfirmDialog', () => {
  it('renders the destructive warning and the masked handle', () => {
    renderWithProviders(
      <ApproveConfirmDialog
        open
        onOpenChange={() => undefined}
        submitting={false}
        handle="User_5a8c1f0e"
        onConfirm={() => undefined}
      />,
    );
    expect(screen.getByText('User_5a8c1f0e')).toBeInTheDocument();
    expect(
      screen.getByText(/purges data after 7 days/i),
    ).toBeInTheDocument();
  });

  it('confirm button is destructive variant and fires onConfirm', async () => {
    const onConfirm = vi.fn();
    renderWithProviders(
      <ApproveConfirmDialog
        open
        onOpenChange={() => undefined}
        submitting={false}
        handle="User_5a8c1f0e"
        onConfirm={onConfirm}
      />,
    );
    const user = userEvent.setup();
    await user.click(screen.getByRole('button', { name: 'Approve deletion' }));
    expect(onConfirm).toHaveBeenCalledTimes(1);
  });

  it('cancel button fires onOpenChange(false)', async () => {
    const onOpenChange = vi.fn();
    renderWithProviders(
      <ApproveConfirmDialog
        open
        onOpenChange={onOpenChange}
        submitting={false}
        handle="User_abc"
        onConfirm={() => undefined}
      />,
    );
    const user = userEvent.setup();
    await user.click(screen.getByRole('button', { name: 'Cancel' }));
    expect(onOpenChange).toHaveBeenCalledWith(false);
  });

  it('disables both buttons while submitting', () => {
    renderWithProviders(
      <ApproveConfirmDialog
        open
        onOpenChange={() => undefined}
        submitting
        handle="User_abc"
        onConfirm={() => undefined}
      />,
    );
    expect(screen.getByRole('button', { name: 'Cancel' })).toBeDisabled();
    expect(
      screen.getByRole('button', { name: 'Approve deletion' }),
    ).toBeDisabled();
  });
});
