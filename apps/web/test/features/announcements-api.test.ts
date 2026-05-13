import { describe, it, expect } from 'vitest';
import { http, HttpResponse } from 'msw';
import { apiFetch, ApiError } from '@/lib/api/client';
import { validators } from '@/lib/api/validators';
import { server } from '../mocks/server';
import {
  sampleAnnouncementDraft,
  sampleAnnouncementList,
  sampleSubscriberCount,
} from '../mocks/handlers';

describe('admin announcements list API', () => {
  it('returns the announcement list on 200', async () => {
    const res = await apiFetch('/admin/announcements', validators.adminAnnouncementList);
    expect(res.items).toHaveLength(sampleAnnouncementList.items.length);
  });

  it('throws SCHEMA_MISMATCH when response shape is invalid', async () => {
    server.use(
      http.get('*/admin/announcements', () =>
        HttpResponse.json({ items: [{ id: 'not-a-uuid' }] }),
      ),
    );
    try {
      await apiFetch('/admin/announcements', validators.adminAnnouncementList);
      throw new Error('expected apiFetch to throw');
    } catch (err) {
      expect(err).toBeInstanceOf(ApiError);
      expect((err as ApiError).message).toBe('SCHEMA_MISMATCH');
    }
  });
});

describe('admin announcement detail API', () => {
  it('returns the draft announcement', async () => {
    const res = await apiFetch(
      `/admin/announcements/${sampleAnnouncementDraft.id}`,
      validators.adminAnnouncementDetail,
    );
    expect(res.item.title).toBe(sampleAnnouncementDraft.title);
  });

  it('throws ApiError(404) when missing', async () => {
    server.use(
      http.get(`*/admin/announcements/${sampleAnnouncementDraft.id}`, () =>
        HttpResponse.json({ error: 'Not found' }, { status: 404 }),
      ),
    );
    try {
      await apiFetch(
        `/admin/announcements/${sampleAnnouncementDraft.id}`,
        validators.adminAnnouncementDetail,
      );
      throw new Error('expected apiFetch to throw');
    } catch (err) {
      expect(err).toBeInstanceOf(ApiError);
      expect((err as ApiError).status).toBe(404);
    }
  });
});

describe('subscriber count API', () => {
  it('returns the count', async () => {
    const res = await apiFetch(
      '/admin/notifications/subscribers/count',
      validators.subscriberCount,
    );
    expect(res.count).toBe(sampleSubscriberCount.count);
  });

  it('throws SCHEMA_MISMATCH on bad shape', async () => {
    server.use(
      http.get('*/admin/notifications/subscribers/count', () =>
        HttpResponse.json({ count: 'forty' }),
      ),
    );
    try {
      await apiFetch(
        '/admin/notifications/subscribers/count',
        validators.subscriberCount,
      );
      throw new Error('expected apiFetch to throw');
    } catch (err) {
      expect(err).toBeInstanceOf(ApiError);
      expect((err as ApiError).message).toBe('SCHEMA_MISMATCH');
    }
  });
});
