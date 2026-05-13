import { describe, it, expect } from 'vitest';
import { http, HttpResponse } from 'msw';
import { QueryClient } from '@tanstack/react-query';
import { apiFetch, ApiError } from '@/lib/api/client';
import { validators } from '@/lib/api/validators';
import { buildDetailPath } from '@/features/moderation/api/detail';
import { server } from '../mocks/server';
import { sampleDetailResponse } from '../mocks/handlers';

const REPORT_ID = '11111111-1111-1111-1111-111111111111';

describe('admin report detail API', () => {
  it('returns the report on 200', async () => {
    const res = await apiFetch(
      buildDetailPath(REPORT_ID),
      validators.adminReportDetail,
    );
    expect(res.report.id).toBe(sampleDetailResponse.report.id);
    expect(res.report.evidenceFiles).toHaveLength(2);
  });

  it('throws ApiError(404) when the report is missing', async () => {
    server.use(
      http.get(`*/admin/reports/${REPORT_ID}`, () =>
        HttpResponse.json({ error: 'Not found' }, { status: 404 }),
      ),
    );
    try {
      await apiFetch(buildDetailPath(REPORT_ID), validators.adminReportDetail);
      throw new Error('expected apiFetch to throw');
    } catch (err) {
      expect(err).toBeInstanceOf(ApiError);
      expect((err as ApiError).status).toBe(404);
    }
  });

  it('throws SCHEMA_MISMATCH when response shape is invalid', async () => {
    server.use(
      http.get(`*/admin/reports/${REPORT_ID}`, () =>
        HttpResponse.json({ report: { id: 'not-a-uuid' } }),
      ),
    );
    try {
      await apiFetch(buildDetailPath(REPORT_ID), validators.adminReportDetail);
      throw new Error('expected apiFetch to throw');
    } catch (err) {
      expect(err).toBeInstanceOf(ApiError);
      expect((err as ApiError).message).toBe('SCHEMA_MISMATCH');
    }
  });
});

describe('QueryClient defaults satisfy detail fetch', () => {
  it('caches the detail response under its key', async () => {
    const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    const data = await qc.fetchQuery({
      queryKey: ['moderation', 'detail', REPORT_ID],
      queryFn: () =>
        apiFetch(buildDetailPath(REPORT_ID), validators.adminReportDetail),
    });
    expect(data.report.title).toBe('Fake parcel SMS');
    expect(qc.getQueryData(['moderation', 'detail', REPORT_ID])).toBeTruthy();
  });
});
