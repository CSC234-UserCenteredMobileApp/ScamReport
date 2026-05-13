import { describe, it, expect } from 'vitest';
import { http, HttpResponse } from 'msw';
import { apiFetch, ApiError } from '@/lib/api/client';
import { validators } from '@/lib/api/validators';
import { buildEvidenceUrlPath } from '@/features/moderation/api/evidence-url';
import { server } from '../mocks/server';
import { sampleEvidenceUrlResponse } from '../mocks/handlers';

const REPORT_ID = '11111111-1111-1111-1111-111111111111';
const FILE_ID = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

describe('admin evidence URL API', () => {
  it('returns the signed URL + expiresAt on 200', async () => {
    const res = await apiFetch(
      buildEvidenceUrlPath(REPORT_ID, FILE_ID),
      validators.adminEvidenceUrl,
    );
    expect(res.url).toBe(sampleEvidenceUrlResponse.url);
    expect(typeof res.expiresAt).toBe('string');
  });

  it('throws ApiError(404) when the file does not belong to the report', async () => {
    server.use(
      http.get(`*/admin/reports/${REPORT_ID}/evidence/${FILE_ID}/url`, () =>
        HttpResponse.json({ error: 'Not found' }, { status: 404 }),
      ),
    );
    try {
      await apiFetch(
        buildEvidenceUrlPath(REPORT_ID, FILE_ID),
        validators.adminEvidenceUrl,
      );
      throw new Error('expected apiFetch to throw');
    } catch (err) {
      expect(err).toBeInstanceOf(ApiError);
      expect((err as ApiError).status).toBe(404);
    }
  });

  it('throws SCHEMA_MISMATCH when the response body is malformed', async () => {
    server.use(
      http.get(`*/admin/reports/${REPORT_ID}/evidence/${FILE_ID}/url`, () =>
        HttpResponse.json({ url: 'not-a-real-url', expiresAt: 'nope' }),
      ),
    );
    try {
      await apiFetch(
        buildEvidenceUrlPath(REPORT_ID, FILE_ID),
        validators.adminEvidenceUrl,
      );
      throw new Error('expected apiFetch to throw');
    } catch (err) {
      expect(err).toBeInstanceOf(ApiError);
      expect((err as ApiError).message).toBe('SCHEMA_MISMATCH');
    }
  });
});
