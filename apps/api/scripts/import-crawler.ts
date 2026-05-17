// Import news-crawler scam suspects into Postgres.
//
// Each crawler record maps to: Person + Scammer (+ ScammerIdentifiers) + a
// pre-verified Report row + a ModerationAction(approve) audit entry —
// mirroring the submit→approve flow a real user-submitted report goes
// through (see apps/api/src/features/reports/reports.service.ts and
// admin-reports.service.ts).
//
// Idempotent: keyed on `reports.source_url`. A record whose URL already
// exists is skipped; safe to re-run.
//
// Usage:
//   bun run apps/api/scripts/import-crawler.ts /abs/path/to/output.json
//   CRAWLER_OUTPUT_PATH=/abs/path bun run apps/api/scripts/import-crawler.ts

import { PrismaPg } from '@prisma/adapter-pg';
import { config } from 'dotenv';
import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { normalizePhone } from '../src/core/lib/identifier-extractor';

config({ path: resolve(import.meta.dirname, '..', '.env') });

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });

type CrawlerRecord = {
  firstname: string | null;
  lastname: string | null;
  aliases: string[] | null;
  personal_id: string | null;
  phone: string[] | null;
  bank_account: string[] | null;
  bank_name: string | null;
  company_name: string | null;
  total_money_lost: number | null;
  currency: string | null;
  num_victims: number | null;
  scam_type: string | null;
  description: string | null;
  arrest_status: string | null;
  province: string | null;
  nationality: string | null;
  source_url: string | null;
  source_site: string | null;
  scraped_at: string | null;
  article_title: string | null;
};

// Crawler scam_type → existing scam_types.code (after migration 20260518120000
// adds the `fake_job` row).
const SCAM_TYPE_MAP: Record<string, string> = {
  fake_investment: 'investment_fraud',
  call_center: 'phone_impersonation',
  impersonation: 'phone_impersonation',
  fake_job: 'fake_job',
  online_shopping: 'ecommerce_fraud',
  romance_scam: 'romance_scam',
  other: 'other',
};

function buildFullName(rec: CrawlerRecord): string | null {
  const first = rec.firstname?.trim();
  const last = rec.lastname?.trim();
  if (!first && !last) return null;
  return [first, last].filter(Boolean).join(' ').trim() || null;
}

function pickRiskLevel(rec: CrawlerRecord): 'low' | 'medium' | 'high' | 'unknown' {
  if (rec.arrest_status === 'arrested') return 'high';
  if (rec.arrest_status === 'wanted') return 'high';
  if (rec.arrest_status === 'fled') return 'medium';
  return 'medium';
}

function parseScrapedAt(raw: string | null | undefined): Date | null {
  if (!raw) return null;
  const d = new Date(raw);
  return Number.isNaN(d.getTime()) ? null : d;
}

function normalizeBankAccount(raw: string): string {
  return raw.replace(/\D/g, '');
}

type ScamTypeRef = { id: number; labelEn: string };

async function loadScamTypes(): Promise<Map<string, ScamTypeRef>> {
  const rows = await prisma.scamType.findMany({
    select: { id: true, code: true, labelEn: true },
  });
  return new Map(rows.map((r) => [r.code, { id: r.id, labelEn: r.labelEn }]));
}

