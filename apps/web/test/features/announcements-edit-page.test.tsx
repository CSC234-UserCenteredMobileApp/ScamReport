import { describe, expect, it, vi } from 'vitest';
import { http, HttpResponse } from 'msw';
import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Route, Routes } from 'react-router-dom';
import { AnnouncementsEditPage } from '@/features/announcements/pages/edit-page';
import { firebaseAuth } from '@/lib/auth/firebase';
import { renderWithProviders } from '../helpers';
import { server } from '../mocks/server';
import {
  sampleAnnouncementDraft,
  samplePublishedAnnouncement,
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

function renderRoute(id: string) {
  return renderWithProviders(
    <Routes>
      <Route path="/announcements" element={<div data-testid="list">List</div>} />
      <Route path="/announcements/:id/edit" element={<AnnouncementsEditPage />} />
    </Routes>,
    { initialRoute: `/announcements/${id}/edit` },
  );
}

describe('AnnouncementsEditPage', () => {
  it('renders the draft form with prefilled values', async () => {
    renderRoute(sampleAnnouncementDraft.id);
    const titleInput = await screen.findByLabelText('Title');
    expect(titleInput).toHaveValue(sampleAnnouncementDraft.title);
    expect(screen.getByLabelText('Body')).toHaveValue(sampleAnnouncementDraft.body);
    expect(screen.getByRole('button', { name: 'Save draft' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Publish' })).toBeInTheDocument();
  });

  it('locks the form and shows Unpublish when the announcement is already published', async () => {
    renderRoute(samplePublishedAnnouncement.id);
    expect(await screen.findByText('Published — editing locked')).toBeInTheDocument();
    expect(screen.getByLabelText('Title')).toBeDisabled();
    expect(screen.getByRole('button', { name: 'Unpublish' })).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Publish' })).toBeNull();
  });

  it('opens the publish confirmation dialog when Publish is clicked', async () => {
    const user = userEvent.setup();
    renderRoute(sampleAnnouncementDraft.id);
    await screen.findByLabelText('Title');
    await user.click(screen.getByRole('button', { name: 'Publish' }));
    expect(
      await screen.findByText('Publish and send push?'),
    ).toBeInTheDocument();
  });

  it('opens the delete confirmation dialog when Delete is clicked', async () => {
    const user = userEvent.setup();
    renderRoute(sampleAnnouncementDraft.id);
    await screen.findByLabelText('Title');
    await user.click(screen.getByRole('button', { name: 'Delete' }));
    expect(await screen.findByText('Delete this announcement?')).toBeInTheDocument();
  });

  it('redirects to /announcements on 404', async () => {
    server.use(
      http.get('*/admin/announcements/:id', () =>
        HttpResponse.json({ error: 'Not found' }, { status: 404 }),
      ),
    );
    renderRoute(sampleAnnouncementDraft.id);
    await waitFor(() => {
      expect(screen.getByTestId('list')).toBeInTheDocument();
    });
    expect(toastMock.error).toHaveBeenCalled();
  });
});
