// Seed 25 synthetic users + consent + FCM devices.
//
// Why synthetic, not real Firebase Auth users:
//   Creating real Firebase users requires admin privileges on the Firebase
//   project AND would let anyone with the seed `firebase_uid` actually
//   sign in to the app — a security smell. Server-side flows only need a
//   resolvable `users.id`; the `firebase_uid` column is namespaced as
//   `synthetic-user-{n}` so it cannot collide with real Firebase UIDs.
//
//   Devs sign in with their own real Firebase account; the seed is for
//   read-side queue density + admin-flow exercise, not user-facing login.
//
// Side effects (all DB-only):
//   - users         (25 rows: 22 user + 3 admin)
//   - consent_records (×3 per user: registration / privacy_policy / terms_of_service)
//   - fcm_devices   (×1 per user: fake token, platform=android)

import { PrismaPg } from '@prisma/adapter-pg';
import { config } from 'dotenv';
import { resolve } from 'path';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { assertSafeToSeed } from './safety';

config({ path: resolve(import.meta.dirname, '../.env') });

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });

interface SyntheticUser {
  firebaseUid: string;
  email: string;
  displayName: string;
  role: 'user' | 'admin';
  preferredLanguage: 'th' | 'en';
}

function buildUsers(): SyntheticUser[] {
  // Thai first names + plausible @example.com emails. EN-locale users
  // sprinkled in (4 of 25).
  const regular: Array<[string, string, 'th' | 'en']> = [
    ['Somchai Wong', 'somchai.wong', 'th'],
    ['Niran Thanachai', 'niran.t', 'th'],
    ['Pim Chaiprasit', 'pim.cha', 'th'],
    ['Daeng Surasak', 'daeng.s', 'th'],
    ['Mali Saetang', 'mali.s', 'th'],
    ['Anan Phongphan', 'anan.p', 'th'],
    ['Suda Boonmee', 'suda.b', 'th'],
    ['Krit Thongchai', 'krit.t', 'th'],
    ['Ploy Sirisak', 'ploy.s', 'th'],
    ['Nuch Saengarun', 'nuch.s', 'th'],
    ['Tarn Korkiat', 'tarn.k', 'en'],
    ['Aof Wattana', 'aof.w', 'th'],
    ['Boom Sukhum', 'boom.s', 'th'],
    ['Mint Phongsri', 'mint.p', 'th'],
    ['Earth Chanchai', 'earth.c', 'en'],
    ['Top Thanawat', 'top.t', 'th'],
    ['Pang Jiraporn', 'pang.j', 'th'],
    ['Ice Vorawit', 'ice.v', 'en'],
    ['Bow Pacharin', 'bow.p', 'th'],
    ['Aim Patcharee', 'aim.p', 'th'],
    ['Fern Suchada', 'fern.s', 'th'],
    ['Gun Anuwat', 'gun.a', 'en'],
  ];

  const users: SyntheticUser[] = regular.map(([name, slug, lang], i) => ({
    firebaseUid: `synthetic-user-${i + 1}`,
    email: `${slug}@example.com`,
    displayName: name,
    role: 'user',
    preferredLanguage: lang,
  }));

  // Three admins. One has a known email so a dev can recognise it in the
  // admin web for spot checks.
  users.push(
    {
      firebaseUid: 'synthetic-admin-1',
      email: 'admin1@example.com',
      displayName: 'Admin Apinya',
      role: 'admin',
      preferredLanguage: 'th',
    },
    {
      firebaseUid: 'synthetic-admin-2',
      email: 'admin2@example.com',
      displayName: 'Admin Suriya',
      role: 'admin',
      preferredLanguage: 'th',
    },
    {
      firebaseUid: 'synthetic-admin-3',
      email: 'seed-admin@example.com',
      displayName: 'Admin Seed',
      role: 'admin',
      preferredLanguage: 'en',
    },
  );

  return users;
}

async function main() {
  await assertSafeToSeed();

  const users = buildUsers();
  let created = 0;
  const startedAt = new Date();

  for (const u of users) {
    // Spread createdAt across the last ~100 days for plausible registration history.
    const idx = users.indexOf(u);
    const createdAt = new Date(startedAt.getTime() - (100 - idx * 3) * 24 * 60 * 60 * 1000);
    const consentAt = new Date(createdAt.getTime() + 1000);

    const user = await prisma.user.upsert({
      where: { firebaseUid: u.firebaseUid },
      update: {},
      create: {
        firebaseUid: u.firebaseUid,
        email: u.email,
        displayName: u.displayName,
        role: u.role,
        preferredLanguage: u.preferredLanguage,
        createdAt,
        updatedAt: createdAt,
      },
      select: { id: true },
    });
    created++;

    // Consent records — three at registration time. first_report_submission
    // is recorded later by seed-flow when this user submits their first report.
    await prisma.consentRecord.createMany({
      data: [
        { userId: user.id, consentType: 'registration',     policyVersion: 'v1.0.0', acceptedAt: consentAt },
        { userId: user.id, consentType: 'privacy_policy',   policyVersion: 'v1.0.0', acceptedAt: consentAt },
        { userId: user.id, consentType: 'terms_of_service', policyVersion: 'v1.0.0', acceptedAt: consentAt },
      ],
      skipDuplicates: true,
    });

    // FCM device — one synthetic Android device per user. Real FCM sends
    // will fail-silent (verified non-fatal in notifications.service.ts:67-68).
    await prisma.fcmDevice.upsert({
      where: { fcmToken: `synthetic-fcm-${u.firebaseUid}` },
      update: {},
      create: {
        userId: user.id,
        fcmToken: `synthetic-fcm-${u.firebaseUid}`,
        platform: 'android',
        appVersion: '1.0.0-seed',
      },
    });
  }

  console.log(`seed-users: upserted=${created}`);
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
