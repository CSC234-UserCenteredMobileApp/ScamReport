// Dev helper: promote a Firebase account to `admin` in Postgres.
//
// Usage (from repo root):
//
//   bun run --filter @my-product/api promote-admin <firebase-uid-or-email>
//
// Examples:
//
//   bun run --filter @my-product/api promote-admin alice@example.com
//   bun run --filter @my-product/api promote-admin abc123xyz
//
// Looks the row up by `firebaseUid` first, then by `email`. Sets
// `users.role = 'admin'` and prints the resulting row. If no row exists
// (the user has never signed in / `/auth/sync` has not run for them) the
// script exits non-zero with a hint.
//
// NOT for production promotion. Production must go through a SQL audit
// trail in the Supabase console — see HOW_TO_CONTRIBUTE.md §3.1.

import 'dotenv/config';
import { getPrisma } from '../src/core/db/client';

async function main(): Promise<void> {
  const arg = process.argv[2]?.trim();
  if (!arg) {
    console.error('usage: promote-admin <firebase-uid-or-email>');
    process.exit(2);
  }

  const prisma = getPrisma();
  const looksLikeEmail = arg.includes('@');

  const existing = looksLikeEmail
    ? await prisma.user.findUnique({ where: { email: arg } })
    : await prisma.user.findUnique({ where: { firebaseUid: arg } });

  if (!existing) {
    console.error(
      `[promote-admin] no users row matched ${looksLikeEmail ? 'email' : 'firebaseUid'}=${arg}.`,
    );
    console.error(
      '[promote-admin] the user must sign in once (so /auth/sync creates their users row) before promotion.',
    );
    process.exit(1);
  }

  if (existing.role === 'admin') {
    console.log(`[promote-admin] ${arg} is already admin (id=${existing.id}). no-op.`);
    return;
  }

  const updated = await prisma.user.update({
    where: { id: existing.id },
    data: { role: 'admin' },
    select: { id: true, firebaseUid: true, email: true, role: true },
  });

  console.log('[promote-admin] promoted:', updated);
}

main()
  .catch((err) => {
    console.error('[promote-admin] failed:', err);
    process.exit(1);
  })
  .finally(async () => {
    await getPrisma().$disconnect();
  });
