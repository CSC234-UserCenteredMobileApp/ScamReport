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
//
// `as: 'scoped'` is what makes the derived `user` field visible to consumers
// that compose this plugin via `.use(...)`. Without it, the derive is "local"
// and the consumer's handlers don't see `user` in their typed context.
export const authMiddleware = new Elysia({ name: 'auth' }).derive(
  { as: 'scoped' },
  async ({ headers }): Promise<{ user: AuthUser | null }> => ({
    user: await verifyBearer(headers.authorization),
  }),
);

// Use this on routes that must reject unauthenticated callers. Inside
// handlers `user` is typed `AuthUser | null` but is non-null at runtime
// because onBeforeHandle short-circuits with 401 when missing.
export const requireAuth = new Elysia({ name: 'auth-required' })
  .derive(
    { as: 'scoped' },
    async ({ headers }): Promise<{ user: AuthUser | null }> => ({
      user: await verifyBearer(headers.authorization),
    }),
  )
  .onBeforeHandle({ as: 'scoped' }, ({ user, set }) => {
    if (!user) {
      set.status = 401;
      return { error: 'Unauthorized' };
    }
  });
