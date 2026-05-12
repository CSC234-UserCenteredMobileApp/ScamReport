import type { TSchema, Static } from '@sinclair/typebox';
import type { TypeCheck } from '@sinclair/typebox/compiler';
import { firebaseAuth } from '@/lib/auth/firebase';

const BASE = import.meta.env.VITE_API_BASE_URL ?? '';

export class ApiError extends Error {
  constructor(public status: number, message: string, public body?: unknown) {
    super(message);
    this.name = 'ApiError';
  }
}

export interface ApiFetchInit extends Omit<RequestInit, 'body'> {
  body?: unknown;
}

export async function apiFetch<S extends TSchema>(
  path: string,
  validator: TypeCheck<S>,
  init: ApiFetchInit = {},
): Promise<Static<S>> {
  const user = firebaseAuth.currentUser;
  const token = user ? await user.getIdToken() : null;

  const { body, headers, ...rest } = init;
  const res = await fetch(`${BASE}${path}`, {
    ...rest,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(headers ?? {}),
    },
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });

  if (res.status === 401) {
    await firebaseAuth.signOut().catch(() => undefined);
    throw new ApiError(401, 'UNAUTHORIZED');
  }
  if (res.status === 403) {
    throw new ApiError(403, 'FORBIDDEN');
  }
  if (!res.ok) {
    const errBody = await res.json().catch(() => undefined);
    throw new ApiError(res.status, `HTTP_${res.status}`, errBody);
  }

  const json = (await res.json()) as unknown;
  if (!validator.Check(json)) {
    const errors = [...validator.Errors(json)].slice(0, 5);
    throw new ApiError(0, 'SCHEMA_MISMATCH', errors);
  }
  return json as Static<S>;
}
