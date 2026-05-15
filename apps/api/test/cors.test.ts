import { describe, it, expect, mock } from 'bun:test';
import { app } from '../src/index';

mock.module('../src/core/firebase/admin', () => ({
  getFirebaseAdmin: () => ({}),
}));

mock.module('../src/core/firebase/messaging', () => ({
  sendFcmToUser: async () => {},
  sendFcmBroadcast: async () => {},
}));

const ALLOWED_LOCAL = 'http://localhost:5173';
const ALLOWED_PROD = 'https://scamreport-admin.vercel.app';
const ALLOWED_PREVIEW = 'https://scamreport-admin-feat-test.vercel.app';
const DISALLOWED = 'https://evil.example.com';

function preflight(origin: string): Request {
  return new Request('http://localhost/admin/reports/queue', {
    method: 'OPTIONS',
    headers: {
      Origin: origin,
      'Access-Control-Request-Method': 'GET',
      'Access-Control-Request-Headers': 'Authorization, Content-Type',
    },
  });
}

describe('CORS preflight allowlist for /admin/reports/queue', () => {
  it('allows http://localhost:5173 (dev)', async () => {
    const res = await app.handle(preflight(ALLOWED_LOCAL));
    expect([200, 204]).toContain(res.status);
    expect(res.headers.get('access-control-allow-origin')).toBe(ALLOWED_LOCAL);
    const headers = res.headers.get('access-control-allow-headers') ?? '';
    expect(headers.toLowerCase()).toContain('authorization');
    expect(headers.toLowerCase()).toContain('content-type');
  });

  it('allows the production Vercel domain', async () => {
    const res = await app.handle(preflight(ALLOWED_PROD));
    expect([200, 204]).toContain(res.status);
    expect(res.headers.get('access-control-allow-origin')).toBe(ALLOWED_PROD);
  });

  it('allows a project-scoped Vercel preview domain', async () => {
    const res = await app.handle(preflight(ALLOWED_PREVIEW));
    expect([200, 204]).toContain(res.status);
    expect(res.headers.get('access-control-allow-origin')).toBe(ALLOWED_PREVIEW);
  });

  it('rejects an unknown origin', async () => {
    const res = await app.handle(preflight(DISALLOWED));
    expect(res.headers.get('access-control-allow-origin')).not.toBe(DISALLOWED);
  });
});
