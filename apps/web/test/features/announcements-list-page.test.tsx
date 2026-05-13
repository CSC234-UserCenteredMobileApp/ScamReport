import { describe, expect, it, vi } from 'vitest';
import { http, HttpResponse } from 'msw';
import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Route, Routes } from 'react-router-dom';
import { AnnouncementsListPage } from '@/features/announcements/pages/list-page';
import { firebaseAuth } from '@/lib/auth/firebase';
import { renderWithProviders } from '../helpers';
import { server } from '../mocks/server';

Object.defineProperty(firebaseAuth, 'currentUser', {
  configurable: true,
  get: () => ({ getIdToken: vi.fn(async () => 'tok') }),
});

function renderRoute(initialRoute = '/announcements') {
  return renderWithProviders(
    <Routes>
      <Route path="/announcements" element={<AnnouncementsListPage />} />
      <Route path="/announcements/new" element={<div data-testid="new">New</div>} />
    </Routes>,
    { initialRoute },
  );
}

describe('AnnouncementsListPage', () => {
  it('renders the table once data loads', async () => {
    renderRoute();
    expect(await screen.findByText('Launch tips draft')).toBeInTheDocument();
    expect(screen.getByText('Published fraud alert')).toBeInTheDocument();
  });

  it('shows the empty state when the list is empty', async () => {
    server.use(
      http.get('*/admin/announcements', () => HttpResponse.json({ items: [] })),
    );
    renderRoute();
    expect(await screen.findByText('No announcements yet.')).toBeInTheDocument();
  });

  it('shows the error alert on 500', async () => {
    server.use(
      http.get('*/admin/announcements', () =>
        HttpResponse.json({ error: 'boom' }, { status: 500 }),
      ),
    );
    renderRoute();
    expect(await screen.findByRole('alert')).toBeInTheDocument();
  });

  it('navigates to /announcements/new when CTA is clicked', async () => {
    const user = userEvent.setup();
    renderRoute();
    await screen.findByText('Launch tips draft');
    await user.click(screen.getByRole('button', { name: 'New announcement' }));
    await waitFor(() => {
      expect(screen.getByTestId('new')).toBeInTheDocument();
    });
  });
});
