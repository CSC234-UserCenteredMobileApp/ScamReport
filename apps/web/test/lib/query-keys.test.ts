import { describe, it, expect } from 'vitest';
import { queryKeys } from '@/lib/api/query-keys';

describe('queryKeys', () => {
  it('moderation.queue is stable for the same scam type', () => {
    expect(queryKeys.moderation.queue('phishing_sms')).toEqual([
      'moderation',
      'queue',
      'phishing_sms',
    ]);
  });

  it("moderation.queue defaults to 'all' when no scam type", () => {
    expect(queryKeys.moderation.queue()).toEqual(['moderation', 'queue', 'all']);
  });

  it('moderation.all is the namespace root', () => {
    expect(queryKeys.moderation.all).toEqual(['moderation']);
  });

  it('moderation.detail keys by id', () => {
    expect(queryKeys.moderation.detail('abc')).toEqual(['moderation', 'detail', 'abc']);
  });
});
