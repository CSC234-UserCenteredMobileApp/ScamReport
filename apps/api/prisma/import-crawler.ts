// One-shot import: reads ../crawler/output.json and inserts verified reports.
// Run from repo root: bun apps/api/prisma/import-crawler.ts
//
// Idempotent: skips records whose article_title is already stored.
// Province field is dropped (PRD §7 — removed before init migration).

import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { config } from 'dotenv';
import { readFileSync } from 'fs';
import { resolve } from 'path';

config({ path: resolve(import.meta.dirname, '../.env') });

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });

type CrawlerRecord = {
  firstname: string | null;
  lastname: string | null;
  aliases: string[];
  phone: string[];
  bank_account: string[];
  bank_name: string | null;
  company_name: string | null;
  total_money_lost: number | null;
  currency: string;
  num_victims: number | null;
  scam_type: string;
  description: string;
  arrest_status: 'arrested' | 'wanted' | 'unknown';
  nationality: string | null;
  source_url: string;
  scraped_at: string;
  article_title: string;
};

const SCAM_TYPE_MAP: Record<string, number> = {
  fake_investment: 6,
  online_shopping: 4,
  impersonation: 1,
  call_center: 1,
  fake_job: 5,
  romance_scam: 7,
  other: 5,
};

const ARREST_LABEL: Record<string, string> = {
  arrested: 'จับกุมแล้ว',
  wanted: 'ต้องการตัว',
  unknown: 'ไม่ทราบ',
};

const HALF_HOUR = 30 * 60 * 1000;

function truncate(s: string, max: number): string {
  return [...s].length <= max ? s : [...s].slice(0, max).join('');
}

function normalizePhone(raw: string): string {
  const digits = raw.replace(/[^\d]/g, '');
  if (digits.startsWith('0')) return '+66' + digits.slice(1);
  if (digits.startsWith('66')) return '+' + digits;
  return '+' + digits;
}

function buildDescription(r: CrawlerRecord): string {
  const name = [r.firstname, r.lastname].filter(Boolean).join(' ') || (r.aliases[0] ?? 'ไม่ระบุ');
  const aliases = r.aliases.length > 0 ? r.aliases.join(', ') : null;
  const nameDisplay = aliases ? `${name} (${aliases})` : name;
  const bankAccounts = r.bank_account.length > 0 ? r.bank_account.join(', ') : 'ไม่ระบุ';

  return [
    r.article_title,
    '',
    r.description,
    '',
    `รายละเอียดผู้ต้องสงสัย: ${nameDisplay}`,
    `สัญชาติ: ${r.nationality ?? 'ไม่ระบุ'}`,
    `บริษัท/องค์กร: ${r.company_name ?? 'ไม่ระบุ'}`,
    `เลขบัญชีธนาคาร: ${bankAccounts} (${r.bank_name ?? 'ไม่ระบุ'})`,
    `สถานะการจับกุม: ${ARREST_LABEL[r.arrest_status] ?? 'ไม่ทราบ'}`,
    `จำนวนผู้เสียหาย: ${r.num_victims != null ? r.num_victims : 'ไม่ระบุ'}`,
    `ความเสียหายรวม: ${r.total_money_lost != null ? r.total_money_lost.toLocaleString('th-TH') : 'ไม่ระบุ'} บาท`,
    `แหล่งข้อมูล: ${r.source_url}`,
  ].join('\n');
}

async function main() {
  const crawlerPath = resolve(import.meta.dirname, '../../../../crawler/output.json');
  const records: CrawlerRecord[] = JSON.parse(readFileSync(crawlerPath, 'utf-8'));

  const existing = await prisma.report.findMany({ select: { title: true } });
  const existingTitles = new Set(existing.map((r) => r.title));

  let inserted = 0;
  let skipped = 0;

  for (const rec of records) {
    const title = truncate(rec.article_title, 200);

    if (existingTitles.has(title)) {
      skipped++;
      continue;
    }

    const scamTypeId = SCAM_TYPE_MAP[rec.scam_type] ?? 5;
    const description = buildDescription(rec);
    const verifiedAt = new Date(rec.scraped_at);
    const createdAt = new Date(verifiedAt.getTime() - HALF_HOUR);

    const firstPhone = rec.phone[0] ?? null;
    const targetIdentifier = firstPhone ? normalizePhone(firstPhone) : null;

    await prisma.report.create({
      data: {
        title,
        description,
        scamTypeId,
        targetIdentifier,
        targetIdentifierKind: targetIdentifier ? 'phone' : null,
        targetIdentifierNormalized: targetIdentifier?.toLowerCase() ?? null,
        status: 'verified',
        reporterId: null,
        createdAt,
        updatedAt: verifiedAt,
        verifiedAt,
      },
    });

    existingTitles.add(title);
    inserted++;
  }

  console.log(`import-crawler: inserted=${inserted} skipped=${skipped} total=${records.length}`);
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
