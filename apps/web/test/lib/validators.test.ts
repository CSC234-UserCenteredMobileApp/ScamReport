import { describe, it, expect } from 'vitest';
import { validators } from '@/lib/api/validators';
import { sampleQueue, adminSyncResponse } from '../mocks/handlers';

describe('precompiled validators', () => {
  it('adminQueue accepts a valid AdminQueueResponse', () => {
    expect(validators.adminQueue.Check(sampleQueue)).toBe(true);
  });

  it('adminQueue rejects a response with wrong types', () => {
    const bad = { ...sampleQueue, pendingCount: 'one' };
    expect(validators.adminQueue.Check(bad)).toBe(false);
  });

  it('authSync accepts a valid AuthSyncResponse', () => {
    expect(validators.authSync.Check(adminSyncResponse)).toBe(true);
  });

  it('adminAction validates the action response shape', () => {
    expect(
      validators.adminAction.Check({
        id: '11111111-1111-1111-1111-111111111111',
        status: 'verified',
        updatedAt: new Date().toISOString(),
      }),
    ).toBe(true);
  });
});
