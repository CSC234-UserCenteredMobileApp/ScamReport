// One-shot seed: insert verified scam reports for the feed.
// Run from apps/api: bun run prisma/seed-reports.ts
//
// Idempotent: skips reports with titles already present.

import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { config } from 'dotenv';

config();

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });

type Seed = {
  title: string;
  description: string;
  scamTypeId: number; // 1=phone_impersonation 2=phishing_sms 3=fake_qr 4=ecommerce_fraud 5=other
  targetIdentifier?: string;
  targetIdentifierKind?: 'phone' | 'url' | 'other';
  daysAgo: number;
};

const SEEDS: Seed[] = [
  {
    title: 'Fake Kerry parcel SMS with phishing link',
    description:
      'Received SMS claiming a parcel was held; the link redirects to a fake login page mimicking Kerry Express to steal credentials.',
    scamTypeId: 2,
    targetIdentifier: 'https://kerry-th.delivery-check.co',
    targetIdentifierKind: 'url',
    daysAgo: 1,
  },
  {
    title: 'Caller pretending to be from the Revenue Department',
    description:
      'Aggressive caller claims unpaid tax penalties and demands immediate transfer to a "verification" account or arrest is imminent.',
    scamTypeId: 1,
    targetIdentifier: '+66 2 999 1234',
    targetIdentifierKind: 'phone',
    daysAgo: 2,
  },
  {
    title: 'Fake Lazada order confirmation QR',
    description:
      'QR codes posted in shopping forums claiming to confirm a refund; instead initiates a PromptPay transfer to the scammer.',
    scamTypeId: 3,
    daysAgo: 3,
  },
  {
    title: 'E-commerce store accepts payment but never ships',
    description:
      'Instagram store with cloned product photos collects payment via bank transfer and disappears; multiple victims reported the same shop name.',
    scamTypeId: 4,
    targetIdentifier: 'https://instagram.com/best-deals-th',
    targetIdentifierKind: 'url',
    daysAgo: 4,
  },
  {
    title: 'Bank impersonation call about "suspicious activity"',
    description:
      'Caller claims to be from SCB fraud team and asks for OTP to "block" a fraudulent transaction. The OTP is used to drain the account.',
    scamTypeId: 1,
    targetIdentifier: '+66 2 777 9000',
    targetIdentifierKind: 'phone',
    daysAgo: 6,
  },
  {
    title: 'Phishing SMS impersonating Krungthai Bank',
    description:
      'SMS warns of account suspension and links to ktb-secure-login.com. The page captures username, password, and PIN.',
    scamTypeId: 2,
    targetIdentifier: 'https://ktb-secure-login.com',
    targetIdentifierKind: 'url',
    daysAgo: 7,
  },
  {
    title: 'QR sticker overlay at restaurant for fake PromptPay',
    description:
      'Scammers placed QR stickers over real PromptPay codes at street-food stalls; payments go to mule accounts instead of the merchant.',
    scamTypeId: 3,
    daysAgo: 9,
  },
  {
    title: 'Facebook Marketplace iPhone listing — never delivered',
    description:
      'Seller demands full transfer up front for a "barely used" iPhone, then blocks the buyer after payment. Listing reused across multiple fake profiles.',
    scamTypeId: 4,
    daysAgo: 12,
  },
];

const HALF_HOUR = 30 * 60 * 1000;

async function main() {
  let inserted = 0;
  let skipped = 0;

  for (const s of SEEDS) {
    const existing = await prisma.report.findFirst({ where: { title: s.title } });
    if (existing) {
      skipped++;
      continue;
    }

    const verifiedAt = new Date(Date.now() - s.daysAgo * 24 * 60 * 60 * 1000);
    const createdAt = new Date(verifiedAt.getTime() - HALF_HOUR);

    await prisma.report.create({
      data: {
        title: s.title,
        description: s.description,
        scamTypeId: s.scamTypeId,
        targetIdentifier: s.targetIdentifier,
        targetIdentifierKind: s.targetIdentifierKind,
        targetIdentifierNormalized: s.targetIdentifier?.toLowerCase(),
        status: 'verified',
        createdAt,
        updatedAt: verifiedAt,
        verifiedAt,
      },
    });
    inserted++;
  }

  console.log(`seed-reports: inserted=${inserted} skipped=${skipped}`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
