// Post-seed sanity check. Exits non-zero on any failed invariant so the
// orchestrator surfaces silent flow gaps.
// Read-only.
//
// Run from apps/api: bun run prisma/verify-seed.ts

import { PrismaPg } from '@prisma/adapter-pg';
import { config } from 'dotenv';
import { resolve } from 'path';
import { PrismaClient } from '../src/generated/prisma/client.js';

config({ path: resolve(import.meta.dirname, '../.env') });

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });

interface Check {
  name: string;
  ok: boolean;
  detail: string;
}

const checks: Check[] = [];
function expect(name: string, ok: boolean, detail: string) {
  checks.push({ name, ok, detail });
}

const counts = await prisma.$queryRaw<
  {
    users: bigint;
    reports: bigint;
    linked: bigint;
    pending: bigint;
    verified: bigint;
    flagged: bigint;
    rejected: bigint;
    orphan_reporter: bigint;
    moderation_actions: bigint;
    notifications: bigint;
    consent_records: bigint;
    fcm_devices: bigint;
    check_logs: bigint;
    embeddings: bigint;
    ai_convs: bigint;
    ai_msgs: bigint;
    announcements: bigint;
    announcements_published: bigint;
    scammers: bigint;
    persons: bigint;
  }[]
>`
  SELECT
    (SELECT COUNT(*) FROM users)                                              AS users,
    (SELECT COUNT(*) FROM reports)                                            AS reports,
    (SELECT COUNT(*) FROM reports WHERE scammer_id IS NOT NULL)               AS linked,
    (SELECT COUNT(*) FROM reports WHERE status = 'pending')                   AS pending,
    (SELECT COUNT(*) FROM reports WHERE status = 'verified')                  AS verified,
    (SELECT COUNT(*) FROM reports WHERE status = 'flagged')                   AS flagged,
    (SELECT COUNT(*) FROM reports WHERE status = 'rejected')                  AS rejected,
    (SELECT COUNT(*) FROM reports WHERE reporter_id IS NULL)                  AS orphan_reporter,
    (SELECT COUNT(*) FROM moderation_actions)                                 AS moderation_actions,
    (SELECT COUNT(*) FROM notifications)                                      AS notifications,
    (SELECT COUNT(*) FROM consent_records)                                    AS consent_records,
    (SELECT COUNT(*) FROM fcm_devices)                                        AS fcm_devices,
    (SELECT COUNT(*) FROM check_logs)                                         AS check_logs,
    (SELECT COUNT(*) FROM report_embeddings)                                  AS embeddings,
    (SELECT COUNT(*) FROM ai_conversations)                                   AS ai_convs,
    (SELECT COUNT(*) FROM ai_messages)                                        AS ai_msgs,
    (SELECT COUNT(*) FROM announcements)                                      AS announcements,
    (SELECT COUNT(*) FROM announcements WHERE status = 'published')           AS announcements_published,
    (SELECT COUNT(*) FROM scammers)                                           AS scammers,
    (SELECT COUNT(*) FROM persons)                                            AS persons
`;
const c = counts[0]!;
const n = (b: bigint) => Number(b);

console.log('seed counts:', JSON.parse(JSON.stringify(c, (_, v) => typeof v === 'bigint' ? Number(v) : v)));

expect('users >= 25',                     n(c.users) >= 25,                        `users=${n(c.users)}`);
expect('reports >= 100',                  n(c.reports) >= 100,                     `reports=${n(c.reports)}`);
expect('verified >= 40',                  n(c.verified) >= 40,                     `verified=${n(c.verified)}`);
expect('zero orphan reporters',           n(c.orphan_reporter) === 0,              `orphan_reporter=${n(c.orphan_reporter)}`);
expect('moderation_actions ≥ non-pending',
  n(c.moderation_actions) >= n(c.verified) + n(c.flagged) + n(c.rejected),
  `moderation_actions=${n(c.moderation_actions)} vs non_pending=${n(c.verified) + n(c.flagged) + n(c.rejected)}`);
expect('notifications ≥ verified',        n(c.notifications) >= n(c.verified),     `notifications=${n(c.notifications)} verified=${n(c.verified)}`);
expect('consent_records = 3 × users',     n(c.consent_records) === 3 * n(c.users), `consent=${n(c.consent_records)} users=${n(c.users)}`);
expect('fcm_devices = users',             n(c.fcm_devices) === n(c.users),         `fcm=${n(c.fcm_devices)} users=${n(c.users)}`);
expect('check_logs >= 400',               n(c.check_logs) >= 400,                  `check_logs=${n(c.check_logs)}`);
expect('embeddings ≥ verified',           n(c.embeddings) >= n(c.verified),        `embeddings=${n(c.embeddings)} verified=${n(c.verified)}`);
expect('ai_conversations >= 10',          n(c.ai_convs) >= 10,                     `convs=${n(c.ai_convs)}`);
expect('ai_messages >= 35',               n(c.ai_msgs) >= 35,                      `msgs=${n(c.ai_msgs)}`);
expect('announcements published >= 6',    n(c.announcements_published) >= 6,       `published=${n(c.announcements_published)}`);
expect('scammers >= 12',                  n(c.scammers) >= 12,                     `scammers=${n(c.scammers)}`);

const perScammer = await prisma.$queryRaw<{ name: string; cases: bigint }[]>`
  SELECT s.display_name AS name, COUNT(r.id)::bigint AS cases
  FROM scammers s
  LEFT JOIN reports r ON r.scammer_id = s.id
  GROUP BY s.id
  ORDER BY cases DESC
`;
console.log('per scammer:');
for (const row of perScammer) console.log(`  ${row.name}: ${Number(row.cases)}`);

let failed = 0;
for (const ch of checks) {
  console.log(`  ${ch.ok ? 'OK  ' : 'FAIL'} — ${ch.name}  (${ch.detail})`);
  if (!ch.ok) failed++;
}

await prisma.$disconnect();

if (failed > 0) {
  console.error(`verify-seed: ${failed} check(s) failed`);
  process.exit(1);
}
console.log('verify-seed: all checks passed.');
