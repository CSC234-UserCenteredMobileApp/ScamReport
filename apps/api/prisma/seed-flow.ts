// Drive the real submission + moderation flow for every seeded scenario.
//
// This is the "fix" for the previous bad-data state. Instead of inserting
// reports rows directly, we import the service-layer functions and call
// them like the HTTP handlers would. That triggers EVERY downstream
// side effect: aiScore computation, scammer auto-link, Firestore mirror,
// moderation_actions audit insert, notifications, FCM (silently fails),
// reportCountCache updates.
//
// After the per-scenario loop, a backdate transaction temporarily disables
// the `reports_set_updated_at` and `moderation_actions_no_update` triggers
// (production-runtime invariants — restored before COMMIT) so timestamps
// can be spread across the last 90 days for realistic queue density.
//
// Run from apps/api: bun run prisma/seed-flow.ts

import { PrismaPg } from '@prisma/adapter-pg';
import { config } from 'dotenv';
import { resolve } from 'path';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { createReport } from '../src/features/reports/reports.service';
import {
  approveReport,
  rejectReport,
  flagReport,
  unflagReport,
} from '../src/features/admin-reports/admin-reports.service';
import { assertSafeToSeed } from './safety';
import { REPORT_SCENARIOS, type ReportScenario } from './seed-fixtures';

config({ path: resolve(import.meta.dirname, '../.env') });

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });

// Mapping from fixture-level scamTypeCode → DB scam_types.code (they match
// 1:1 with the migration seed; included as a guard against future drift).
const VALID_CODES = new Set([
  'phone_impersonation',
  'phishing_sms',
  'fake_qr',
  'ecommerce_fraud',
  'other',
  'investment_fraud',
  'romance_scam',
]);

interface Pools {
  reporters: string[]; // user.id of role='user'
  admins: string[];    // user.id of role='admin'
}

async function loadPools(): Promise<Pools> {
  const users = await prisma.user.findMany({
    where: { firebaseUid: { startsWith: 'synthetic-' } },
    select: { id: true, role: true },
    orderBy: { createdAt: 'asc' },
  });
  const reporters = users.filter((u) => u.role === 'user').map((u) => u.id);
  const admins = users.filter((u) => u.role === 'admin').map((u) => u.id);
  if (reporters.length === 0 || admins.length === 0) {
    throw new Error('seed-flow: run seed-users.ts first — no synthetic users found');
  }
  return { reporters, admins };
}

async function submitOne(scenario: ReportScenario, reporterId: string) {
  if (!VALID_CODES.has(scenario.scamTypeCode)) {
    throw new Error(`seed-flow: unknown scamTypeCode "${scenario.scamTypeCode}" — fix fixtures`);
  }
  return createReport(reporterId, {
    title: scenario.title,
    description: scenario.description,
    scamTypeCode: scenario.scamTypeCode,
    targetIdentifier: scenario.identifier ?? null,
    targetIdentifierKind: scenario.identifierKind ?? null,
    suspectedScammerName: scenario.suspectedNameAtSubmit ?? null,
    evidenceFiles: [],
  });
}

async function moderate(
  reportId: string,
  scenario: ReportScenario,
  adminId: string,
  remark: string,
) {
  if (scenario.action === 'pending') return;
  if (scenario.doubleAction && scenario.action === 'approve') {
    // Flag → unflag → approve sequence for audit-trail variety.
    await flagReport(reportId, adminId, 'Flagged for second opinion — pattern matches multiple campaigns');
    await unflagReport(reportId, adminId, 'Second moderator concurred — proceeding to approve');
  }
  switch (scenario.action) {
    case 'approve':
      await approveReport(reportId, adminId, remark);
      break;
    case 'flag':
      await flagReport(reportId, adminId, remark);
      break;
    case 'reject':
      await rejectReport(reportId, adminId, remark);
      break;
  }
}

function remarkFor(scenario: ReportScenario): string {
  switch (scenario.action) {
    case 'approve':
      return 'Verified against known scammer pattern + matching identifier.';
    case 'flag':
      return 'Holding for second opinion — uncertain identifier match.';
    case 'reject':
      return 'Insufficient evidence or appears legitimate on review.';
    default:
      return '';
  }
}

