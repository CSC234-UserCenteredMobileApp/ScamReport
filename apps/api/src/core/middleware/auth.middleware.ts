import { Elysia } from 'elysia';
import { getAuth } from 'firebase-admin/auth';
import { getFirebaseAdmin } from '../firebase/admin';

export type AuthUser = { uid: string; email: string | null };

async function verifyBearer(
  authHeader: string | undefined,
): Promise<AuthUser | null> {
  if (!authHeader?.startsWith('Bearer ')) return null;
  const token = authHeader.slice('Bearer '.length).trim();
  if (!token) return null;
  try {
    const decoded = await getAuth(getFirebaseAdmin()).verifyIdToken(token);
    return { uid: decoded.uid, email: decoded.email ?? null };
  } catch {
    return null;
  }
}

// Decodes the Authorization: Bearer <id-token> header if present.
// On success the request gains a `user` field; otherwise `user` is null.
// Routes that *require* auth should compose `requireAuth` instead.
export const authMiddleware = new Elysia({ name: 'auth' }).derive(
  async ({ headers }): Promise<{ user: AuthUser | null }> => ({
    user: await verifyBearer(headers.authorization),
  }),
);

// Use this on routes that must reject unauthenticated callers.
// Derives `user` itself (Elysia doesn't propagate `.derive()` state through
// `.use()` to chained hooks), so importers don't need to pull both plugins.
export const requireAuth = new Elysia({ name: 'auth-required' })
  .derive(
    async ({ headers }): Promise<{ user: AuthUser | null }> => ({
      user: await verifyBearer(headers.authorization),
    }),
  )
  .onBeforeHandle(({ user, set }) => {
    if (!user) {
      set.status = 401;
      return { error: 'Unauthorized' };
    }
  });
