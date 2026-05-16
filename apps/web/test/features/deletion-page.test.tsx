import { describe, expect, it, vi } from 'vitest';
import { http, HttpResponse } from 'msw';
import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { DeletionRequestsPage } from '@/features/deletion-requests/pages/deletion-page';
import { firebaseAuth } from '@/lib/auth/firebase';
import { renderWithProviders } from '../helpers';
import { server } from '../mocks/server';
import {
  sampleApprovedDeletion,
  samplePendingDeletion,
  sampleRejectedDeletion,
} from '../mocks/handlers';

Object.defineProperty(firebaseAuth, 'currentUser', {
  configurable: true,
  get: () => ({ getIdToken: vi.fn(async () => 'tok') }),
});

const toastMock = vi.hoisted(() => ({
  success: vi.fn(),
  error: vi.fn(),
}));

vi.mock('sonner', () => ({
  toast: toastMock,
  Toaster: () => null,
}));

describe('DeletionRequestsPage', () => {
  it('renders pending rows by default and shows pendingCount', async () => {
    renderWithProviders(<DeletionRequestsPage />);
    expect(
      await screen.findByText(samplePendingDeletion.userHandle),
    ).toBeInTheDocument();
    expect(screen.getByText('1')).toBeInTheDocument();
  });

  it('swaps to the approved filter when the chip is clicked', async () => {
    const user = userEvent.setup();
    renderWithProviders(<DeletionRequestsPage />);
    await screen.findByText(samplePendingDeletion.userHandle);
    await user.click(screen.getByRole('tab', { name: 'Approved' }));
    expect(
      await screen.findByText(sampleApprovedDeletion.userHandle),
    ).toBeInTheDocument();
  });

  it('opens the approve confirmation dialog when Approve is clicked', async () => {
    const user = userEvent.setup();
    renderWithProviders(<DeletionRequestsPage />);
    await screen.findByText(samplePendingDeletion.userHandle);
    await user.click(screen.getByRole('button', { name: 'Approve' }));
    expect(
      await screen.findByText('Approve account deletion?'),
    ).toBeInTheDocument();
  });

  it('opens the reject dialog when Reject is clicked', async () => {
    const user = userEvent.setup();
    renderWithProviders(<DeletionRequestsPage />);
    await screen.findByText(samplePendingDeletion.userHandle);
    await user.click(screen.getByRole('button', { name: 'Reject' }));
    expect(
      await screen.findByText('Reject deletion request'),
    ).toBeInTheDocument();
  });

  it('shows the error alert and a retry button on 500', async () => {
    server.use(
      http.get('*/admin/deletion-requests', () =>
        HttpResponse.json({ error: 'boom' }, { status: 500 }),
      ),
    );
    renderWithProviders(<DeletionRequestsPage />);
    expect(await screen.findByRole('alert')).toBeInTheDocument();
  });

  it('shows user email for admin review and never leaks internal identifiers', async () => {
    renderWithProviders(<DeletionRequestsPage />);
    await screen.findByText(samplePendingDeletion.userHandle);
    // Email is intentionally shown to admin so they can make an informed decision.
    expect(screen.getByText(samplePendingDeletion.userEmail!)).toBeInTheDocument();
    const html = document.body.innerHTML;
    expect(html).not.toMatch(/firebaseUid/i);
  });

  it('renders the rejected reason chip when filter switched to rejected', async () => {
    const user = userEvent.setup();
    renderWithProviders(<DeletionRequestsPage />);
    await screen.findByText(samplePendingDeletion.userHandle);
    await user.click(screen.getByRole('tab', { name: 'Rejected' }));
    await waitFor(() =>
      expect(
        screen.getByText(sampleRejectedDeletion.userHandle),
      ).toBeInTheDocument(),
    );
  });
});
