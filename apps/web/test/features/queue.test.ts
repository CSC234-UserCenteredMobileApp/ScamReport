import { describe, it, expect } from 'vitest';
import { buildQueuePath } from '@/features/moderation/api/queue';

describe('buildQueuePath', () => {
  it('returns the bare path when no scam_type', () => {
    expect(buildQueuePath()).toBe('/admin/reports/queue');
  });

  it('encodes the scam_type query parameter', () => {
    expect(buildQueuePath('phishing_sms')).toBe(
      '/admin/reports/queue?scam_type=phishing_sms',
    );
  });

  it('encodes special characters', () => {
    expect(buildQueuePath('a b&c')).toBe(
      '/admin/reports/queue?scam_type=a%20b%26c',
    );
  });
});
