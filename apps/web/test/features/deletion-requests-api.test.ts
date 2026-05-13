import { describe, it, expect } from 'vitest';
import { http, HttpResponse } from 'msw';
import { apiFetch, ApiError } from '@/lib/api/client';
import { validators } from '@/lib/api/validators';
import { buildListPath } from '@/features/deletion-requests/api/list';
import { server } from '../mocks/server';
import { samplePendingDeletion } from '../mocks/handlers';

describe('admin deletion requests list API', () => {
  it('returns the pending list by default', async () => {
    const res = await apiFetch(buildListPath(), validators.adminDeletionList);
    expect(res.items[0]?.id).toBe(samplePendingDeletion.id);
    expect(res.pendingCount).toBeGreaterThanOrEqual(1);
  });

  it('passes the status query string', async () => {
    const res = await apiFetch(
      buildListPath('approved'),
      validators.adminDeletionList,
    );
    expect(res.items[0]?.status).toBe('approved');
  });

  it('throws ApiError(500) on server error', async () => {
    server.use(
      http.get('*/admin/deletion-requests', () =>
        HttpResponse.json({ error: 'boom' }, { status: 500 }),
      ),
    );
    try {
      await apiFetch(buildListPath(), validators.adminDeletionList);
      throw new Error('expected apiFetch to throw');
    } catch (err) {
      expect(err).toBeInstanceOf(ApiError);
      expect((err as ApiError).status).toBe(500);
    }
  });

  it('throws SCHEMA_MISMATCH on bad shape', async () => {
    server.use(
      http.get('*/admin/deletion-requests', () =>
        HttpResponse.json({ items: [{ id: 'not-uuid' }], pendingCount: 0 }),
      ),
    );
    try {
      await apiFetch(buildListPath(), validators.adminDeletionList);
      throw new Error('expected apiFetch to throw');
    } catch (err) {
      expect(err).toBeInstanceOf(ApiError);
      expect((err as ApiError).message).toBe('SCHEMA_MISMATCH');
    }
  });
});
