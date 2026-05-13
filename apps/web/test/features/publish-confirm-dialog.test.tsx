import { describe, expect, it, vi } from 'vitest';
import { http, HttpResponse } from 'msw';
import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { PublishConfirmDialog } from '@/features/announcements/components/publish-confirm-dialog';
import { firebaseAuth } from '@/lib/auth/firebase';
import { renderWithProviders } from '../helpers';
import { server } from '../mocks/server';

Object.defineProperty(firebaseAuth, 'currentUser', {
  configurable: true,
  get: () => ({ getIdToken: vi.fn(async () => 'tok') }),
});

describe('PublishConfirmDialog', () => {
  it('renders the count once the query resolves', async () => {
    renderWithProviders(
      <PublishConfirmDialog
        open
        onOpenChange={() => undefined}
        submitting={false}
        onConfirm={() => undefined}
      />,
    );
    expect(
      await screen.findByText('About 42 subscribers will receive a notification.'),
    ).toBeInTheDocument();
  });

  it('confirm button fires onConfirm', async () => {
    const onConfirm = vi.fn();
    renderWithProviders(
      <PublishConfirmDialog
        open
        onOpenChange={() => undefined}
        submitting={false}
        onConfirm={onConfirm}
      />,
    );
    await screen.findByText('About 42 subscribers will receive a notification.');
    const user = userEvent.setup();
    await user.click(screen.getByRole('button', { name: 'Publish' }));
    expect(onConfirm).toHaveBeenCalledTimes(1);
  });

  it('cancel button calls onOpenChange(false)', async () => {
    const onOpenChange = vi.fn();
    renderWithProviders(
      <PublishConfirmDialog
        open
        onOpenChange={onOpenChange}
        submitting={false}
        onConfirm={() => undefined}
      />,
    );
    const user = userEvent.setup();
    await user.click(screen.getByRole('button', { name: 'Cancel' }));
    expect(onOpenChange).toHaveBeenCalledWith(false);
  });

  it('still renders a skeleton when the count call errors', async () => {
    server.use(
      http.get('*/admin/notifications/subscribers/count', () =>
        HttpResponse.json({ error: 'boom' }, { status: 500 }),
      ),
    );
    renderWithProviders(
      <PublishConfirmDialog
        open
        onOpenChange={() => undefined}
        submitting={false}
        onConfirm={() => undefined}
      />,
    );
    expect(await screen.findByRole('dialog')).toBeInTheDocument();
  });
});
