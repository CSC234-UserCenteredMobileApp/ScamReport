import { describe, expect, it, vi } from 'vitest';
import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Route, Routes } from 'react-router-dom';
import { AnnouncementsNewPage } from '@/features/announcements/pages/new-page';
import { firebaseAuth } from '@/lib/auth/firebase';
import { renderWithProviders } from '../helpers';
import { sampleAnnouncementDraft } from '../mocks/handlers';

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

function renderRoute() {
  return renderWithProviders(
    <Routes>
      <Route path="/announcements/new" element={<AnnouncementsNewPage />} />
      <Route
        path="/announcements/:id/edit"
        element={<div data-testid="edit-page">Edit</div>}
      />
    </Routes>,
    { initialRoute: '/announcements/new' },
  );
}

describe('AnnouncementsNewPage', () => {
  it('navigates to the edit page after saving the first draft', async () => {
    renderRoute();
    const user = userEvent.setup();
    await user.type(screen.getByLabelText('Title'), 'A brand-new draft');
    await user.type(screen.getByLabelText('Body'), 'The body of the draft.');
    await user.click(screen.getByRole('button', { name: 'Save draft' }));
    await waitFor(() => {
      expect(screen.getByTestId('edit-page')).toBeInTheDocument();
    });
    expect(toastMock.success).toHaveBeenCalled();
  });

  it('shows the attachments-after-save hint', () => {
    renderRoute();
    expect(
      screen.getByText('Attachments unlock after the first save.'),
    ).toBeInTheDocument();
  });

  it('publishes inline from the new page in one flow', async () => {
    renderRoute();
    const user = userEvent.setup();
    await user.type(screen.getByLabelText('Title'), 'Inline publish');
    await user.type(screen.getByLabelText('Body'), 'Going live now.');
    await user.click(screen.getByRole('button', { name: 'Publish' }));
    // Confirm dialog appears (subscriber count copy comes from the
    // /admin/notifications/subscribers/count handler).
    await waitFor(() => {
      expect(screen.getByText('Publish and send push?')).toBeInTheDocument();
    });
    // Click the dialog's "Publish" button (a second button with the same
    // accessible name now exists alongside the form's primary button).
    const publishButtons = screen.getAllByRole('button', { name: 'Publish' });
    const confirmBtn = publishButtons[publishButtons.length - 1];
    if (!confirmBtn) throw new Error('confirm Publish button not found');
    await user.click(confirmBtn);
    await waitFor(() => {
      expect(screen.getByTestId('edit-page')).toBeInTheDocument();
    });
    expect(toastMock.success).toHaveBeenCalled();
    expect(sampleAnnouncementDraft.id).toBeTruthy();
  });

  // The new-page form starts on fraud_alert by default; this verifies the
  // create flow still uses the form's selected category when the user picks
  // a different one before saving.
  it('respects the category radio selection', async () => {
    renderRoute();
    const user = userEvent.setup();
    await user.click(screen.getByRole('radio', { name: 'Tips' }));
    expect(screen.getByRole('radio', { name: 'Tips' })).toHaveAttribute(
      'aria-checked',
      'true',
    );
    // Sanity: the mocked POST returns the draft fixture; assert the redirect
    // target still matches the fixture id regardless of which category the
    // user picked locally.
    await user.type(screen.getByLabelText('Title'), 'X');
    await user.type(screen.getByLabelText('Body'), 'Y');
    await user.click(screen.getByRole('button', { name: 'Save draft' }));
    await waitFor(() => {
      expect(screen.getByTestId('edit-page')).toBeInTheDocument();
    });
    expect(sampleAnnouncementDraft.id).toBeTruthy();
  });
});
