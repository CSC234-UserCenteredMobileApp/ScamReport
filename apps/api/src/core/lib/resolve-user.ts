// Resolves the internal users.id (UUID) from the Firebase UID carried on the
// auth-middleware context. Every Postgres FK that points at a user uses the
// internal users.id, not the Firebase subject — see auth.route.ts /auth/sync.
//
// Mobile is expected to have called POST /auth/sync at sign-in, so the row
// exists. As a safety net we upsert the row here on first call so a stale
// cache or a missed sync doesn't 404 the user out of the rest of the app.

import { getPrisma } from '../db/client';

export class UserNotProvisionedError extends Error {
  constructor(firebaseUid: string) {
    super(`No users row for firebase_uid=${firebaseUid}; call /auth/sync first.`);
    this.name = 'UserNotProvisionedError';
  }
}

export async function resolveInternalUserId(
  firebaseUid: string,
  email: string | null,
): Promise<string> {
  const prisma = getPrisma();
  // Upsert keeps the call idempotent. If /auth/sync has already created the
  // row, this is effectively a SELECT (the WHERE matches and `update` is a
  // no-op refresh of the email cache).
  const row = await prisma.user.upsert({
    where: { firebaseUid },
    create: { firebaseUid, email: email ?? undefined },
    update: { email: email ?? undefined },
    select: { id: true },
  });
  return row.id;
}
