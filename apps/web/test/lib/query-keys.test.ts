import { describe, it, expect } from 'vitest';
import { queryKeys } from '@/lib/api/query-keys';

describe('queryKeys', () => {
  it('moderation.queue is stable for the same params', () => {
    expect(
      queryKeys.moderation.queue({
        scam_type: 'phishing_sms',
        page: 1,
        page_size: 25,
      }),
    ).toEqual([
      'moderation',
      'queue',
      '',
      'all',
      'all',
      'all',
      'phishing_sms',
      1,
      25,
    ]);
  });

  it("moderation.queue defaults to 'all' when no filters are set", () => {
    expect(queryKeys.moderation.queue({ page: 1, page_size: 25 })).toEqual([
      'moderation',
      'queue',
      '',
      'all',
      'all',
      'all',
      'all',
      1,
      25,
    ]);
  });

  it('moderation.all is the namespace root', () => {
    expect(queryKeys.moderation.all).toEqual(['moderation']);
  });

  it('moderation.detail keys by id', () => {
    expect(queryKeys.moderation.detail('abc')).toEqual(['moderation', 'detail', 'abc']);
  });
});
