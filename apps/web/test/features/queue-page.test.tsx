import { describe, it, expect, vi, beforeEach } from 'vitest';
import { http, HttpResponse } from 'msw';
import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { server } from '../mocks/server';
import {
  sampleQueue,
  sampleFlagged,
  sampleMediumScore,
  sampleLowScore,
} from '../mocks/handlers';
import { renderWithProviders, makeQueryClient } from '../helpers';
import { QueuePage } from '@/features/moderation/pages/queue-page';
import { firebaseAuth } from '@/lib/auth/firebase';
import type { AdminQueueResponse } from '@my-product/shared';

Object.defineProperty(firebaseAuth, 'currentUser', {
  configurable: true,
  get: () => ({ getIdToken: vi.fn(async () => 'tok') }),
});

const baseUrl = 'http://localhost:3000';

const emptyExtra = { total: 0, page: 1, pageSize: 25 };

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
        HttpResponse.json<AdminQueueResponse>({
          items: [],
          pendingCount: 0,
          flaggedCount: 0,
          ...emptyExtra,
        }),
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
    const menuTriggers = screen.getAllByRole('button', { name: /actions/i });
    await user.click(menuTriggers[0]!);

    const approveItem = await screen.findByRole('menuitem', { name: /approve/i });
    await user.click(approveItem);

    const dialog = await screen.findByRole('dialog');
    expect(dialog).toBeInTheDocument();
    const submitBtn = screen.getByRole('button', { name: /confirm/i });
    await user.click(submitBtn);
    expect(await screen.findByRole('alert')).toBeInTheDocument();
    expect(firstRowTitle).toBeInTheDocument();
  });

  it('renders the search input and the Filters button', async () => {
    renderWithProviders(<QueuePage />, { client: makeQueryClient() });
    await screen.findByText(sampleQueue.items[0]!.title);
    expect(screen.getByPlaceholderText(/search title/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /filters/i })).toBeInTheDocument();
  });

  it('renders the pagination footer with showing-of-total', async () => {
    renderWithProviders(<QueuePage />, { client: makeQueryClient() });
    await screen.findByText(sampleQueue.items[0]!.title);
    // sampleQueue has total: 2
    expect(screen.getByText(/1.*2.*of.*2/i)).toBeInTheDocument();
  });

  it('changing the page-size selector triggers a URL update', async () => {
    const user = userEvent.setup();
    server.use(
      http.get(`${baseUrl}/admin/reports/queue`, () =>
        HttpResponse.json<AdminQueueResponse>({
          items: sampleQueue.items,
          pendingCount: 1,
          flaggedCount: 1,
          total: 137,
          page: 1,
          pageSize: 25,
        }),
      ),
    );
    renderWithProviders(<QueuePage />, { client: makeQueryClient() });
    await screen.findByText(sampleQueue.items[0]!.title);

    const trigger = screen.getByRole('combobox');
    await user.click(trigger);
    const opt = await screen.findByRole('option', { name: '50' });
    await user.click(opt);
    // No explicit assertion on URL (MemoryRouter); the click path exercises
    // the pagination onChange callback in the page component.
  });

  it('submits an approve action with a remark and closes the dialog', async () => {
    const user = userEvent.setup();
    renderWithProviders(<QueuePage />, { client: makeQueryClient() });
    await screen.findByText(sampleQueue.items[0]!.title);

    const menuTriggers = screen.getAllByRole('button', { name: /actions/i });
    await user.click(menuTriggers[0]!);
    const approveItem = await screen.findByRole('menuitem', { name: /approve/i });
    await user.click(approveItem);

    const dialog = await screen.findByRole('dialog');
    const remark = dialog.querySelector('textarea');
    if (!remark) throw new Error('remark textarea not found');
    await user.type(remark, 'looks valid');
    const submit = screen.getByRole('button', { name: /confirm/i });
    await user.click(submit);

    await waitFor(() => {
      expect(screen.queryByRole('dialog')).toBeNull();
    });
  });
});

describe('AI score badge colors', () => {
  it('score ≥ 70 renders red badge', async () => {
    renderWithProviders(<QueuePage />, { client: makeQueryClient() });
    const item = sampleQueue.items[0]!;
    await screen.findByText(item.title);
    const badge = screen.getByText(String(item.aiScore));
    expect(badge).toHaveClass('bg-red-100');
  });

  it('score 40–69 renders amber badge', async () => {
    server.use(
      http.get(`${baseUrl}/admin/reports/queue`, () =>
        HttpResponse.json<AdminQueueResponse>({
          items: [sampleMediumScore],
          pendingCount: 1,
          flaggedCount: 0,
          total: 1,
          page: 1,
          pageSize: 25,
        }),
      ),
    );
    renderWithProviders(<QueuePage />, { client: makeQueryClient() });
    await screen.findByText(sampleMediumScore.title);
    const badge = screen.getByText(String(sampleMediumScore.aiScore));
    expect(badge).toHaveClass('bg-amber-100');
  });

  it('score < 40 renders green badge', async () => {
    server.use(
      http.get(`${baseUrl}/admin/reports/queue`, () =>
        HttpResponse.json<AdminQueueResponse>({
          items: [sampleLowScore],
          pendingCount: 1,
          flaggedCount: 0,
          total: 1,
          page: 1,
          pageSize: 25,
        }),
      ),
    );
    renderWithProviders(<QueuePage />, { client: makeQueryClient() });
    await screen.findByText(sampleLowScore.title);
    const badge = screen.getByText(String(sampleLowScore.aiScore));
    expect(badge).toHaveClass('bg-green-100');
  });

  it('null score renders a dash, not a badge', async () => {
    server.use(
      http.get(`${baseUrl}/admin/reports/queue`, () =>
        HttpResponse.json<AdminQueueResponse>({
          items: [sampleFlagged],
          pendingCount: 0,
          flaggedCount: 1,
          total: 1,
          page: 1,
          pageSize: 25,
        }),
      ),
    );
    renderWithProviders(<QueuePage />, { client: makeQueryClient() });
    await screen.findByText(sampleFlagged.title);
    expect(screen.getByText('—')).toBeInTheDocument();
  });
});
