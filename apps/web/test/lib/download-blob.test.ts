import { describe, it, expect, vi, beforeEach } from 'vitest';
import { http, HttpResponse } from 'msw';
import { server } from '../mocks/server';
import { downloadBlob } from '@/lib/api/download-blob';
import { ApiError } from '@/lib/api/client';
import { firebaseAuth } from '@/lib/auth/firebase';

const baseUrl = 'http://localhost:3000';

function stubCurrentUser(token: string | null) {
  Object.defineProperty(firebaseAuth, 'currentUser', {
    configurable: true,
    get: () =>
      token === null ? null : { getIdToken: vi.fn(async () => token) },
  });
}

beforeEach(() => {
  stubCurrentUser('tok');
  (globalThis.URL as { createObjectURL?: (b: Blob) => string }).createObjectURL =
    vi.fn(() => 'blob:fake');
  (globalThis.URL as { revokeObjectURL?: (u: string) => void }).revokeObjectURL =
    vi.fn();
  Object.defineProperty(HTMLAnchorElement.prototype, 'click', {
    configurable: true,
    value: vi.fn(),
  });
});

describe('downloadBlob', () => {
  it('respects Content-Disposition filename and triggers download', async () => {
    server.use(
      http.get(`${baseUrl}/admin/export.csv`, () =>
        new HttpResponse(new Blob(['a,b\n1,2'], { type: 'text/csv' }), {
          headers: {
            'Content-Type': 'text/csv',
            'Content-Disposition': 'attachment; filename="server.csv"',
          },
        }),
      ),
    );
    await downloadBlob('/admin/export.csv', 'fallback.csv');
    expect(
      (globalThis.URL as unknown as { createObjectURL: (b: Blob) => string })
        .createObjectURL,
    ).toHaveBeenCalled();
  });

  it('falls back to the supplied filename when no header is present', async () => {
    server.use(
      http.get(`${baseUrl}/admin/export.csv`, () =>
        new HttpResponse(new Blob(['x']), { headers: { 'Content-Type': 'text/csv' } }),
      ),
    );
    await expect(
      downloadBlob('/admin/export.csv', 'fallback.csv'),
    ).resolves.toBeUndefined();
  });

  it('throws ApiError on 403', async () => {
    server.use(
      http.get(`${baseUrl}/admin/export.csv`, () =>
        new HttpResponse(null, { status: 403 }),
      ),
    );
    await expect(
      downloadBlob('/admin/export.csv', 'x.csv'),
    ).rejects.toBeInstanceOf(ApiError);
  });
});
