import { describe, it, expect, vi, beforeEach } from 'vitest';
import { http, HttpResponse } from 'msw';
import { Type } from '@sinclair/typebox';
import { TypeCompiler } from '@sinclair/typebox/compiler';
import { server } from '../mocks/server';
import { apiFetch, ApiError } from '@/lib/api/client';
import { firebaseAuth } from '@/lib/auth/firebase';

const PingSchema = Type.Object({ ok: Type.Boolean() });
const pingChecker = TypeCompiler.Compile(PingSchema);

const baseUrl = 'http://localhost:3000';

const signOutMock = vi.fn(async () => undefined);

vi.spyOn(firebaseAuth, 'signOut').mockImplementation(() => signOutMock());

function stubCurrentUser(token: string | null) {
  Object.defineProperty(firebaseAuth, 'currentUser', {
    configurable: true,
    get: () =>
      token === null
        ? null
        : {
            getIdToken: vi.fn(async () => token),
          },
  });
}

beforeEach(() => {
  signOutMock.mockClear();
  stubCurrentUser(null);
});

describe('apiFetch', () => {
  it('attaches Authorization: Bearer when a Firebase user is present', async () => {
    stubCurrentUser('the-token');
    const seen: Record<string, string> = {};
    server.use(
      http.get(`${baseUrl}/ping`, ({ request }) => {
        seen.auth = request.headers.get('Authorization') ?? '';
        return HttpResponse.json({ ok: true });
      }),
    );

    const result = await apiFetch('/ping', pingChecker);
    expect(result).toEqual({ ok: true });
    expect(seen.auth).toBe('Bearer the-token');
  });

  it('omits Authorization when there is no Firebase user', async () => {
    const seen: Record<string, string | null> = {};
    server.use(
      http.get(`${baseUrl}/ping`, ({ request }) => {
        seen.auth = request.headers.get('Authorization');
        return HttpResponse.json({ ok: true });
      }),
    );
    await apiFetch('/ping', pingChecker);
    expect(seen.auth).toBeNull();
  });

  it('on 401 calls firebaseAuth.signOut() and throws ApiError(401)', async () => {
    server.use(http.get(`${baseUrl}/ping`, () => new HttpResponse(null, { status: 401 })));
    await expect(apiFetch('/ping', pingChecker)).rejects.toBeInstanceOf(ApiError);
    expect(signOutMock).toHaveBeenCalledOnce();
  });

  it('on 403 throws ApiError(403, FORBIDDEN) without signOut', async () => {
    server.use(http.get(`${baseUrl}/ping`, () => new HttpResponse(null, { status: 403 })));
    await expect(apiFetch('/ping', pingChecker)).rejects.toMatchObject({
      status: 403,
      message: 'FORBIDDEN',
    });
    expect(signOutMock).not.toHaveBeenCalled();
  });

  it('on 500 throws ApiError(500) and surfaces the body', async () => {
    server.use(
      http.get(`${baseUrl}/ping`, () =>
        HttpResponse.json({ error: 'boom' }, { status: 500 }),
      ),
    );
    await expect(apiFetch('/ping', pingChecker)).rejects.toMatchObject({
      status: 500,
      body: { error: 'boom' },
    });
  });

  it('on shape mismatch throws ApiError(0, SCHEMA_MISMATCH) via the TypeBox checker', async () => {
    server.use(http.get(`${baseUrl}/ping`, () => HttpResponse.json({ ok: 'yes' })));
    await expect(apiFetch('/ping', pingChecker)).rejects.toMatchObject({
      status: 0,
      message: 'SCHEMA_MISMATCH',
    });
  });
});
