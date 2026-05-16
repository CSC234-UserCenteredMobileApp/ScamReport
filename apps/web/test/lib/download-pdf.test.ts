import { describe, it, expect, vi, beforeEach } from 'vitest';
import { http, HttpResponse } from 'msw';
import { server } from '../mocks/server';
import { downloadPdf } from '@/lib/api/download-pdf';
import { ApiError } from '@/lib/api/client';
import { firebaseAuth } from '@/lib/auth/firebase';

const baseUrl = 'http://localhost:3000';

function stubCurrentUser(token: string | null) {
  Object.defineProperty(firebaseAuth, 'currentUser', {
    configurable: true,
    get: () =>
      token === null
        ? null
        : { getIdToken: vi.fn(async () => token) },
  });
}

// jsdom doesn't ship a real URL.createObjectURL; stub the pair before each.
beforeEach(() => {
  stubCurrentUser('the-token');
  (globalThis.URL as { createObjectURL?: (b: Blob) => string }).createObjectURL =
    vi.fn(() => 'blob:fake');
  (globalThis.URL as { revokeObjectURL?: (u: string) => void }).revokeObjectURL =
    vi.fn();
  const click = vi.fn();
  // Spy on link click — jsdom navigates on anchor.click() by default.
  Object.defineProperty(HTMLAnchorElement.prototype, 'click', {
    configurable: true,
    value: click,
  });
});

describe('downloadPdf', () => {
  it('fetches the PDF with auth + triggers a download', async () => {
    let seenAuth = '';
    server.use(
      http.get(`${baseUrl}/admin/x.pdf`, ({ request }) => {
        seenAuth = request.headers.get('Authorization') ?? '';
        return new HttpResponse(new Uint8Array([0x25, 0x50, 0x44, 0x46]), {
          headers: { 'Content-Type': 'application/pdf' },
        });
      }),
    );

    await downloadPdf('/admin/x.pdf', 'thing.pdf');
    expect(seenAuth).toBe('Bearer the-token');
    expect(
      (globalThis.URL as { createObjectURL: () => string }).createObjectURL,
    ).toHaveBeenCalled();
  });

  it('throws ApiError on 403', async () => {
    server.use(
      http.get(`${baseUrl}/admin/x.pdf`, () =>
        new HttpResponse(null, { status: 403 }),
      ),
    );
    await expect(downloadPdf('/admin/x.pdf', 'x.pdf')).rejects.toBeInstanceOf(
      ApiError,
    );
  });
});