async function importRecord(
  rec: CrawlerRecord,
  scamTypeByCode: Map<string, ScamTypeRef>,
): Promise<'imported' | 'skipped' | 'invalid'> {
  if (!rec.source_url) return 'invalid';

  // Idempotency: if any Report already has this source_url, skip.
  const existing = await prisma.report.findFirst({
    where: { sourceUrl: rec.source_url },
    select: { id: true },
  });
  if (existing) return 'skipped';

  const fullName = buildFullName(rec);
  if (!fullName) return 'invalid';

  const crawlerCode = rec.scam_type ?? 'other';
  const dbCode = SCAM_TYPE_MAP[crawlerCode] ?? 'other';
  const scamType = scamTypeByCode.get(dbCode);
  if (!scamType) return 'invalid';

  const scamTypeId = scamType.id;
  const scamTypeLabelEn = scamType.labelEn;
  const scrapedAt = parseScrapedAt(rec.scraped_at);
  const verifiedAt = scrapedAt ?? new Date();
  const aliases = (rec.aliases ?? []).filter((a) => a && a.trim());
  const riskLevel = pickRiskLevel(rec);

  await prisma.$transaction(async (tx) => {
    // 1. Upsert Person by fullName (case-insensitive).
    const existingPerson = await tx.person.findFirst({
      where: { fullName: { equals: fullName, mode: 'insensitive' } },
      select: { id: true },
    });
    const person = existingPerson
      ? existingPerson
      : await tx.person.create({
          data: { fullName, aliases, riskLevel },
          select: { id: true },
        });

    // 2. Upsert Scammer by displayName.
    const existingScammer = await tx.scammer.findFirst({
      where: { displayName: fullName },
      select: { id: true },
    });
    const scammerData = {
      displayName: fullName,
      suspectedName: fullName,
      personId: person.id,
      aliases,
      riskLevel,
      province: rec.province ?? null,
      nationality: rec.nationality ?? null,
      arrestStatus: rec.arrest_status ?? null,
    };
    const scammer = existingScammer
      ? await tx.scammer.update({
          where: { id: existingScammer.id },
          data: scammerData,
          select: { id: true },
        })
      : await tx.scammer.create({
          data: scammerData,
          select: { id: true },
        });

    // 3. Upsert ScammerIdentifiers — phones + bank accounts.
    const phones = (rec.phone ?? []).filter(Boolean);
    for (const raw of phones) {
      const normalized = normalizePhone(raw);
      if (!normalized) continue;
      await tx.scammerIdentifier.upsert({
        where: { kind_valueNormalized: { kind: 'phone', valueNormalized: normalized } },
        update: { scammerId: scammer.id, valueRaw: raw },
        create: {
          scammerId: scammer.id,
          kind: 'phone',
          valueRaw: raw,
          valueNormalized: normalized,
        },
      });
    }

    const banks = (rec.bank_account ?? []).filter(Boolean);
    for (const raw of banks) {
      const normalized = normalizeBankAccount(raw);
      if (!normalized) continue;
      await tx.scammerIdentifier.upsert({
        where: {
          kind_valueNormalized: { kind: 'bank_account', valueNormalized: normalized },
        },
        update: { scammerId: scammer.id, valueRaw: raw },
        create: {
          scammerId: scammer.id,
          kind: 'bank_account',
          valueRaw: raw,
          valueNormalized: normalized,
        },
      });
    }

    // 4. Create Report row.
    const firstPhone = phones[0] ? normalizePhone(phones[0]) : null;
    // reports.title check: BETWEEN 3 AND 200 chars.
    const rawTitle = rec.article_title?.trim() || `${fullName} — ${scamTypeLabelEn}`;
    const title = rawTitle.length > 200 ? rawTitle.slice(0, 197) + '…' : rawTitle;
    // reports.description check: >= 10 chars. Pad with the title when empty.
    const rawDescription = rec.description?.trim() ?? '';
    const description =
      rawDescription.length >= 10 ? rawDescription : `${title} (no description available)`;
    const report = await tx.report.create({
      data: {
        reporterId: null,
        title,
        description,
        scamTypeId,
        targetIdentifier: phones[0] ?? null,
        targetIdentifierKind: phones[0] ? 'phone' : null,
        targetIdentifierNormalized: firstPhone,
        status: 'verified',
        scammerId: scammer.id,
        suspectedNameAtSubmit: fullName,
        createdAt: scrapedAt ?? new Date(),
        verifiedAt,
        sourceUrl: rec.source_url,
        sourceSite: rec.source_site ?? null,
        scrapedAt,
        articleTitle: rec.article_title ?? null,
        moneyLostThb:
          rec.total_money_lost != null ? BigInt(Math.round(rec.total_money_lost)) : null,
        numVictims: rec.num_victims ?? null,
      },
      select: { id: true },
    });

    // 5. Audit log — admin approve, system-actor.
    await tx.moderationAction.create({
      data: {
        reportId: report.id,
        adminId: null,
        action: 'approve',
        remark: 'Auto-imported from news crawler',
      },
    });
  });

  return 'imported';
}

async function recomputeCaches() {
  // Lifted verbatim from prisma/seed-scammers.ts so cache columns stay
  // consistent with the rest of the seed flow.
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

async function main() {
  const argPath = process.argv[2];
  const envPath = process.env.CRAWLER_OUTPUT_PATH;
  const src = argPath ?? envPath;
  if (!src) {
    console.error(
      'usage: bun run apps/api/scripts/import-crawler.ts <abs-path-to-output.json>',
    );
    process.exit(1);
  }
  const absSrc = resolve(src);
  if (!existsSync(absSrc)) {
    console.error(`source not found: ${absSrc}`);
    process.exit(1);
  }
  const raw = readFileSync(absSrc, 'utf8');
  const parsed = JSON.parse(raw) as unknown;
  if (!Array.isArray(parsed)) {
    console.error('source must be a JSON array of records');
    process.exit(1);
  }
  const records = parsed as CrawlerRecord[];

  const scamTypeByCode = await loadScamTypes();
  if (!scamTypeByCode.has('fake_job')) {
    console.error(
      'scam_types.fake_job is missing — run `bunx prisma migrate deploy` first',
    );
    process.exit(1);
  }

  let imported = 0;
  let skipped = 0;
  let invalid = 0;
  for (const rec of records) {
    try {
      const r = await importRecord(rec, scamTypeByCode);
      if (r === 'imported') imported++;
      else if (r === 'skipped') skipped++;
      else invalid++;
    } catch (e) {
      console.error(`failed record ${rec.source_url ?? '<no url>'}:`, e);
      invalid++;
    }
  }

  await recomputeCaches();

  console.log(
    `import-crawler: imported=${imported} skipped=${skipped} invalid=${invalid} total=${records.length}`,
  );
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
