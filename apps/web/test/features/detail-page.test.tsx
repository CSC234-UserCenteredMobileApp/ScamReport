import { describe, it, expect, vi } from 'vitest';
import { http, HttpResponse } from 'msw';
import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Routes, Route } from 'react-router-dom';
import { DetailPage } from '@/features/moderation/pages/detail-page';
import { firebaseAuth } from '@/lib/auth/firebase';
import { renderWithProviders } from '../helpers';
import { server } from '../mocks/server';
import { sampleDetailResponse } from '../mocks/handlers';

Object.defineProperty(firebaseAuth, 'currentUser', {
  configurable: true,
  get: () => ({ getIdToken: vi.fn(async () => 'tok') }),
});

const REPORT_ID = '11111111-1111-1111-1111-111111111111';

const toastMock = vi.hoisted(() => ({
  success: vi.fn(),
  error: vi.fn(),
}));

vi.mock('sonner', () => ({
  toast: toastMock,
  Toaster: () => null,
}));

function renderRoute(initialRoute = `/moderation/${REPORT_ID}`) {
  return renderWithProviders(
    <Routes>
      <Route path="/moderation" element={<div data-testid="queue">Queue</div>} />
      <Route path="/moderation/:id" element={<DetailPage />} />
    </Routes>,
    { initialRoute },
  );
}

describe('DetailPage', () => {
  it('renders the loading skeleton then the report', async () => {
    renderRoute();
    expect(await screen.findByText(sampleDetailResponse.report.title)).toBeInTheDocument();
    // "Submitted anonymously" appears twice — meta card subtitle and synthetic
    // audit-trail row. Asserting >=1 is enough; multi-render is intentional.
    expect(screen.getAllByText(/Submitted anonymously/i).length).toBeGreaterThan(0);
  });

  it('redirects to /moderation on 404', async () => {
    server.use(
      http.get(`*/admin/reports/${REPORT_ID}`, () =>
        HttpResponse.json({ error: 'Not found' }, { status: 404 }),
      ),
    );
    renderRoute();
    await waitFor(() => {
      expect(screen.getByTestId('queue')).toBeInTheDocument();
    });
    expect(toastMock.error).toHaveBeenCalled();
  });

  it('shows error alert with retry on 500', async () => {
    server.use(
      http.get(`*/admin/reports/${REPORT_ID}`, () =>
        HttpResponse.json({ error: 'boom' }, { status: 500 }),
      ),
    );
    renderRoute();
    // Alert renders both title + description with the same i18n key; assert by role.
    expect(await screen.findByRole('alert')).toBeInTheDocument();
    expect(screen.getAllByText('Could not load the report. Try again.').length).toBeGreaterThan(0);
  });

  it('opens the action dialog when Approve is clicked', async () => {
    const user = userEvent.setup();
    renderRoute();
    await screen.findByText(sampleDetailResponse.report.title);
    await user.click(screen.getByRole('button', { name: 'Approve' }));
    expect(await screen.findByText('Approve report')).toBeInTheDocument();
  });

  it('disables actions when the report is already verified', async () => {
    server.use(
      http.get(`*/admin/reports/${REPORT_ID}`, () =>
        HttpResponse.json({
          report: { ...sampleDetailResponse.report, status: 'verified' as const },
        }),
      ),
    );
    renderRoute();
    expect(
      await screen.findByText('This report has already been reviewed.'),
    ).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Approve' })).toBeNull();
  });

  it('shows the unflag action when the report is currently flagged', async () => {
    server.use(
      http.get(`*/admin/reports/${REPORT_ID}`, () =>
        HttpResponse.json({
          report: { ...sampleDetailResponse.report, status: 'flagged' as const },
        }),
      ),
    );
    renderRoute();
    expect(await screen.findByRole('button', { name: /unflag/i })).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /^Flag for discussion$/i })).toBeNull();
  });

  it('never renders any reporter identifier in the page tree', async () => {
    renderRoute();
    await screen.findByText(sampleDetailResponse.report.title);
    const html = document.body.innerHTML;
    expect(html).not.toMatch(/reporter/i);
    expect(html).not.toMatch(/User_[0-9a-f]/i);
  });
});
