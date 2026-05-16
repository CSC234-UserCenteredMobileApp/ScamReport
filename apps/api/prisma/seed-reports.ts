// One-shot seed: insert verified scam reports for the feed.
// Run from apps/api: bun run prisma/seed-reports.ts
//
// Idempotent: skips reports with titles already present.

import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { config } from 'dotenv';

config();

// Lightweight mirror of the production `normalizeIdentifier` in
// reports.service.ts so seeded rows index the same way real submissions do.
function normalize(raw: string | undefined, kind: 'phone' | 'url' | 'other' | undefined): string | undefined {
  if (!raw) return undefined;
  const trimmed = raw.trim();
  if (!trimmed) return undefined;
  if (kind === 'phone') {
    const stripped = trimmed.replace(/[\s\-()]/g, '');
    if (/^0\d{8,9}$/.test(stripped)) return '+66' + stripped.slice(1);
    return stripped.replace(/[^\d+]/g, '');
  }
  if (kind === 'url') {
    try {
      const u = new URL(trimmed.startsWith('http') ? trimmed : `https://${trimmed}`);
      return u.host.toLowerCase();
    } catch {
      return trimmed.toLowerCase();
    }
  }
  return trimmed.toLowerCase();
}

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

// 25 verified mock reports. Identifiers align with seed-scammers.ts so the
// backfill links the majority. Distribution: 4 Revenue + 4 SCB + 4 Kerry +
// 4 KTB + 3 IG + 3 QR orphan + 3 safe/unknown = 25.
const SEEDS: Seed[] = [
  // ---------- Revenue Dept Impersonator (phone +66 2 999 1234, scamTypeId=1) ----------
  {
    title: 'Caller pretending to be from the Revenue Department',
    description:
      'Aggressive caller claims unpaid tax penalties of 27,800 THB and demands immediate transfer to a "verification" account or arrest is imminent. Victim received call at 10:23 on a Wednesday.',
    scamTypeId: 1,
    targetIdentifier: '+66 2 999 1234',
    targetIdentifierKind: 'phone',
    daysAgo: 2,
  },
  {
    title: 'Revenue Dept scam call demanding 45k transfer',
    description:
      'Caller identified as "Officer Anan" from the Revenue Department, threatened legal action if a 45,000 THB transfer was not made within an hour. Spoke aggressively, refused to provide a callback number.',
    scamTypeId: 1,
    targetIdentifier: '+66 2 999 1234',
    targetIdentifierKind: 'phone',
    daysAgo: 5,
  },
  {
    title: 'Fake tax officer threatens arrest over phone',
    description:
      'Received an unsolicited call from someone claiming to be Khun Somchai at the Revenue Department. Said an audit flagged my account and ordered me to drive to the bank to wire money to clear the case.',
    scamTypeId: 1,
    targetIdentifier: '+66 2 999 1234',
    targetIdentifierKind: 'phone',
    daysAgo: 11,
  },
  {
    title: 'Revenue Dept impersonator targeting small business owners',
    description:
      'My uncle who runs a small shop got the same call — claiming VAT was misfiled and demanding a 60,000 THB "settlement" to a personal account. The caller knew his shop name, likely from public registration data.',
    scamTypeId: 1,
    targetIdentifier: '+66 2 999 1234',
    targetIdentifierKind: 'phone',
    daysAgo: 18,
  },
  // ---------- Customs Duty Scam Caller (phone +66 2 999 5678, scamTypeId=1) ----------
  // Same person as Revenue Dept Impersonator. Demonstrates Person → N campaigns.
  {
    title: 'Customs Officer Somchai demands "duty release" payment',
    description:
      'Caller said his name was "Khun Somchai" from Customs. Claimed I had an undeclared import being held and demanded 18,000 THB transferred to a personal account to release it. Same voice as a Revenue Dept impersonation call I got last month.',
    scamTypeId: 1,
    targetIdentifier: '+66 2 999 5678',
    targetIdentifierKind: 'phone',
    daysAgo: 4,
  },
  {
    title: 'Customs Dept scam call — overdue import fee threat',
    description:
      'Caller introduced himself as Customs Officer Somchai, said a parcel of mine was at customs, ordered a transfer of 25,000 THB to a personal SCB account or face a fine. Refused to give a callback line.',
    scamTypeId: 1,
    targetIdentifier: '+66 2 999 5678',
    targetIdentifierKind: 'phone',
    daysAgo: 9,
  },
  // ---------- SCB Fraud-Team Caller (phone +66 2 777 9000, scamTypeId=1) ----------
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
    title: 'Fake SCB fraud desk requested OTP and drained savings',
    description:
      'Got a call at 19:40 from someone saying he was Khun Niran at SCB fraud team. Claimed a 38,000 THB transfer was attempted from my account and asked me to read out the OTP to "cancel" it. Five minutes later 38,000 was gone.',
    scamTypeId: 1,
    targetIdentifier: '+66 2 777 9000',
    targetIdentifierKind: 'phone',
    daysAgo: 8,
  },
  {
    title: 'SCB caller asked for full card details to "verify identity"',
    description:
      'Caller asked for my card number, CVV, and expiry to confirm my identity before "freezing" a suspicious transaction. Real SCB never asks for the CVV over the phone.',
    scamTypeId: 1,
    targetIdentifier: '+66 2 777 9000',
    targetIdentifierKind: 'phone',
    daysAgo: 14,
  },
  {
    title: 'SCB fraud team impersonator threatened account closure',
    description:
      'Said my SCB account would be closed in 30 minutes unless I gave them the SMS code. Called from a number that looked like a real SCB hotline.',
    scamTypeId: 1,
    targetIdentifier: '+66 2 777 9000',
    targetIdentifierKind: 'phone',
    daysAgo: 21,
  },
  // ---------- Kerry Parcel Phisher (url kerry-th.delivery-check.co, scamTypeId=2) ----------
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
    title: 'Kerry Express phishing link asks for ID card + bank login',
    description:
      'SMS said "Your parcel is held due to unpaid customs. Verify at kerry-th.delivery-check.co". The page asked for ID card number, mobile banking username, and password. Page looks 1:1 with real Kerry site.',
    scamTypeId: 2,
    targetIdentifier: 'https://kerry-th.delivery-check.co',
    targetIdentifierKind: 'url',
    daysAgo: 4,
  },
  {
    title: 'Cloned Kerry tracking page steals mobile banking creds',
    description:
      'Clicked the link out of curiosity. The "tracking" form was a credential-harvest — after submitting fake data, the page redirected to the real Kerry site to look legit. Site cert was issued same week.',
    scamTypeId: 2,
    targetIdentifier: 'https://kerry-th.delivery-check.co',
    targetIdentifierKind: 'url',
    daysAgo: 10,
  },
  {
    title: 'Parcel-held SMS scam — fake Kerry domain',
    description:
      'Three coworkers got the same SMS this week. Same wording, same kerry-th.delivery-check.co link. Looks like a bulk phishing campaign timed with Lazada sale period.',
    scamTypeId: 2,
    targetIdentifier: 'https://kerry-th.delivery-check.co',
    targetIdentifierKind: 'url',
    daysAgo: 16,
  },
  // ---------- KTB Phishing Ring (url ktb-secure-login.com, scamTypeId=2) ----------
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
    title: 'Krungthai "secure login" phishing page drained ATM PIN',
    description:
      'After entering credentials at ktb-secure-login.com, my mobile banking pin and ATM pin were used to withdraw 19,500 THB at an ATM in Pathum Thani within 40 minutes. KTB confirmed the page is not theirs.',
    scamTypeId: 2,
    targetIdentifier: 'https://ktb-secure-login.com',
    targetIdentifierKind: 'url',
    daysAgo: 9,
  },
  {
    title: 'KTB account suspension phishing — ktb-secure-login.com',
    description:
      'SMS said "your KTB account will be locked in 24h, verify at ktb-secure-login.com". Page is a perfect clone of KTB NEXT, even the OTP screen looks identical. Be careful — they ask for the 6-digit OTP twice.',
    scamTypeId: 2,
    targetIdentifier: 'https://ktb-secure-login.com',
    targetIdentifierKind: 'url',
    daysAgo: 13,
  },
  {
    title: 'Mother fell for KTB phishing — lost 12k overnight',
    description:
      'Mom clicked an SMS link to ktb-secure-login.com thinking it was the real bank. Submitted her username and password. By morning a 12,300 THB transfer had cleared to an unknown account in Chonburi.',
    scamTypeId: 2,
    targetIdentifier: 'https://ktb-secure-login.com',
    targetIdentifierKind: 'url',
    daysAgo: 22,
  },
  // ---------- IG Marketplace Ghost (social_handle @best-deals-th, scamTypeId=4) ----------
  {
    title: 'E-commerce store accepts payment but never ships',
    description:
      'Instagram store @best-deals-th with cloned product photos collects payment via bank transfer and disappears; multiple victims reported the same shop name.',
    scamTypeId: 4,
    targetIdentifier: '@best-deals-th',
    targetIdentifierKind: 'other',
    daysAgo: 4,
  },
  {
    title: 'IG shop @best-deals-th took 8,500 THB, never delivered',
    description:
      'Ordered an iPhone case + AirPods bundle from @best-deals-th on Instagram. Paid 8,500 THB to a personal SCB account. After a week of "shipping delay" excuses, the account blocked me and the IG page disappeared.',
    scamTypeId: 4,
    targetIdentifier: '@best-deals-th',
    targetIdentifierKind: 'other',
    daysAgo: 12,
  },
  {
    title: 'Instagram reseller @best-deals-th — confirmed scam',
    description:
      'Six victims posted in a Pantip thread about @best-deals-th. Same pattern: full payment required up front, photos lifted from other shops, account goes dark after 5–7 days. Bank accounts used appear to be mule accounts.',
    scamTypeId: 4,
    targetIdentifier: '@best-deals-th',
    targetIdentifierKind: 'other',
    daysAgo: 19,
  },
  // ---------- QR Swap Crew (no identifier, scamTypeId=3) ----------
  {
    title: 'Fake Lazada order confirmation QR',
    description:
      'QR codes posted in shopping forums claiming to confirm a refund; instead initiates a PromptPay transfer to the scammer.',
    scamTypeId: 3,
    daysAgo: 3,
  },
  {
    title: 'QR sticker overlay at restaurant for fake PromptPay',
    description:
      'Scammers placed QR stickers over real PromptPay codes at street-food stalls; payments go to mule accounts instead of the merchant.',
    scamTypeId: 3,
    daysAgo: 9,
  },
  {
    title: 'PromptPay refund QR scam in marketplace group',
    description:
      'Someone in a Lazada buyers group posted a QR labelled "scan to receive 450 THB refund". The QR actually triggers an outgoing transfer of 450 THB. Several users almost fell for it before someone called it out.',
    scamTypeId: 3,
    daysAgo: 15,
  },
  // ---------- Safe / unknown-scammer reports (for verdict diversity) ----------
  {
    title: 'Suspicious package from real DHL — turned out legit',
    description:
      'Got a notification from DHL.co.th about a package I forgot I ordered. Was worried it was a phishing attempt but the tracking number checked out on the official site. Adding here so others know the real domain.',
    scamTypeId: 5,
    daysAgo: 6,
  },
  {
    title: 'Marketplace iPhone listing — paid but never delivered',
    description:
      'Seller on Facebook Marketplace demanded full transfer up front for a "barely used" iPhone 14, then blocked me after payment of 18,000 THB. Listing was reused across multiple fake profiles. Different bank account each time.',
    scamTypeId: 4,
    daysAgo: 17,
  },
  {
    title: 'Fake job posting collected ID card scans',
    description:
      'LinkedIn-style job posting for a "data entry assistant" asked applicants to email a copy of their ID card and bank book as part of the application. No interview was ever scheduled and the company name does not exist in the DBD registry.',
    scamTypeId: 5,
    daysAgo: 25,
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
        targetIdentifierNormalized: normalize(s.targetIdentifier, s.targetIdentifierKind),
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
