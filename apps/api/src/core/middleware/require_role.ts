import { Elysia } from 'elysia';
import { getAuth } from 'firebase-admin/auth';
import { getFirebaseAdmin } from '../firebase/admin';
import { getPrisma } from '../db/client';

export type Role = 'user' | 'admin';

export type AuthUserWithRole = {
  uid: string;
  email: string | null;
  role: Role;
};

// Verifies the Firebase ID token and resolves the caller's role from the
// canonical source of truth: the `users.role` enum in Postgres
// (DATABASE_DESIGN §4.1). Firebase custom claims are intentionally NOT used
// — admin promotion is a single SQL update, with no token-refresh dance and
// no dual-write surface.
//
// Returns null when the Authorization header is missing/malformed or when
// `verifyIdToken` throws (expired, malformed, revoked, untrusted issuer).
// When the token verifies but no `users` row exists yet (e.g. /auth/sync
// has not run for this account), the caller is treated as a regular `user`
// — admin-gated endpoints will 403, which is the correct response.
async function verifyBearerWithRole(
  authHeader: string | undefined,
): Promise<AuthUserWithRole | null> {
  if (!authHeader?.startsWith('Bearer ')) return null;
  const token = authHeader.slice('Bearer '.length).trim();
  if (!token) return null;
  let decoded;
  try {
    decoded = await getAuth(getFirebaseAdmin()).verifyIdToken(token);
  } catch {
    return null;
  }
  const row = await getPrisma().user.findUnique({
    where: { firebaseUid: decoded.uid },
    select: { role: true },
  });
  const role: Role = row?.role === 'admin' ? 'admin' : 'user';
  return { uid: decoded.uid, email: decoded.email ?? null, role };
}

// Compose this on any Elysia route group that must be reachable only by users
// with a specific role. Usage:
//
//   import { requireRole } from '../../core/middleware/require_role';
//   import { Elysia } from 'elysia';
//
//   export const adminReports = new Elysia({ prefix: '/admin/reports' })
//     .use(requireRole('admin'))
//     .get('/', ({ user }) => listForAdmin(user));
//
// Behaviour:
//   missing / malformed token            -> 401 { error: 'Unauthorized' }
//   verified but role != required        -> 403 { error: 'Forbidden' }
//   verified and role == required        -> handler runs, `user` typed as
//                                            AuthUserWithRole
//
// 'admin' is treated as a superset: a route requiring 'user' also accepts
// admins, mirroring how customer-facing endpoints work in production.
export function requireRole(required: Role) {
  return new Elysia({ name: `auth-role-${required}` })
    .derive(
      { as: 'scoped' },
      async ({
        headers,
      }): Promise<{ user: AuthUserWithRole | null }> => ({
        user: await verifyBearerWithRole(headers.authorization),
      }),
    )
    .onBeforeHandle({ as: 'scoped' }, ({ user, set }) => {
      if (!user) {
        set.status = 401;
        return { error: 'Unauthorized' };
      }
      const ok =
        required === 'user'
          ? user.role === 'user' || user.role === 'admin'
          : user.role === 'admin';
      if (!ok) {
        set.status = 403;
        return { error: 'Forbidden' };
      }
    });
}
