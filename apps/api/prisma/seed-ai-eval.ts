// Seed labelled AI evaluation cases. The eval harness reads from this table
// and runs each case through /check + computeAiScore + Ask AI to produce
// accuracy metrics.
//
// Idempotent: matches existing rows by label.
// Run from apps/api: bun run prisma/seed-ai-eval.ts

import { PrismaPg } from '@prisma/adapter-pg';
import { config } from 'dotenv';
import { resolve } from 'path';
import {
  CheckInputKind,
  PrismaClient,
  VerdictLabel,
} from '../src/generated/prisma/client.js';

config({ path: resolve(import.meta.dirname, '../.env') });

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });

type Seed = {
  label: string;
  inputType: CheckInputKind;
  inputPayload: string;
  expectedVerdict: VerdictLabel;
  expectedScammerDisplayName?: string;
  expectedScamTypeCode?: string;
  expectedMissingFacts?: string[];
  notes?: string;
};

// 25 cases: 10 phone, 8 url, 7 free-text.
const SEEDS: Seed[] = [
  // ---------- phone (10) ----------
  {
    label: 'phone-revenue-known',
    inputType: 'phone',
    inputPayload: '+66 2 999 1234',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'Revenue Dept Impersonator',
    expectedScamTypeCode: 'phone_impersonation',
  },
  {
    label: 'phone-revenue-known-thai-prefix',
    inputType: 'phone',
    inputPayload: '029991234',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'Revenue Dept Impersonator',
    expectedScamTypeCode: 'phone_impersonation',
  },
  {
    label: 'phone-scb-known',
    inputType: 'phone',
    inputPayload: '+66 2 777 9000',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'SCB Fraud-Team Caller',
    expectedScamTypeCode: 'phone_impersonation',
  },
  {
    label: 'phone-scb-known-thai-prefix',
    inputType: 'phone',
    inputPayload: '027779000',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'SCB Fraud-Team Caller',
    expectedScamTypeCode: 'phone_impersonation',
  },
  {
    label: 'phone-unknown-clean',
    inputType: 'phone',
    inputPayload: '+66819998888',
    expectedVerdict: 'safe',
  },
  {
    label: 'phone-unknown-thai-prefix',
    inputType: 'phone',
    inputPayload: '0812345678',
    expectedVerdict: 'safe',
  },
  {
    label: 'phone-with-spaces-known',
    inputType: 'phone',
    inputPayload: '+66 2 999-1234',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'Revenue Dept Impersonator',
  },
  {
    label: 'phone-unknown-international',
    inputType: 'phone',
    inputPayload: '+1 555 0100',
    expectedVerdict: 'safe',
  },
  {
    label: 'phone-revenue-spaces',
    inputType: 'phone',
    inputPayload: '02 999 1234',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'Revenue Dept Impersonator',
  },
  {
    label: 'phone-scb-dashes',
    inputType: 'phone',
    inputPayload: '02-777-9000',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'SCB Fraud-Team Caller',
  },

  // ---------- url (8) ----------
  {
    label: 'url-kerry-known',
    inputType: 'url',
    inputPayload: 'https://kerry-th.delivery-check.co',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'Kerry Parcel Phisher',
    expectedScamTypeCode: 'phishing_sms',
  },
  {
    label: 'url-kerry-known-no-scheme',
    inputType: 'url',
    inputPayload: 'kerry-th.delivery-check.co',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'Kerry Parcel Phisher',
  },
  {
    label: 'url-ktb-known',
    inputType: 'url',
    inputPayload: 'https://ktb-secure-login.com/login',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'KTB Phishing Ring',
    expectedScamTypeCode: 'phishing_sms',
  },
  {
    label: 'url-ktb-known-no-scheme',
    inputType: 'url',
    inputPayload: 'ktb-secure-login.com',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'KTB Phishing Ring',
  },
  {
    label: 'url-unknown-legit-bank',
    inputType: 'url',
    inputPayload: 'https://www.scb.co.th/personal',
    expectedVerdict: 'safe',
  },
  {
    label: 'url-unknown-blog',
    inputType: 'url',
    inputPayload: 'https://example.com/blog',
    expectedVerdict: 'safe',
  },
  {
    label: 'url-kerry-uppercase',
    inputType: 'url',
    inputPayload: 'HTTPS://KERRY-TH.DELIVERY-CHECK.CO/track',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'Kerry Parcel Phisher',
  },
  {
    label: 'url-ktb-uppercase',
    inputType: 'url',
    inputPayload: 'https://KTB-SECURE-LOGIN.COM',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'KTB Phishing Ring',
  },

  // ---------- text (7) ----------
  {
    label: 'text-parcel-sms',
    inputType: 'text',
    inputPayload:
      'I got an SMS saying my Kerry parcel is held and need to click a link to release it. Is this safe?',
    expectedVerdict: 'suspicious',
    expectedScammerDisplayName: 'Kerry Parcel Phisher',
    expectedScamTypeCode: 'phishing_sms',
    expectedMissingFacts: ['targetIdentifier', 'userAction'],
  },
  {
    label: 'text-revenue-call',
    inputType: 'text',
    inputPayload:
      'Someone called pretending to be from the Revenue Department, said I had unpaid tax and demanded I transfer money',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'Revenue Dept Impersonator',
    expectedScamTypeCode: 'phone_impersonation',
    expectedMissingFacts: ['targetIdentifier', 'userAction'],
  },
  {
    label: 'text-scb-otp',
    inputType: 'text',
    inputPayload:
      'I got a call from someone saying they were SCB fraud team asking for my OTP to block a transaction',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'SCB Fraud-Team Caller',
    expectedScamTypeCode: 'phone_impersonation',
    expectedMissingFacts: ['targetIdentifier', 'userAction'],
  },
  {
    label: 'text-ig-store',
    inputType: 'text',
    inputPayload:
      'I paid an Instagram store @best-deals-th for an iPhone but they never shipped and blocked me',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'IG Marketplace Ghost',
    expectedScamTypeCode: 'ecommerce_fraud',
    expectedMissingFacts: ['userAction'],
  },
  {
    label: 'text-qr-restaurant',
    inputType: 'text',
    inputPayload:
      'I scanned a PromptPay QR at a street food stall but the money went somewhere weird',
    expectedVerdict: 'suspicious',
    expectedScammerDisplayName: 'QR Swap Crew',
    expectedScamTypeCode: 'fake_qr',
    expectedMissingFacts: ['targetIdentifier', 'userAction'],
  },
  {
    label: 'text-generic-question',
    inputType: 'text',
    inputPayload: 'What are some common scams targeting elderly people?',
    expectedVerdict: 'unknown',
    expectedMissingFacts: [],
    notes: 'Generic question — not a scam report; AI should answer informatively.',
  },
  {
    label: 'text-ktb-phishing',
    inputType: 'text',
    inputPayload:
      'I got an SMS from KTB saying my account is suspended and to click a link to verify',
    expectedVerdict: 'suspicious',
    expectedScammerDisplayName: 'KTB Phishing Ring',
    expectedScamTypeCode: 'phishing_sms',
    expectedMissingFacts: ['targetIdentifier', 'userAction'],
  },
];

async function main() {
  const scammers = await prisma.scammer.findMany({
    select: { id: true, displayName: true },
  });
  const byName = new Map(scammers.map((s) => [s.displayName, s.id]));

  let inserted = 0;
  let updated = 0;

  for (const s of SEEDS) {
    const expectedScammerId = s.expectedScammerDisplayName
      ? (byName.get(s.expectedScammerDisplayName) ?? null)
      : null;

    const data = {
      label: s.label,
      inputType: s.inputType,
      inputPayload: s.inputPayload,
      expectedVerdict: s.expectedVerdict,
      expectedScammerId,
      expectedScamTypeCode: s.expectedScamTypeCode ?? null,
      expectedMissingFacts: s.expectedMissingFacts ?? [],
      notes: s.notes ?? null,
    };

    const existing = await prisma.aiEvalCase.findFirst({
      where: { label: s.label },
      select: { id: true },
    });

    if (existing) {
      await prisma.aiEvalCase.update({ where: { id: existing.id }, data });
      updated++;
    } else {
      await prisma.aiEvalCase.create({ data });
      inserted++;
    }
  }

  console.log(`seed-ai-eval: inserted=${inserted} updated=${updated} total=${SEEDS.length}`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
