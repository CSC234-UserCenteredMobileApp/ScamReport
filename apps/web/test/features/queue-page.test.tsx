import { describe, it, expect, vi, beforeEach } from 'vitest';
import { http, HttpResponse } from 'msw';
import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { server } from '../mocks/server';
import { sampleQueue, sampleItem, sampleFlagged, sampleMediumScore, sampleLowScore } from '../mocks/handlers';
import { renderWithProviders, makeQueryClient } from '../helpers';
import { QueuePage } from '@/features/moderation/pages/queue-page';
import { firebaseAuth } from '@/lib/auth/firebase';
import type { AdminQueueResponse } from '@my-product/shared';

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
    // Dropdown trigger is labelled by the column's "Actions" header; click that
    // (the row also has an inline Review button which navigates instead).
    const menuTriggers = screen.getAllByRole('button', { name: /actions/i });
    await user.click(menuTriggers[0]!);

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

describe('Queue filter — status', () => {
  it('status=flagged hides pending rows', async () => {
    const user = userEvent.setup();
    renderWithProviders(<QueuePage />, { client: makeQueryClient() });
    await screen.findByText(sampleItem.title);
    await user.click(screen.getByRole('button', { name: /^flagged$/i }));
    expect(screen.queryByText(sampleItem.title)).toBeNull();
    expect(screen.getByText(sampleFlagged.title)).toBeInTheDocument();
  });

  it('status=pending hides flagged rows', async () => {
    const user = userEvent.setup();
    renderWithProviders(<QueuePage />, { client: makeQueryClient() });
    await screen.findByText(sampleFlagged.title);
    await user.click(screen.getByRole('button', { name: /^pending$/i }));
    expect(screen.queryByText(sampleFlagged.title)).toBeNull();
    expect(screen.getByText(sampleItem.title)).toBeInTheDocument();
  });

  it('shows noMatch message when filters exclude all rows', async () => {
    const user = userEvent.setup();
    server.use(
      http.get(`${baseUrl}/admin/reports/queue`, () =>
        HttpResponse.json<AdminQueueResponse>({
          items: [sampleItem],
          pendingCount: 1,
          flaggedCount: 0,
        }),
      ),
    );
    renderWithProviders(<QueuePage />, { client: makeQueryClient() });
    await screen.findByText(sampleItem.title);
    await user.click(screen.getByRole('button', { name: /^flagged$/i }));
    expect(await screen.findByText(/no reports match/i)).toBeInTheDocument();
  });
});

describe('Queue filter — priority', () => {
  it('priority-only hides rows without priorityFlag', async () => {
    const user = userEvent.setup();
    renderWithProviders(<QueuePage />, { client: makeQueryClient() });
    await screen.findByText(sampleItem.title); // priorityFlag=false
    await user.click(screen.getByRole('button', { name: /priority only/i }));
    expect(screen.queryByText(sampleItem.title)).toBeNull();
    expect(screen.getByText(sampleFlagged.title)).toBeInTheDocument(); // priorityFlag=true
  });
});

describe('Queue filter — confidence', () => {
  it('high filter shows high-confidence rows and hides null-confidence rows', async () => {
    const user = userEvent.setup();
    renderWithProviders(<QueuePage />, { client: makeQueryClient() });
    await screen.findByText(sampleItem.title); // aiConfidence='high'
    await user.click(screen.getByRole('button', { name: /^high/i }));
    expect(screen.getByText(sampleItem.title)).toBeInTheDocument();
    expect(screen.queryByText(sampleFlagged.title)).toBeNull(); // aiConfidence=null
  });

  it('medium filter shows only medium-confidence rows', async () => {
    const user = userEvent.setup();
    server.use(
      http.get(`${baseUrl}/admin/reports/queue`, () =>
        HttpResponse.json<AdminQueueResponse>({
          items: [sampleItem, sampleMediumScore],
          pendingCount: 2,
          flaggedCount: 0,
        }),
      ),
    );
    renderWithProviders(<QueuePage />, { client: makeQueryClient() });
    await screen.findByText(sampleMediumScore.title);
    await user.click(screen.getByRole('button', { name: /medium/i }));
    expect(screen.queryByText(sampleItem.title)).toBeNull();
    expect(screen.getByText(sampleMediumScore.title)).toBeInTheDocument();
  });

  it('low filter shows only low-confidence rows', async () => {
    const user = userEvent.setup();
    server.use(
      http.get(`${baseUrl}/admin/reports/queue`, () =>
        HttpResponse.json<AdminQueueResponse>({
          items: [sampleItem, sampleLowScore],
          pendingCount: 2,
          flaggedCount: 0,
        }),
      ),
    );
    renderWithProviders(<QueuePage />, { client: makeQueryClient() });
    await screen.findByText(sampleLowScore.title);
    await user.click(screen.getByRole('button', { name: /^low/i }));
    expect(screen.queryByText(sampleItem.title)).toBeNull();
    expect(screen.getByText(sampleLowScore.title)).toBeInTheDocument();
  });
});

describe('AI score badge colors', () => {
  it('score ≥ 70 renders red badge', async () => {
    renderWithProviders(<QueuePage />, { client: makeQueryClient() });
    await screen.findByText(sampleItem.title);
    const badge = screen.getByText(String(sampleItem.aiScore)); // 78
    expect(badge).toHaveClass('bg-red-100');
  });

  it('score 40–69 renders amber badge', async () => {
    server.use(
      http.get(`${baseUrl}/admin/reports/queue`, () =>
        HttpResponse.json<AdminQueueResponse>({
          items: [sampleMediumScore],
          pendingCount: 1,
          flaggedCount: 0,
        }),
      ),
    );
    renderWithProviders(<QueuePage />, { client: makeQueryClient() });
    await screen.findByText(sampleMediumScore.title);
    const badge = screen.getByText(String(sampleMediumScore.aiScore)); // 55
    expect(badge).toHaveClass('bg-amber-100');
  });

  it('score < 40 renders green badge', async () => {
    server.use(
      http.get(`${baseUrl}/admin/reports/queue`, () =>
        HttpResponse.json<AdminQueueResponse>({
          items: [sampleLowScore],
          pendingCount: 1,
          flaggedCount: 0,
        }),
      ),
    );
    renderWithProviders(<QueuePage />, { client: makeQueryClient() });
    await screen.findByText(sampleLowScore.title);
    const badge = screen.getByText(String(sampleLowScore.aiScore)); // 22
    expect(badge).toHaveClass('bg-green-100');
  });

  it('null score renders a dash, not a badge', async () => {
    server.use(
      http.get(`${baseUrl}/admin/reports/queue`, () =>
        HttpResponse.json<AdminQueueResponse>({
          items: [sampleFlagged],
          pendingCount: 0,
          flaggedCount: 1,
        }),
      ),
    );
    renderWithProviders(<QueuePage />, { client: makeQueryClient() });
    await screen.findByText(sampleFlagged.title);
    expect(screen.getByText('—')).toBeInTheDocument();
  });
});
