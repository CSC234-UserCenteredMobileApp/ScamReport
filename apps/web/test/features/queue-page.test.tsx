import { describe, it, expect, vi, beforeEach } from 'vitest';
import { http, HttpResponse } from 'msw';
import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { server } from '../mocks/server';
import { sampleQueue } from '../mocks/handlers';
import { renderWithProviders, makeQueryClient } from '../helpers';
import { QueuePage } from '@/features/moderation/pages/queue-page';
import { firebaseAuth } from '@/lib/auth/firebase';

Object.defineProperty(firebaseAuth, 'currentUser', {
  configurable: true,
  get: () => ({ getIdToken: vi.fn(async () => 'tok') }),
});

const baseUrl = 'http://localhost:3000';

beforeEach(() => {
  vi.clearAllMocks();
});

describe('QueuePage', () => {
  it('renders rows from the queue endpoint', async () => {
    renderWithProviders(<QueuePage />, { client: makeQueryClient() });
    expect(await screen.findByText(sampleQueue.items[0]!.title)).toBeInTheDocument();
    expect(await screen.findByText(sampleQueue.items[1]!.title)).toBeInTheDocument();
  });

  it('shows the empty state when the queue is empty', async () => {
    server.use(
      http.get(`${baseUrl}/admin/reports/queue`, () =>
        HttpResponse.json({ items: [], pendingCount: 0, flaggedCount: 0 }),
      ),
    );
    renderWithProviders(<QueuePage />, { client: makeQueryClient() });
    expect(await screen.findByText(/queue is empty/i)).toBeInTheDocument();
  });

  it('shows an error alert when the queue fails to load', async () => {
    server.use(
      http.get(`${baseUrl}/admin/reports/queue`, () =>
        HttpResponse.json({ error: 'boom' }, { status: 500 }),
      ),
    );
    renderWithProviders(<QueuePage />, { client: makeQueryClient() });
    await waitFor(() => {
      expect(screen.getAllByRole('alert').length).toBeGreaterThan(0);
    });
  });

  it('opens an action dialog and requires a remark before submitting', async () => {
    const user = userEvent.setup();
    renderWithProviders(<QueuePage />, { client: makeQueryClient() });

    const firstRowTitle = await screen.findByText(sampleQueue.items[0]!.title);
    // The actions dropdown trigger is the row's first IconButton sibling
    const actionsButtons = screen.getAllByRole('button', { name: /review/i });
    await user.click(actionsButtons[0]!);

    const approveItem = await screen.findByRole('menuitem', { name: /approve/i });
    await user.click(approveItem);

    const dialog = await screen.findByRole('dialog');
    expect(dialog).toBeInTheDocument();
    // Submitting empty form keeps dialog open + shows error
    const submitBtn = screen.getByRole('button', { name: /confirm/i });
    await user.click(submitBtn);
    expect(await screen.findByRole('alert')).toBeInTheDocument();
    expect(firstRowTitle).toBeInTheDocument();
  });
});
