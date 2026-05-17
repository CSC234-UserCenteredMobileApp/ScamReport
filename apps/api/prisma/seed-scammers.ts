// Seed scammer profiles + identifiers from the shared fixtures module, then
// backfill reports.scammer_id from reports already in the DB (matched via
// target_identifier_normalized).
//
// Idempotent: re-running upserts by displayName and re-runs the backfill harmlessly.
//
// Run from apps/api: bun run prisma/seed-scammers.ts

import { PrismaPg } from '@prisma/adapter-pg';
import { config } from 'dotenv';
import { resolve } from 'path';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { assertSafeToSeed } from './safety';
import { SCAMMERS } from './seed-fixtures';

config({ path: resolve(import.meta.dirname, '../.env') });

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });

async function upsertPersons() {
  const fullNames = [
    ...new Set(SCAMMERS.map((s) => s.personFullName).filter((x): x is string => x !== null)),
  ];
  const byName = new Map<string, string>();
  for (const fullName of fullNames) {
    const existing = await prisma.person.findFirst({
      where: { fullName },
      select: { id: true },
    });
    if (existing) {
      byName.set(fullName, existing.id);
    } else {
      const row = await prisma.person.create({
        data: { fullName, riskLevel: 'high' },
        select: { id: true },
      });
      byName.set(fullName, row.id);
    }
  }
  return byName;
}

async function upsertScammers(personByName: Map<string, string>) {
  const byName = new Map<string, string>();
  for (const s of SCAMMERS) {
    const existing = await prisma.scammer.findFirst({
      where: { displayName: s.displayName },
      select: { id: true },
    });
    const data = {
      displayName: s.displayName,
      suspectedName: s.suspectedName,
      personId: s.personFullName ? personByName.get(s.personFullName) ?? null : null,
      aliases: s.aliases,
      riskLevel: s.riskLevel,
      notes: s.notes,
    };
    const row = existing
      ? await prisma.scammer.update({ where: { id: existing.id }, data })
      : await prisma.scammer.create({ data });
    byName.set(s.displayName, row.id);

    for (const id of s.identifiers) {
      await prisma.scammerIdentifier.upsert({
        where: {
          kind_valueNormalized: { kind: id.kind, valueNormalized: id.valueNormalized },
        },
        update: { scammerId: row.id, valueRaw: id.valueRaw },
        create: {
          scammerId: row.id,
          kind: id.kind,
          valueRaw: id.valueRaw,
          valueNormalized: id.valueNormalized,
        },
      });
    }
  }
  return byName;
}

async function recomputePersonCounts() {
  await prisma.$executeRaw`
    UPDATE persons p
    SET
      campaign_count_cache = COALESCE(c.cnt, 0),
      report_count_cache   = COALESCE(c.report_cnt, 0),
      first_seen_at        = c.first_seen,
      last_seen_at         = c.last_seen
    FROM (
      SELECT s.person_id,
             COUNT(*)::int                                  AS cnt,
             COALESCE(SUM(s.report_count_cache), 0)::int    AS report_cnt,
             MIN(s.first_seen_at)                            AS first_seen,
             MAX(s.last_seen_at)                             AS last_seen
      FROM scammers s
      WHERE s.person_id IS NOT NULL
      GROUP BY s.person_id
    ) AS c
    WHERE c.person_id = p.id
  `;
}

async function backfillReportLinks() {
  const updated = await prisma.$executeRaw`
    UPDATE reports r
    SET scammer_id = si.scammer_id
    FROM scammer_identifiers si
    WHERE r.scammer_id IS NULL
      AND r.target_identifier_normalized IS NOT NULL
      AND r.target_identifier_normalized = si.value_normalized
  `;
  return Number(updated);
}

async function recomputeReportCounts() {
  await prisma.$executeRaw`
    UPDATE scammers s
    SET
      report_count_cache = COALESCE(agg.cnt, 0),
      first_seen_at      = agg.first_seen,
      last_seen_at       = agg.last_seen
    FROM (
      SELECT scammer_id,
             COUNT(*)::int AS cnt,
             MIN(created_at) AS first_seen,
             MAX(COALESCE(verified_at, updated_at)) AS last_seen
      FROM reports
      WHERE scammer_id IS NOT NULL
      GROUP BY scammer_id
    ) agg
    WHERE s.id = agg.scammer_id
  `;
}

async function main() {
  await assertSafeToSeed();

  const personByName = await upsertPersons();
  const byName = await upsertScammers(personByName);
  const updated = await backfillReportLinks();
  await recomputeReportCounts();
  await recomputePersonCounts();
  console.log(
    `seed-scammers: persons=${personByName.size} profiles=${byName.size} reports_linked=${updated}`,
  );
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
