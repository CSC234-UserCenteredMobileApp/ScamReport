import { Elysia, t } from 'elysia';
import { DeleteAccountResponse, CancelDeletionResponse } from '@my-product/shared';
import { requireAuth } from '../../core/middleware/auth.middleware';
import { resolveInternalUserId } from '../../core/lib/resolve-user';
import { getPrisma } from '../../core/db/client';

export const userRoute = new Elysia({ prefix: '/user' })
  .use(requireAuth)

  // POST /user/delete-account
  // Creates an AccountDeletionRequest with a 7-day purge window.
  // Idempotent: second call returns original timestamps (upsert with no-op update).
  .post(
    '/delete-account',
    async ({ user }) => {
      const prisma = getPrisma();
      const userId = await resolveInternalUserId(user!.uid, user!.email);
      const now = new Date();
      const purgeDueAt = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

      const row = await prisma.accountDeletionRequest.upsert({
        where: { userId },
        create: { userId, requestedAt: now, purgeDueAt },
        update: {},
        select: { requestedAt: true, purgeDueAt: true },
      });

      return {
        requestedAt: row.requestedAt.toISOString(),
        purgeDueAt: row.purgeDueAt.toISOString(),
      };
    },
    { response: DeleteAccountResponse },
  )

  // DELETE /user/delete-account
  // Cancels a pending deletion request (only if not yet purged).
  .delete(
    '/delete-account',
    async ({ user, set }) => {
      const prisma = getPrisma();
      const userId = await resolveInternalUserId(user!.uid, user!.email);

      const { count } = await prisma.accountDeletionRequest.deleteMany({
        where: { userId, purgedAt: null },
      });

      if (count === 0) {
        set.status = 404;
        return { error: 'No pending deletion request found' };
      }

      return { message: 'Account deletion request cancelled.' };
    },
    {
      response: {
        200: CancelDeletionResponse,
        404: t.Object({ error: t.String() }),
      },
    },
  );
