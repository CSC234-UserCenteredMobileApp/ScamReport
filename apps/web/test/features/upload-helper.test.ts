import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { Type } from '@sinclair/typebox';
import { TypeCompiler } from '@sinclair/typebox/compiler';
import { uploadWithProgress } from '@/lib/api/upload';
import { ApiError } from '@/lib/api/client';

interface FakeXhrInstance {
  readyState: number;
  status: number;
  responseText: string;
  open: ReturnType<typeof vi.fn>;
  setRequestHeader: ReturnType<typeof vi.fn>;
  send: ReturnType<typeof vi.fn>;
  abort: ReturnType<typeof vi.fn>;
  addEventListener: ReturnType<typeof vi.fn>;
  upload: { addEventListener: ReturnType<typeof vi.fn> };
  listeners: Record<string, Array<() => void>>;
}

const Schema = Type.Object({ ok: Type.Boolean() });
const checker = TypeCompiler.Compile(Schema);

let active: FakeXhrInstance;

beforeEach(() => {
  active = {
    readyState: 0,
    status: 0,
    responseText: '',
    open: vi.fn(),
    setRequestHeader: vi.fn(),
    send: vi.fn(),
    abort: vi.fn(),
    listeners: { load: [], error: [], abort: [] },
    addEventListener: vi.fn((event: string, handler: () => void) => {
      active.listeners[event] = active.listeners[event] ?? [];
      active.listeners[event]!.push(handler);
    }),
    upload: { addEventListener: vi.fn() },
  };
  vi.stubGlobal('XMLHttpRequest', vi.fn(() => active));
});

afterEach(() => {
  vi.unstubAllGlobals();
});

function fireLoad() {
  for (const fn of active.listeners.load ?? []) fn();
}
function fireError() {
  for (const fn of active.listeners.error ?? []) fn();
}

describe('uploadWithProgress', () => {
  it('resolves with the validated body on 200', async () => {
    const fd = new FormData();
    const promise = uploadWithProgress('/upload', fd, checker);
    active.status = 200;
    active.responseText = JSON.stringify({ ok: true });
    fireLoad();
    await expect(promise).resolves.toEqual({ ok: true });
  });

  it('rejects with ApiError(401) on unauthorized', async () => {
    const fd = new FormData();
    const promise = uploadWithProgress('/upload', fd, checker);
    active.status = 401;
    active.responseText = JSON.stringify({ error: 'no' });
    fireLoad();
    await expect(promise).rejects.toMatchObject({ status: 401 });
  });

  it('rejects with SCHEMA_MISMATCH when the response shape is wrong', async () => {
    const fd = new FormData();
    const promise = uploadWithProgress('/upload', fd, checker);
    active.status = 200;
    active.responseText = JSON.stringify({ ok: 'truthy' });
    fireLoad();
    await expect(promise).rejects.toMatchObject({ message: 'SCHEMA_MISMATCH' });
  });

  it('rejects with NETWORK_ERROR when the request errors', async () => {
    const fd = new FormData();
    const promise = uploadWithProgress('/upload', fd, checker);
    fireError();
    await expect(promise).rejects.toBeInstanceOf(ApiError);
  });
});
