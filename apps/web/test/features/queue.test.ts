import { describe, it, expect } from 'vitest';
import { buildQueuePath } from '@/features/moderation/api/queue';

const defaults = { page: 1, page_size: 25 } as const;

describe('buildQueuePath', () => {
  it('returns the bare path when no filters', () => {
    expect(buildQueuePath({ ...defaults })).toBe('/admin/reports/queue');
  });

  it('encodes the scam_type query parameter', () => {
    expect(buildQueuePath({ ...defaults, scam_type: 'phishing_sms' })).toBe(
      '/admin/reports/queue?scam_type=phishing_sms',
    );
  });

  it('encodes special characters in scam_type', () => {
    expect(buildQueuePath({ ...defaults, scam_type: 'a b&c' })).toBe(
      '/admin/reports/queue?scam_type=a+b%26c',
    );
  });

  it('omits defaults from the URL', () => {
    expect(
      buildQueuePath({
        ...defaults,
        status: 'all',
        confidence: 'all',
      }),
    ).toBe('/admin/reports/queue');
  });

  it('emits non-default page / page_size', () => {
    expect(buildQueuePath({ page: 2, page_size: 50 })).toBe(
      '/admin/reports/queue?page=2&page_size=50',
    );
  });

  it('emits filter params when set', () => {
    expect(
      buildQueuePath({
        ...defaults,
        q: 'phish',
        status: 'flagged',
        priority: 'true',
        confidence: 'high',
        scam_type: 'phishing_sms',
      }),
    ).toBe(
      '/admin/reports/queue?q=phish&status=flagged&priority=true&confidence=high&scam_type=phishing_sms',
    );
  });
});
