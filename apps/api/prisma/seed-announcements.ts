// Seed 6 announcements via the real createAnnouncement + publishAnnouncement
// service calls. Two of the six broadcast via FCM (sendPush=true), which
// stamps pushed_to_fcm_at; the FCM send itself fails-silent in dev since no
// real device tokens are registered.

import { PrismaPg } from '@prisma/adapter-pg';
import { config } from 'dotenv';
import { resolve } from 'path';
import { PrismaClient } from '../src/generated/prisma/client.js';
import {
  createAnnouncement,
  publishAnnouncement,
} from '../src/features/admin-announcements/admin-announcements.service';
import { assertSafeToSeed } from './safety';
import { ANNOUNCEMENTS } from './seed-fixtures';

config({ path: resolve(import.meta.dirname, '../.env') });

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });

async function loadFirstAdmin(): Promise<{ firebaseUid: string; email: string }> {
  const row = await prisma.user.findFirst({
    where: { firebaseUid: { startsWith: 'synthetic-admin-' }, role: 'admin' },
    select: { firebaseUid: true, email: true },
    orderBy: { createdAt: 'asc' },
  });
  if (!row) {
    throw new Error('seed-announcements: run seed-users.ts first — no synthetic admin found');
  }
  return { firebaseUid: row.firebaseUid, email: row.email ?? '' };
}

async function main() {
  await assertSafeToSeed();
  const admin = await loadFirstAdmin();
  let created = 0;
  let published = 0;

  for (const a of ANNOUNCEMENTS) {
    const draft = await createAnnouncement(admin.firebaseUid, admin.email, {
      title: a.title,
      body: a.body,
      category: a.category,
    });
    created++;

    const pub = await publishAnnouncement(draft.id, a.sendPush);
    if (pub) published++;
  }

  console.log(`seed-announcements: created=${created} published=${published}`);
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
