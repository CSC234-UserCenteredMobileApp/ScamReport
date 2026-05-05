// One-shot seed: insert verified phone scam reports for call screening tests.
// Run from apps/api: bun run seed:call-screening
//
// Idempotent: skips numbers already present as verified phone reports.

import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { config } from 'dotenv';

config();

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });

function normalizePhone(raw: string): string {
  const stripped = raw.replace(/[\s\-\(\)]/g, '');
  if (/^0\d{8,9}$/.test(stripped)) return '+66' + stripped.slice(1);
  return stripped;
}

type Seed = {
  title: string;
  description: string;
  targetIdentifier: string;
};

const SEEDS: Seed[] = [
  {
    title: 'Test: Police impersonation hotline',
    description:
      'Caller claims to be a police officer and demands immediate transfer to a "safe account" to avoid arrest for alleged money laundering.',
    targetIdentifier: '+66 81 234 5678',
  },
  {
    title: 'Test: Fake bank fraud department',
    description:
      'Caller pretends to be from a bank fraud team and requests OTP to "block a suspicious transaction". OTP is used to drain the account.',
    targetIdentifier: '081-999-0000',
  },
  {
    title: 'Test: Revenue dept scam line',
    description:
      'Caller claims unpaid tax penalties and demands immediate payment or arrest. Uses local Bangkok number to appear official.',
    targetIdentifier: '02-555-9999',
  },
];

async function main() {
  let inserted = 0;
  let skipped = 0;

  for (const s of SEEDS) {
    const normalized = normalizePhone(s.targetIdentifier);

    const existing = await prisma.report.findFirst({
      where: {
        status: 'verified',
        targetIdentifierKind: 'phone',
        targetIdentifierNormalized: normalized,
      },
    });

    if (existing) {
      skipped++;
      continue;
    }

    const verifiedAt = new Date();
    const createdAt = new Date(verifiedAt.getTime() - 30 * 60 * 1000);

    await prisma.report.create({
      data: {
        title: s.title,
        description: s.description,
        scamTypeId: 1, // phone_impersonation
        targetIdentifier: s.targetIdentifier,
        targetIdentifierKind: 'phone',
        targetIdentifierNormalized: normalized,
        status: 'verified',
        createdAt,
        updatedAt: verifiedAt,
        verifiedAt,
      },
    });
    inserted++;
    console.log(`  + ${normalized} (${s.targetIdentifier})`);
  }

  console.log(`\nseed-call-screening: inserted=${inserted} skipped=${skipped}`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
