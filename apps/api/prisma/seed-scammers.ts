// Seed mock scammer profiles + identifiers, then backfill reports.scammer_id
// from the existing seeded reports. Idempotent: re-running upserts by alias
// and re-runs the backfill harmlessly.
//
// Run from apps/api: bun run prisma/seed-scammers.ts

import { PrismaPg } from '@prisma/adapter-pg';
import { config } from 'dotenv';
import { resolve } from 'path';
import { PrismaClient, ScammerIdentifierKind, ScammerRiskLevel } from '../src/generated/prisma/client.js';

config({ path: resolve(import.meta.dirname, '../.env') });

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });

type SeedIdentifier = {
  kind: ScammerIdentifierKind;
  valueRaw: string;
  valueNormalized: string;
};

type SeedScammer = {
  displayName: string;
  suspectedName: string | null;
  // When non-null, the scammer is linked to this Person row (created
  // upsert-by-fullName). Two scammers sharing personFullName end up under one
  // Person — demonstrating "one human runs many campaigns".
  personFullName: string | null;
  aliases: string[];
  riskLevel: ScammerRiskLevel;
  notes: string;
  identifiers: SeedIdentifier[];
};

// Mock offenders. Identifiers are aligned with seed-reports.ts so the backfill
// matches existing rows by `target_identifier_normalized`.
const SEEDS: SeedScammer[] = [
  {
    displayName: 'Revenue Dept Impersonator',
    suspectedName: 'Khun Somchai Wongchai',
    personFullName: 'Khun Somchai Wongchai',
    aliases: ['Officer Anan'],
    riskLevel: 'high',
    notes:
      'Cold-calls victims claiming unpaid tax penalties; demands transfers to a "verification" account. Caller introduces himself as "Khun Somchai Wongchai".',
    identifiers: [
      { kind: 'phone', valueRaw: '+66 2 999 1234', valueNormalized: '+6629991234' },
    ],
  },
  {
    // Second campaign run by the SAME person as the Revenue Dept Impersonator.
    // Demonstrates 1 person → N scammer campaigns through Scammer.personId.
    displayName: 'Customs Duty Scam Caller',
    suspectedName: 'Khun Somchai Wongchai',
    personFullName: 'Khun Somchai Wongchai',
    aliases: ['Customs Officer Somchai'],
    riskLevel: 'high',
    notes:
      'Same caller as the Revenue Dept campaign; pivots to claiming an undeclared import incurred customs duty. Demands a transfer to release the parcel.',
    identifiers: [
      { kind: 'phone', valueRaw: '+66 2 999 5678', valueNormalized: '+6629995678' },
    ],
  },
  {
    displayName: 'Kerry Parcel Phisher',
    suspectedName: null,
    personFullName: null,
    aliases: ['Kerry Express Notify'],
    riskLevel: 'high',
    notes:
      'Sends SMS claiming undelivered parcels; link redirects to a cloned Kerry login page that captures credentials. Anonymous campaign — no caller name surfaced.',
    identifiers: [
      {
        kind: 'url',
        valueRaw: 'https://kerry-th.delivery-check.co',
        valueNormalized: 'kerry-th.delivery-check.co',
      },
    ],
  },
  {
    displayName: 'IG Marketplace Ghost',
    suspectedName: null,
    personFullName: null,
    aliases: ['Best Deals TH', 'IG iPhone Reseller'],
    riskLevel: 'medium',
    notes:
      'Operates Instagram storefronts with cloned product photos; collects bank transfers and blocks buyers after payment.',
    // Note: instagram.com host alone matches every IG profile; tracked via the
    // social handle instead. The IG seeded report won't auto-link by URL —
    // moderator would assign on approval.
    identifiers: [
      {
        kind: 'social_handle',
        valueRaw: '@best-deals-th',
        valueNormalized: '@best-deals-th',
      },
    ],
  },
  {
    displayName: 'SCB Fraud-Team Caller',
    suspectedName: 'Khun Niran Thanachai',
    personFullName: 'Khun Niran Thanachai',
    aliases: [],
    riskLevel: 'high',
    notes:
      'Impersonates SCB fraud desk; convinces victims to share OTPs to "block" suspicious transactions, then drains the account. Caller introduces himself as "Khun Niran Thanachai".',
    identifiers: [
      { kind: 'phone', valueRaw: '+66 2 777 9000', valueNormalized: '+6627779000' },
    ],
  },
  {
    displayName: 'KTB Phishing Ring',
    suspectedName: null,
    personFullName: null,
    aliases: ['Krungthai Secure Login'],
    riskLevel: 'high',
    notes:
      'Phishing SMS warning of account suspension; landing page captures username, password, and PIN. Anonymous campaign.',
    identifiers: [
      {
        kind: 'url',
        valueRaw: 'https://ktb-secure-login.com',
        valueNormalized: 'ktb-secure-login.com',
      },
    ],
  },
  {
    displayName: 'QR Swap Crew',
    suspectedName: null,
    personFullName: null,
    aliases: ['Lazada Refund QR', 'PromptPay Sticker Crew'],
    riskLevel: 'medium',
    notes:
      'Distributes fake PromptPay QR codes (refunds, restaurant stickers); transfers route to mule accounts. Anonymous campaign.',
    identifiers: [],
  },
];

async function upsertPersons() {
  // Collect unique person names from the seed list and upsert one Person row
  // per name. Returns a map fullName → personId so upsertScammers can link.
  const fullNames = [
    ...new Set(SEEDS.map((s) => s.personFullName).filter((x): x is string => x !== null)),
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
  const byAlias = new Map<string, string>();
  for (const s of SEEDS) {
    // Match on displayName as a stable natural key — no unique constraint at
    // the DB level, but the seed list controls duplication.
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
    byAlias.set(s.displayName, row.id);

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
  return byAlias;
}

async function recomputePersonCounts() {
  // After scammers + reports are wired, refresh each Person's caches.
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
  // Match reports by target_identifier_normalized → scammer_identifiers.value_normalized.
  // Single SQL update keeps the backfill fast and idempotent.
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
  // Refresh report_count_cache + first_seen_at / last_seen_at on every scammer
  // from the linked reports table. Cheap; runs after backfill.
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
  const personByName = await upsertPersons();
  const byAlias = await upsertScammers(personByName);
  const updated = await backfillReportLinks();
  await recomputeReportCounts();
  await recomputePersonCounts();
  console.log(
    `seed-scammers: persons=${personByName.size} profiles=${byAlias.size} reports_linked=${updated}`,
  );
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