async function backdateTimestamps(reportIdsByDaysAgo: Array<{ id: string; daysAgo: number; action: ReportScenario['action'] }>) {
  // Precompute new timestamps in JS — keeps the tx short.
  const rows = reportIdsByDaysAgo.map((r) => {
    const created = new Date(Date.now() - r.daysAgo * 24 * 60 * 60 * 1000);
    const verifiedDelayMs = (15 + Math.random() * (24 * 60 - 15)) * 60 * 1000;
    const verified = r.action === 'approve' ? new Date(created.getTime() + verifiedDelayMs) : null;
    const updated = verified ?? created;
    return { id: r.id, created, updated, verified };
  });

  // Disable triggers in a single transaction; re-enable inside the same tx so
  // production invariants (updated_at auto-stamp, moderation_actions
  // append-only) are restored before any caller sees an interleaved state.
  await prisma.$transaction(async (tx) => {
    await tx.$executeRawUnsafe(`ALTER TABLE reports             DISABLE TRIGGER reports_set_updated_at`);
    await tx.$executeRawUnsafe(`ALTER TABLE moderation_actions  DISABLE TRIGGER moderation_actions_no_update`);

    // One bulk UPDATE via VALUES — finishes in <1s vs ~6s for 122
    // single-row updates over a pooler.
    if (rows.length > 0) {
      const placeholders = rows
        .map((_, i) => `($${i * 4 + 1}::uuid, $${i * 4 + 2}::timestamptz, $${i * 4 + 3}::timestamptz, $${i * 4 + 4}::timestamptz)`)
        .join(',');
      const params: unknown[] = [];
      for (const r of rows) {
        params.push(r.id, r.created.toISOString(), r.updated.toISOString(), r.verified ? r.verified.toISOString() : null);
      }
      await tx.$executeRawUnsafe(
        `UPDATE reports r
         SET created_at = u.c, updated_at = u.up, verified_at = u.v
         FROM (VALUES ${placeholders}) AS u(id, c, up, v)
         WHERE r.id = u.id`,
        ...params,
      );
    }

    // Pull moderation_actions in line with their parent report's window.
    // For each non-pending report: action's created_at ∈ [report.created_at + 15m,
    // verifiedAt or report.updated_at]. Random within that band.
    await tx.$executeRawUnsafe(`
      UPDATE moderation_actions ma
      SET created_at = r.created_at
                       + INTERVAL '15 minutes'
                       + (random() * GREATEST(
                            EXTRACT(EPOCH FROM (COALESCE(r.verified_at, r.updated_at) - r.created_at - INTERVAL '15 minutes')),
                            0
                         ) * INTERVAL '1 second')
      FROM reports r
      WHERE ma.report_id = r.id
    `);

    // Notifications follow their moderation_action's timestamp.
    await tx.$executeRawUnsafe(`
      UPDATE notifications n
      SET created_at = COALESCE(ma_latest.latest_at, n.created_at)
      FROM (
        SELECT report_id, MAX(created_at) AS latest_at
        FROM moderation_actions
        GROUP BY report_id
      ) ma_latest
      WHERE n.report_id = ma_latest.report_id
    `);

    await tx.$executeRawUnsafe(`ALTER TABLE moderation_actions  ENABLE TRIGGER moderation_actions_no_update`);
    await tx.$executeRawUnsafe(`ALTER TABLE reports             ENABLE TRIGGER reports_set_updated_at`);
  }, { timeout: 120_000, maxWait: 30_000 });
}

async function main() {
  await assertSafeToSeed();
  const { reporters, admins } = await loadPools();
  console.log(`seed-flow: pools = ${reporters.length} reporters / ${admins.length} admins / ${REPORT_SCENARIOS.length} scenarios`);

  const backdate: Array<{ id: string; daysAgo: number; action: ReportScenario['action'] }> = [];
  let submitErrors = 0;
  let modErrors = 0;

  for (let i = 0; i < REPORT_SCENARIOS.length; i++) {
    const s = REPORT_SCENARIOS[i]!;
    const reporterId = reporters[i % reporters.length]!;
    const adminId    = admins[i % admins.length]!;
    let reportId: string;
    try {
      const created = await submitOne(s, reporterId);
      reportId = created.id;
    } catch (err) {
      submitErrors++;
      console.error(`seed-flow: createReport failed for "${s.title}" — ${(err as Error).message}`);
      continue;
    }

    try {
      await moderate(reportId, s, adminId, remarkFor(s));
    } catch (err) {
      modErrors++;
      console.error(`seed-flow: moderation failed for "${s.title}" (action=${s.action}) — ${(err as Error).message}`);
    }

    backdate.push({ id: reportId, daysAgo: s.daysAgo, action: s.action });

    if ((i + 1) % 10 === 0) {
      process.stdout.write(`\rseed-flow: ${i + 1}/${REPORT_SCENARIOS.length} scenarios processed`);
    }
  }
  process.stdout.write('\n');

  console.log('seed-flow: backdating timestamps…');
  await backdateTimestamps(backdate);

  // Recompute scammer + person caches after the backdate so first_seen_at /
  // last_seen_at line up with the spread timestamps.
  await prisma.$executeRawUnsafe(`
    UPDATE scammers s
    SET report_count_cache = COALESCE(agg.cnt, 0),
        first_seen_at      = agg.first_seen,
        last_seen_at       = agg.last_seen
    FROM (
      SELECT scammer_id, COUNT(*)::int AS cnt,
             MIN(created_at) AS first_seen,
             MAX(COALESCE(verified_at, updated_at)) AS last_seen
      FROM reports
      WHERE scammer_id IS NOT NULL
      GROUP BY scammer_id
    ) agg
    WHERE s.id = agg.scammer_id
  `);

  console.log(`seed-flow: done. scenarios=${REPORT_SCENARIOS.length} submit_errors=${submitErrors} mod_errors=${modErrors}`);
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
