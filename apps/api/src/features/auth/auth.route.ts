import { Elysia } from 'elysia';
import { AuthSyncResponse } from '@my-product/shared';
import { requireAuth } from '../../core/middleware/auth.middleware';
import { getPrisma } from '../../core/db/client';

// POST /auth/sync
//
// Verifies the Bearer Firebase ID token (via requireAuth) and upserts the
// users row keyed on firebase_uid. Returns the synced application user so
// the mobile app knows our internal users.id (needed for any subsequent
// authenticated request that joins on user_id).
//
// Mobile flow:
//   1. FirebaseAuth.signIn / createUser → user.getIdToken()
//   2. POST /auth/sync with Authorization: Bearer <id_token>
//   3. Cache the returned AuthUser in currentUserProvider
export const authRoute = new Elysia()
  .use(requireAuth)
  .post(
    '/auth/sync',
    async ({ user }) => {
      const prisma = getPrisma();
      const synced = await prisma.user.upsert({
        where: { firebaseUid: user!.uid },
        create: {
          firebaseUid: user!.uid,
          email: user!.email,
        },
        update: {
          email: user!.email,
        },
      });
      return {
        user: {
          id: synced.id,
          firebaseUid: synced.firebaseUid,
          email: synced.email,
          displayName: synced.displayName,
          role: synced.role,
          preferredLanguage: synced.preferredLanguage,
        },
      };
    },
    { response: AuthSyncResponse },
  );
