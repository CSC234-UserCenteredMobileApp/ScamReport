import { Elysia } from 'elysia';
import { getAuth } from 'firebase-admin/auth';
import { getFirebaseAdmin } from '../firebase/admin';

export type Role = 'user' | 'admin';

export type AuthUserWithRole = {
  uid: string;
  email: string | null;
  role: Role;
};

// Verifies the Firebase ID token and reads the `role` custom claim.
// Returns null when the header is missing, malformed, or fails verification.
async function verifyBearerWithRole(
  authHeader: string | undefined,
): Promise<AuthUserWithRole | null> {
  if (!authHeader?.startsWith('Bearer ')) return null;
  const token = authHeader.slice('Bearer '.length).trim();
  if (!token) return null;
  try {
    const decoded = await getAuth(getFirebaseAdmin()).verifyIdToken(token);
    const claimRole = decoded['role'];
    const role: Role = claimRole === 'admin' ? 'admin' : 'user';
    return { uid: decoded.uid, email: decoded.email ?? null, role };
  } catch {
    return null;
  }
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
