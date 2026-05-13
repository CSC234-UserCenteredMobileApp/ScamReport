import { describe, it, expect } from 'vitest';
import { http, HttpResponse } from 'msw';
import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import type { AdminEvidenceFile } from '@my-product/shared';
import { EvidenceGallery } from '@/features/moderation/components/evidence-gallery';
import { renderWithProviders } from '../helpers';
import { server } from '../mocks/server';
import { sampleEvidenceUrlResponse } from '../mocks/handlers';

const REPORT_ID = '11111111-1111-1111-1111-111111111111';

const imageFile: AdminEvidenceFile = {
  id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  storagePath: 'evidence/admin/sample.jpg',
  kind: 'image',
  mimeType: 'image/jpeg',
  sizeBytes: 24_576,
  signedUrl: null,
};

const pdfFile: AdminEvidenceFile = {
  id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  storagePath: 'evidence/admin/sample.pdf',
  kind: 'pdf',
  mimeType: 'application/pdf',
  sizeBytes: 65_536,
  signedUrl: null,
};

describe('EvidenceGallery', () => {
  it('shows a placeholder text when there are no files', () => {
    renderWithProviders(<EvidenceGallery reportId={REPORT_ID} files={[]} />);
    expect(screen.getByText(/Evidence — 0/)).toBeInTheDocument();
  });

  it('renders an image thumb after the signed URL resolves', async () => {
    renderWithProviders(<EvidenceGallery reportId={REPORT_ID} files={[imageFile]} />);
    const img = await screen.findByRole('img');
    expect(img).toHaveAttribute('src', sampleEvidenceUrlResponse.url);
  });

  it('opens the PDF viewer when the pdf thumb is clicked', async () => {
    const user = userEvent.setup();
    renderWithProviders(<EvidenceGallery reportId={REPORT_ID} files={[pdfFile]} />);
    const buttons = await screen.findAllByRole('button', { name: /Evidence preview/i });
    await user.click(buttons[0]!);
    await waitFor(() => {
      expect(screen.getByTitle('Evidence preview')).toBeInTheDocument();
    });
  });

  it('shows the missing-file fallback when the signed URL call errors', async () => {
    server.use(
      http.get(`*/admin/reports/${REPORT_ID}/evidence/:fileId/url`, () =>
        HttpResponse.json({ error: 'Not found' }, { status: 404 }),
      ),
    );
    renderWithProviders(<EvidenceGallery reportId={REPORT_ID} files={[imageFile]} />);
    expect(await screen.findByText('Could not load this file.')).toBeInTheDocument();
  });
});
