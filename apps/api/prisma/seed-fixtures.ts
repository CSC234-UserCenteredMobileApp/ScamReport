// Canonical seed data shared by every seed script.
//
// One file is the source of truth so identifier alignment between
// `seed-scammers.ts` and `seed-flow.ts` can't drift. Adding a new scammer
// here AND a matching report scenario keeps the application-level auto-link
// (reports.service.ts:196-216 — opportunistic lookup by identifier) firing.
//
// Layout:
//   SCAMMERS              — 12 offender profiles (4 of them share Persons,
//                           so we end up with ~10 distinct Persons).
//   REPORT_SCENARIOS      — 150 report scenarios. ~140 attribute to a scammer
//                           by identifier; ~10 are deliberately orphan to
//                           exercise the moderator "link by hand" flow.
//   AI_CONVERSATIONS      — 10 Ask-AI conversation scripts (alternating
//                           user/assistant messages). 2 intent-detected; 2
//                           linked to a report id (filled in at seed time).
//   ANNOUNCEMENTS         — 6 announcement drafts to publish via the service.
//
// Tuning knobs (also documented in /home/symphony/.claude/plans/…):
//   ~80 approve / 25 flag / 15 reject / 30 pending. 10% of approves carry a
//   follow-up flag → unflag sequence to make the audit trail non-trivial.

import type { ScammerIdentifierKind, ScammerRiskLevel } from '../src/generated/prisma/client.js';

// =============================================================================
// Scammers (12 — extends the original 7 with 5 new campaigns)
// =============================================================================

export interface SeedIdentifier {
  kind: ScammerIdentifierKind;
  valueRaw: string;
  valueNormalized: string;
}

export interface SeedScammer {
  key: string;                   // stable handle for cross-file referencing
  displayName: string;
  suspectedName: string | null;
  personFullName: string | null; // when multiple scammers share a person, they're 1 human / N campaigns
  aliases: string[];
  riskLevel: ScammerRiskLevel;
  notes: string;
  identifiers: SeedIdentifier[];
}

export const SCAMMERS: SeedScammer[] = [
  // ---------- 1. Revenue Dept Impersonator (phone)
  {
    key: 'revenue_dept',
    displayName: 'Revenue Dept Impersonator',
    suspectedName: 'Khun Somchai Wongchai',
    personFullName: 'Khun Somchai Wongchai',
    aliases: ['Officer Anan'],
    riskLevel: 'high',
    notes:
      'Cold-calls victims claiming unpaid tax penalties; demands transfers to a "verification" account.',
    identifiers: [{ kind: 'phone', valueRaw: '+66 2 999 1234', valueNormalized: '+6629991234' }],
  },
  // ---------- 2. Customs Duty Scam Caller (same person as #1, different campaign)
  {
    key: 'customs_duty',
    displayName: 'Customs Duty Scam Caller',
    suspectedName: 'Khun Somchai Wongchai',
    personFullName: 'Khun Somchai Wongchai',
    aliases: ['Customs Officer Somchai'],
    riskLevel: 'high',
    notes:
      'Same caller as the Revenue Dept campaign; pivots to claiming an undeclared import incurred customs duty.',
    identifiers: [{ kind: 'phone', valueRaw: '+66 2 999 5678', valueNormalized: '+6629995678' }],
  },
  // ---------- 3. SCB Fraud-Team Caller
  {
    key: 'scb_fraud',
    displayName: 'SCB Fraud-Team Caller',
    suspectedName: 'Khun Niran Thanachai',
    personFullName: 'Khun Niran Thanachai',
    aliases: [],
    riskLevel: 'high',
    notes:
      'Impersonates SCB fraud desk; convinces victims to share OTPs to "block" suspicious transactions, then drains the account.',
    identifiers: [{ kind: 'phone', valueRaw: '+66 2 777 9000', valueNormalized: '+6627779000' }],
  },
  // ---------- 4. Kerry Parcel Phisher (URL)
  {
    key: 'kerry_phish',
    displayName: 'Kerry Parcel Phisher',
    suspectedName: null,
    personFullName: null,
    aliases: ['Kerry Express Notify'],
    riskLevel: 'high',
    notes:
      'Sends SMS claiming undelivered parcels; link redirects to a cloned Kerry login page that captures credentials.',
    identifiers: [
      { kind: 'url', valueRaw: 'https://kerry-th.delivery-check.co', valueNormalized: 'kerry-th.delivery-check.co' },
    ],
  },
  // ---------- 5. KTB Phishing Ring (URL)
  {
    key: 'ktb_phish',
    displayName: 'KTB Phishing Ring',
    suspectedName: null,
    personFullName: null,
    aliases: ['Krungthai Secure Login'],
    riskLevel: 'high',
    notes:
      'Phishing SMS warning of account suspension; landing page captures username, password, and PIN.',
    identifiers: [
      { kind: 'url', valueRaw: 'https://ktb-secure-login.com', valueNormalized: 'ktb-secure-login.com' },
    ],
  },
  // ---------- 6. IG Marketplace Ghost (social handle)
  {
    key: 'ig_ghost',
    displayName: 'IG Marketplace Ghost',
    suspectedName: null,
    personFullName: null,
    aliases: ['Best Deals TH', 'IG iPhone Reseller'],
    riskLevel: 'medium',
    notes:
      'Operates Instagram storefronts with cloned product photos; collects bank transfers and blocks buyers after payment.',
    identifiers: [
      { kind: 'social_handle', valueRaw: '@best-deals-th', valueNormalized: '@best-deals-th' },
    ],
  },
  // ---------- 7. QR Swap Crew (no identifier — orphan-ish)
  {
    key: 'qr_swap',
    displayName: 'QR Swap Crew',
    suspectedName: null,
    personFullName: null,
    aliases: ['Lazada Refund QR', 'PromptPay Sticker Crew'],
    riskLevel: 'medium',
    notes:
      'Distributes fake PromptPay QR codes (refunds, restaurant stickers); transfers route to mule accounts.',
    identifiers: [],
  },

  // ----- 5 new scammer profiles ------------------------------------------
  // ---------- 8. LINE-ID Romance Scam
  {
    key: 'line_romance',
    displayName: 'LINE-ID Romance Scammer',
    suspectedName: 'Khun Daeng Surasak',
    personFullName: 'Khun Daeng Surasak',
    aliases: ['Lonely Investor Daeng'],
    riskLevel: 'high',
    notes:
      'Cultivates a months-long online relationship via LINE, then asks for "emergency" transfers (medical bills, customs fees).',
    identifiers: [{ kind: 'line_id', valueRaw: '@daeng-love-th', valueNormalized: '@daeng-love-th' }],
  },
  // ---------- 9. Utility Bill SMS Phisher
  {
    key: 'utility_bill_sms',
    displayName: 'Utility-Bill SMS Phisher',
    suspectedName: null,
    personFullName: null,
    aliases: ['MEA Overdue Notice', 'PEA Disconnection Alert'],
    riskLevel: 'high',
    notes:
      'SMS claiming overdue electricity bill; URL leads to a clone of the MEA / PEA portal capturing bank logins.',
    identifiers: [
      { kind: 'url', valueRaw: 'https://mea-bill-pay.online', valueNormalized: 'mea-bill-pay.online' },
    ],
  },
  // ---------- 10. OTP Phone Phisher (different person from SCB caller)
  {
    key: 'otp_caller',
    displayName: 'OTP Phone Phisher',
    suspectedName: 'Khun Pong Anuwat',
    personFullName: 'Khun Pong Anuwat',
    aliases: ['Generic Bank Verifier'],
    riskLevel: 'high',
    notes:
      'Cold-calls claiming to be from "the bank" (vague — KBank, Bangkok Bank, SCB); demands OTPs to "stop a fraudulent transfer". Drains accounts within minutes.',
    identifiers: [{ kind: 'phone', valueRaw: '+66 2 555 1212', valueNormalized: '+6625551212' }],
  },
  // ---------- 11. Lazada Coupon URL Scam
  {
    key: 'lazada_coupon',
    displayName: 'Lazada Coupon Phisher',
    suspectedName: null,
    personFullName: null,
    aliases: ['Lazada Bonus 500THB'],
    riskLevel: 'medium',
    notes:
      'Shareable URL promising a 500 THB Lazada coupon; lands on a credential-harvester branded like Lazada\'s real login.',
    identifiers: [
      { kind: 'url', valueRaw: 'https://lazada-coupon-th.com', valueNormalized: 'lazada-coupon-th.com' },
    ],
  },
  // ---------- 12. Gov-Grant Phone Scam
  {
    key: 'gov_grant',
    displayName: 'Government Grant Scam Caller',
    suspectedName: 'Khun Nattapong Sirivat',
    personFullName: 'Khun Nattapong Sirivat',
    aliases: ['Khon La Kreung Officer'],
    riskLevel: 'high',
    notes:
      'Cold-calls victims claiming entitlement to a government grant ("Khon-La-Kreung remainder", "stimulus"); demands a bank fee transfer to release the funds.',
    identifiers: [{ kind: 'phone', valueRaw: '+66 2 222 3434', valueNormalized: '+6622223434' }],
  },
];

// Helper for cross-file lookups
export function scammerByKey(key: string): SeedScammer | undefined {
  return SCAMMERS.find((s) => s.key === key);
}

// =============================================================================
// Report scenarios (150 total — 140 attributed + 10 orphan)
// =============================================================================

export type ScamTypeCode =
  | 'phone_impersonation'
  | 'phishing_sms'
  | 'fake_qr'
  | 'ecommerce_fraud'
  | 'other'
  | 'investment_fraud'
  | 'romance_scam'
  | 'fake_job';

export type Action = 'approve' | 'flag' | 'reject' | 'pending';

export interface ReportScenario {
  title: string;                 // unique per scenario (createReport idempotency keys on it)
  description: string;
  scamTypeCode: ScamTypeCode;
  // Identifier — when set, matches one of the SCAMMERS[].identifiers entries.
  // null = orphan (no auto-link).
  scammerKey: string | null;
  identifierKind: 'phone' | 'url' | 'other' | null;
  identifier: string | null;
  // Predetermined moderation outcome.
  action: Action;
  // Approves that also receive a flag → unflag follow-up before approval.
  doubleAction?: boolean;
  // Days back from now for the original submit time (1–90).
  daysAgo: number;
  // Suspected name claimed by the reporter at submit time. Drives the name-
  // based auto-link in admin-reports.service.ts:318.
  suspectedNameAtSubmit?: string;
}

// Helper to spread N scenarios across the (approve, flag, reject, pending)
// outcome buckets per the plan distribution.
function distribute(n: number): Action[] {
  // 80/25/15/30 of 150 → in proportion: 0.533/0.167/0.10/0.20
  const ratios: Array<[Action, number]> = [
    ['approve', 0.533],
    ['flag', 0.167],
    ['reject', 0.10],
    ['pending', 0.20],
  ];
  const out: Action[] = [];
  for (const [act, r] of ratios) {
    const count = Math.round(n * r);
    for (let i = 0; i < count; i++) out.push(act);
  }
  // Pad with 'approve' if rounding dropped a few.
  while (out.length < n) out.push('approve');
  return out.slice(0, n);
}

// Template generator — produces N variants for a single scammer, drawing
// from a base bank of title + description fragments. Each variant gets a
// unique title (suffix counter) so createReport idempotency keys don't
// collide.
interface VariantBank {
  scamTypeCode: ScamTypeCode;
  identifierKind: 'phone' | 'url' | 'other';
  suspectedNameAtSubmit?: string;
  templates: Array<{ title: string; description: string }>;
}

function variantsFor(
  scammer: SeedScammer,
  bank: VariantBank,
  count: number,
): ReportScenario[] {
  const id = scammer.identifiers[0];
  if (!id) throw new Error(`scammer ${scammer.key} has no identifier`);

  const actions = distribute(count);
  const doubleActionEvery = 10; // ~10% of approves get a flag→unflag prelude
  let approveCounter = 0;

  return bank.templates.slice(0, count).map((t, i) => {
    const action = actions[i] ?? 'pending';
    let doubleAction = false;
    if (action === 'approve') {
      approveCounter++;
      if (approveCounter % doubleActionEvery === 0) doubleAction = true;
    }
    return {
      title: `${t.title} [${scammer.key}#${i + 1}]`,
      description: t.description,
      scamTypeCode: bank.scamTypeCode,
      scammerKey: scammer.key,
      identifierKind: bank.identifierKind,
      identifier: id.valueRaw,
      action,
      ...(doubleAction ? { doubleAction: true } : {}),
      daysAgo: 1 + Math.floor(((i + 1) * 7919) % 88), // deterministic 1-88
      ...(bank.suspectedNameAtSubmit
        ? { suspectedNameAtSubmit: bank.suspectedNameAtSubmit }
        : {}),
    };
  });
}

// --- Variant banks (12-15 templates each) --------------------------------

const REVENUE_BANK: VariantBank = {
  scamTypeCode: 'phone_impersonation',
  identifierKind: 'phone',
  suspectedNameAtSubmit: 'Khun Somchai Wongchai',
  templates: [
    { title: 'Caller pretending to be from the Revenue Department',
      description: 'Aggressive caller claims unpaid tax penalties of 27,800 THB and demands immediate transfer to a "verification" account or arrest is imminent. Victim received call at 10:23 on a Wednesday.' },
    { title: 'Revenue Dept scam call demanding 45k transfer',
      description: 'Caller identified as "Officer Anan" from the Revenue Department, threatened legal action if a 45,000 THB transfer was not made within an hour. Spoke aggressively, refused to provide a callback number.' },
    { title: 'Fake tax officer threatens arrest over phone',
      description: 'Received an unsolicited call from someone claiming to be Khun Somchai at the Revenue Department. Said an audit flagged my account and ordered me to drive to the bank to wire money to clear the case.' },
    { title: 'Revenue Dept impersonator targeting small business owners',
      description: 'My uncle who runs a small shop got the same call — claiming VAT was misfiled and demanding a 60,000 THB "settlement" to a personal account. The caller knew his shop name, likely from public registration data.' },
    { title: 'Revenue scam call — claims my PIT filing was incomplete',
      description: 'Caller said my personal income tax return was missing supporting documents and a fine of 18,500 THB was due today. Demanded a transfer to a personal SCB account marked as "Revenue Office".' },
    { title: 'Aggressive tax-arrest threat — 33k transfer demand',
      description: 'Same script as other Revenue Dept reports. The voice and the demand pattern were identical to a call my colleague received last week — likely the same operator.' },
    { title: 'Revenue Dept caller pressured 78-year-old grandmother',
      description: 'My grandmother answered the call thinking it was the real Revenue Office. The caller said she owed 12,400 THB or police would visit. She panicked and almost transferred before I intervened.' },
    { title: 'Revenue Dept impersonation followed by fake legal letter',
      description: 'After the call, an email arrived with a forged "Revenue Department" letterhead demanding a 41,000 THB settlement. Same phone number listed for callbacks.' },
    { title: 'Caller faked Revenue Dept caller-ID display',
      description: 'The caller-ID showed a real Revenue Department hotline format. After hanging up and dialling the real hotline, the official confirmed no such case exists in my file.' },
    { title: 'Revenue Dept scam — demanded BTC transfer when bank failed',
      description: 'When my SCB transfer failed (daily limit reached), the caller switched to demanding the equivalent in BTC to a wallet address. New behaviour worth noting in this campaign.' },
  ],
};

const CUSTOMS_BANK: VariantBank = {
  scamTypeCode: 'phone_impersonation',
  identifierKind: 'phone',
  suspectedNameAtSubmit: 'Khun Somchai Wongchai',
  templates: [
    { title: 'Customs Officer Somchai demands "duty release" payment',
      description: 'Caller said his name was "Khun Somchai" from Customs. Claimed I had an undeclared import being held and demanded 18,000 THB transferred to a personal account to release it.' },
    { title: 'Customs Dept scam call — overdue import fee threat',
      description: 'Caller introduced himself as Customs Officer Somchai, said a parcel of mine was at customs, ordered a transfer of 25,000 THB to a personal SCB account or face a fine.' },
    { title: 'Fake Customs call followed up via LINE with bogus invoice',
      description: 'After the call, the caller sent a forged Customs Department invoice via LINE for 31,200 THB. Same phone number, same voice as the Revenue Dept impersonator.' },
    { title: 'Customs duty scam targeted Lazada shopper',
      description: 'Caller knew my recent Lazada order from China, said it was held at Customs and a duty of 8,400 THB was required. The order was domestic — no Customs involvement possible.' },
    { title: 'Customs scammer escalated to threats of asset seizure',
      description: 'When I refused to transfer, the caller threatened to "seize my house" the next morning. Same MO as Revenue Dept campaign.' },
    { title: 'Customs Officer Somchai — repeat caller, second week',
      description: 'Same caller from last week pivoted from "tax audit" to "customs duty". Voice + cadence are identical. Number this time was +66 2 999 5678.' },
    { title: 'Customs fee scam — fake DHL package angle',
      description: 'Caller claimed a DHL package with my name was held at Customs and a 14,800 THB fee was needed. I had no incoming international shipment.' },
    { title: 'Customs scam coordinated with fake "delivery" SMS',
      description: 'Got an SMS first claiming a parcel was held, then a follow-up call asking for a customs duty payment. Coordinated multi-channel campaign.' },
    { title: 'Customs duty scammer demanded payment in PromptPay slip',
      description: 'New twist — caller asked for a screenshot of the PromptPay transfer rather than the transfer itself, presumably to forge a receipt for other victims.' },
    { title: 'Customs caller pivoted to "release escrow" angle',
      description: 'When I doubted the customs story, the caller claimed it was actually an "escrow release" and the 18,000 THB would be refunded the next day. Same number.' },
  ],
};

const SCB_BANK: VariantBank = {
  scamTypeCode: 'phone_impersonation',
  identifierKind: 'phone',
  suspectedNameAtSubmit: 'Khun Niran Thanachai',
  templates: [
    { title: 'Bank impersonation call about "suspicious activity"',
      description: 'Caller claims to be from SCB fraud team and asks for OTP to "block" a fraudulent transaction. The OTP is used to drain the account.' },
    { title: 'Fake SCB fraud desk requested OTP and drained savings',
      description: 'Got a call at 19:40 from someone saying he was Khun Niran at SCB fraud team. Five minutes after I read out the OTP, 38,000 THB was gone.' },
    { title: 'SCB caller asked for full card details to "verify identity"',
      description: 'Caller asked for my card number, CVV, and expiry. Real SCB never asks for the CVV over the phone.' },
    { title: 'SCB fraud team impersonator threatened account closure',
      description: 'Said my SCB account would be closed in 30 minutes unless I gave them the SMS code. Called from a number that looked like a real SCB hotline.' },
    { title: 'SCB scammer used voice-clone for "manager escalation"',
      description: 'After my initial pushback, the caller put on a different voice claiming to be a "supervisor". Same number, same script. Voice clone or staged team.' },
    { title: 'SCB fraud-desk impersonator timed call with my real transfer',
      description: 'The call came within an hour of a legitimate transfer I did from SCB Easy. They knew the amount almost exactly. Possibly a data leak from the bank or a malware on my phone.' },
    { title: 'SCB caller used Thai-English code switching for credibility',
      description: 'Caller dropped into English mid-sentence to recite "policy" — same tactic in two earlier SCB scam reports here.' },
    { title: 'SCB fraud-team impersonator left a callback voicemail',
      description: 'After I hung up, a voicemail in the same voice asked me to call back urgently. Number was +66 2 777 9000.' },
    { title: 'SCB scammer escalated to threats of police involvement',
      description: 'Said if I didn\'t give them the OTP in 5 minutes, "police would come open my account". Real SCB does not work this way.' },
    { title: 'SCB caller spoofed real branch caller-ID',
      description: 'Caller-ID showed a real SCB branch number. After hanging up and calling the branch back directly, they confirmed no outgoing call from them.' },
  ],
};

const KERRY_BANK: VariantBank = {
  scamTypeCode: 'phishing_sms',
  identifierKind: 'url',
  templates: [
    { title: 'Fake Kerry parcel SMS with phishing link',
      description: 'Received SMS claiming a parcel was held; the link redirects to a fake login page mimicking Kerry Express to steal credentials.' },
    { title: 'Kerry Express phishing link asks for ID card + bank login',
      description: 'SMS said "Your parcel is held due to unpaid customs. Verify at kerry-th.delivery-check.co". The page asked for ID card number, mobile banking username, and password.' },
    { title: 'Cloned Kerry tracking page steals mobile banking creds',
      description: 'Clicked the link out of curiosity. The "tracking" form was a credential-harvest — after submitting fake data, the page redirected to the real Kerry site to look legit.' },
    { title: 'Parcel-held SMS scam — fake Kerry domain',
      description: 'Three coworkers got the same SMS this week. Same wording, same kerry-th.delivery-check.co link. Looks like a bulk phishing campaign timed with Lazada sale period.' },
    { title: 'Kerry phishing site asks for OTP after credential entry',
      description: 'The phishing flow chains credential capture with an OTP request the next screen. Two coworkers reported the same.' },
    { title: 'Kerry phishing SMS arrived at 03:00 a.m.',
      description: 'Out-of-hours delivery typical of bulk phishing batches. URL is the same kerry-th.delivery-check.co.' },
    { title: 'Kerry phishing variant — Thai-language landing page',
      description: 'New variant of the same domain serves a Thai-language landing page. Asks for ID card number + ATM PIN. Same backend.' },
    { title: 'Mum lost 7,800 THB to Kerry phishing site',
      description: 'Mum entered her KBank credentials. By morning a 7,800 THB transfer had cleared to a mule account.' },
    { title: 'Kerry phishing redirect chain — three hops',
      description: 'URL hops through two short-link domains before landing at kerry-th.delivery-check.co. Possibly to dodge anti-phishing scanners.' },
    { title: 'Kerry phishing SMS quotes real shipping tracking format',
      description: 'SMS uses a tracking-number format identical to real Kerry receipts. Adds credibility for casual readers.' },
  ],
};

const KTB_BANK: VariantBank = {
  scamTypeCode: 'phishing_sms',
  identifierKind: 'url',
  templates: [
    { title: 'Phishing SMS impersonating Krungthai Bank',
      description: 'SMS warns of account suspension and links to ktb-secure-login.com. The page captures username, password, and PIN.' },
    { title: 'Krungthai "secure login" phishing drained ATM PIN',
      description: 'After entering credentials at ktb-secure-login.com, 19,500 THB was withdrawn at an ATM in Pathum Thani within 40 minutes.' },
    { title: 'KTB account suspension phishing — ktb-secure-login.com',
      description: 'SMS said my KTB account will be locked in 24h; page is a perfect clone of KTB NEXT, including the OTP screen.' },
    { title: 'Mother fell for KTB phishing — lost 12k overnight',
      description: 'Mom clicked an SMS link to ktb-secure-login.com. Submitted her username and password. By morning a 12,300 THB transfer had cleared.' },
    { title: 'KTB phishing variant — uses HTTPS and valid cert',
      description: 'Domain has a valid Let\'s Encrypt cert issued last week. Makes the lock-icon trust signal misleading for non-technical users.' },
    { title: 'KTB phishing SMS used real ATM event as bait',
      description: 'I had used an ATM that morning; the SMS arrived 2h later claiming "ATM access anomaly" — too coincidental, suggesting data leak.' },
    { title: 'KTB phishing — staged OTP loop',
      description: 'Page asks for the OTP twice within 30 seconds, presumably to capture both a transaction OTP and a login OTP.' },
    { title: 'KTB phishing SMS arrived during real KTB outage',
      description: 'Sent during a real KTB NEXT outage day. Customers panicked and many followed the link.' },
    { title: 'KTB phishing site asks for security questions',
      description: 'Beyond the password, the phishing page asks for "mother\'s maiden name" — used to bypass real KTB security verification.' },
    { title: 'KTB phishing campaign now using SMS sender-ID "KTB"',
      description: 'New variant masks the sender-ID as "KTB" rather than a raw phone number. SMS routing exploit.' },
  ],
};

const IG_BANK: VariantBank = {
  scamTypeCode: 'ecommerce_fraud',
  identifierKind: 'other',
  templates: [
    { title: 'E-commerce store accepts payment but never ships',
      description: 'Instagram store @best-deals-th with cloned product photos collects payment via bank transfer and disappears; multiple victims reported the same shop name.' },
    { title: 'IG shop @best-deals-th took 8,500 THB, never delivered',
      description: 'Ordered an iPhone case + AirPods bundle from @best-deals-th. After a week of "shipping delay" excuses, the account blocked me and the IG page disappeared.' },
    { title: 'Instagram reseller @best-deals-th — confirmed scam',
      description: 'Six victims posted in a Pantip thread about @best-deals-th. Same pattern: full payment up front, photos lifted from other shops, account dark after 5–7 days.' },
    { title: '@best-deals-th changed handle after scam exposed',
      description: 'After the Pantip exposure, the same content reappeared under a different handle. Same bank account on the order form.' },
    { title: 'IG @best-deals-th — confirmed mule account banking pattern',
      description: 'Bank accounts used by @best-deals-th appear in multiple e-commerce scam reports across forums. Account holders likely paid mules.' },
    { title: '@best-deals-th now asks for half-deposit before "stock check"',
      description: 'New tactic — half-deposit collected before any shipping commitment. After 3 days the account ghosts.' },
    { title: 'IG @best-deals-th — fake delivery slip sent to stall complaints',
      description: 'When I demanded a refund, they sent a forged Kerry tracking screenshot. Tracking number did not exist on the real Kerry site.' },
    { title: '@best-deals-th hit student buyer for 11,200 THB iPad case',
      description: 'University student paid 11,200 THB for an "iPad Pro case" that was a stock photo. Same pattern as 6 prior reports here.' },
    { title: '@best-deals-th uses bot-generated reviews on profile',
      description: 'Profile shows ~200 reviews, all from accounts created the same week. Classic review-farming pattern.' },
    { title: '@best-deals-th — DMs threats when refund requested',
      description: 'After I asked for a refund, the account threatened to "send legal" — a common bluff seen in two prior reports.' },
  ],
};

const QR_BANK: VariantBank = {
  // QR Swap Crew has no identifier — these will be orphan-ish but we still
  // tag them with the scammer key so the name-based auto-link (admin) can
  // pick them up on approve.
  scamTypeCode: 'fake_qr',
  identifierKind: 'other',
  templates: [
    { title: 'Fake Lazada order confirmation QR',
      description: 'QR codes posted in shopping forums claiming to confirm a refund; instead initiates a PromptPay transfer to the scammer.' },
    { title: 'QR sticker overlay at restaurant for fake PromptPay',
      description: 'Scammers placed QR stickers over real PromptPay codes at street-food stalls; payments go to mule accounts instead of the merchant.' },
    { title: 'PromptPay refund QR scam in marketplace group',
      description: 'Someone in a Lazada buyers group posted a QR labelled "scan to receive 450 THB refund". The QR actually triggers an outgoing transfer of 450 THB.' },
    { title: 'QR swap at coffee shop drained 320 THB before customer noticed',
      description: 'Sticker over the real cafe QR. Two customers paid before the owner realised. Stickers came off cleanly — premeditated.' },
    { title: 'PromptPay sticker swap reported at three Bangkok food courts',
      description: 'Same modus operandi across BTS Asok, BTS Phrom Phong, and BTS Thong Lor food courts this week. Same sticker template.' },
    { title: 'Lazada-branded "free coupon" QR triggered hidden payment',
      description: 'Glossy printout in shopping group claiming a free Lazada coupon — QR initiates a 199 THB transfer instead.' },
  ],
};

const LINE_ROMANCE_BANK: VariantBank = {
  scamTypeCode: 'romance_scam',
  identifierKind: 'other',
  suspectedNameAtSubmit: 'Khun Daeng Surasak',
  templates: [
    { title: 'LINE romance — "investor" Daeng asked for emergency transfer',
      description: 'Met via LINE four months ago. After building rapport, "Khun Daeng" claimed a medical emergency overseas and asked for a 45,000 THB transfer. Same script as my friend\'s case.' },
    { title: 'LINE romance scammer — fake passport photo for credibility',
      description: 'Khun Daeng sent a "scan of his passport" to prove identity before asking for transfer. Photo was a stock image with the name photoshopped in.' },
    { title: 'LINE @daeng-love-th — chronic asker pattern',
      description: 'Pattern is unmistakable: weeks of warmth followed by a sudden financial need. Three women in our LINE OpenChat reported the exact same script.' },
    { title: 'LINE romance scam — "customs fee" angle',
      description: 'After months of chat, Daeng claimed a gift parcel was held at customs and asked for a 12,400 THB customs fee to release it. Classic 419 variant.' },
    { title: 'LINE romance — escalated to crypto-investment pitch',
      description: 'After the "loan" was declined, the scammer pivoted to a "guaranteed return" crypto investment with a fake trading dashboard. Same LINE id.' },
    { title: 'LINE @daeng-love-th — fake video-call with looped clip',
      description: 'When pressed for proof, the scammer agreed to a video call. Clip looped after ~10 seconds — recorded, not live.' },
    { title: 'LINE romance scam — exploited bereaved user',
      description: 'My aunt lost her husband last year. Khun Daeng targeted her by referencing widowhood early in chat. Asked for 28,500 THB within three weeks of contact.' },
    { title: 'LINE @daeng-love-th — re-engaged victim 6 months later',
      description: 'Same account messaged me 6 months after I cut contact, pretending to be "back from overseas". Identical opener as last time.' },
    { title: 'LINE romance scam group operates from multi-language script',
      description: 'Mistakes in Thai grammar suggest non-native operators. Several phrases match scripts seen in Cantonese-led scam compounds.' },
    { title: 'LINE @daeng-love-th — claimed cardiac surgery to extract transfer',
      description: 'After "diagnosis" claim with a forged hospital invoice, asked for 60,000 THB upfront. Hospital named on the invoice does not exist.' },
  ],
};

const UTILITY_BANK: VariantBank = {
  scamTypeCode: 'phishing_sms',
  identifierKind: 'url',
  templates: [
    { title: 'MEA overdue-bill SMS phishing — mea-bill-pay.online',
      description: 'SMS claimed I had an overdue MEA bill of 1,840 THB and threatened disconnection. The URL captures bank login.' },
    { title: 'PEA disconnection SMS scam — mea-bill-pay.online',
      description: 'Despite the URL matching the MEA campaign, the SMS branded itself as PEA. Same backend.' },
    { title: 'Utility phishing site captures KBank credentials',
      description: 'Page collected KBank username/password and an OTP. 6,200 THB transferred out within 20 minutes.' },
    { title: 'Utility bill phishing — escalated to "disconnect today" pressure',
      description: 'SMS said power would be cut at 18:00 today unless payment was made. Bait for after-hours panic clicks.' },
    { title: 'Utility phishing — fake "energy subsidy" follow-up',
      description: 'After the failed bill scam, the same number sent a "subsidy reimbursement" link. Same domain, different framing.' },
    { title: 'Utility phishing site asks for ID card photo upload',
      description: 'After login, the site asks the victim to upload a photo of their ID card "for verification". Identity-theft pipeline.' },
    { title: 'MEA phishing batch sent during real-world brownout',
      description: 'SMS arrived right after a real brownout in Bangkok. Timing made victims more likely to believe their account was affected.' },
    { title: 'Utility SMS — Thai-only landing page variant',
      description: 'New variant serves a Thai-only landing page. Same URL.' },
    { title: 'Utility phishing — credentials sold within 24h',
      description: 'Stolen credentials surfaced for sale on a Telegram channel within 24h of submission. Highlights speed of monetisation.' },
    { title: 'Mum hit by utility phishing during home renovation',
      description: 'She thought the message was about her new meter installation. Lost 4,800 THB before the bank reversed part of the transfer.' },
  ],
};

const OTP_BANK: VariantBank = {
  scamTypeCode: 'phone_impersonation',
  identifierKind: 'phone',
  suspectedNameAtSubmit: 'Khun Pong Anuwat',
  templates: [
    { title: 'Generic "bank verifier" scam call — Khun Pong',
      description: 'Caller would not name a specific bank — asked which I used, then claimed to be "from that bank". Demanded OTP.' },
    { title: 'OTP caller targeted shared phone in family of four',
      description: 'Caller dialled my parents\' shared home phone, asked for "the account holder". My father almost gave up the OTP.' },
    { title: 'OTP phisher used bank-style hold music',
      description: 'Mid-call the scammer "put me on hold" with what sounded like a real bank IVR. Effective social cue.' },
    { title: 'OTP caller — sequential dialling pattern across district',
      description: 'Three neighbours on the same street reported the call within an hour. Likely a war-dial.' },
    { title: 'OTP phisher pivoted to PromptPay when OTP rejected',
      description: 'When I refused the OTP, the caller asked for a "PromptPay verification transfer" of 1 THB to "confirm my identity". Account number was a mule.' },
    { title: 'OTP scam call lasted 47 minutes before victim hung up',
      description: 'My aunt stayed on the call for almost an hour while the scammer steadily walked her through reading OTPs. She lost 24,800 THB.' },
    { title: 'OTP caller used real-time IVR mimicry',
      description: 'Background of the call had voices and printer sounds — staged office to simulate a real bank fraud team.' },
    { title: 'OTP scam — caller knew last 4 digits of card',
      description: 'Said "we see your card ending 4527" — those were the real last 4. Possibly from a breach.' },
  ],
};

const LAZADA_BANK: VariantBank = {
  scamTypeCode: 'phishing_sms',
  identifierKind: 'url',
  templates: [
    { title: 'Lazada coupon phishing — lazada-coupon-th.com',
      description: '"You\'ve won a 500 THB Lazada coupon!" — URL lands on a clone of the real Lazada login page.' },
    { title: 'Lazada coupon scam shared on Facebook groups',
      description: 'Same link circulated in three Buy & Sell Facebook groups before admins removed it.' },
    { title: 'Lazada phishing — fake "claim before midnight" countdown',
      description: 'Page shows a countdown timer to pressure victims. Login form is the harvest.' },
    { title: 'Lazada coupon phishing — captures recovery email too',
      description: 'After main login, the page asks for "recovery email" — used for downstream account-takeover.' },
    { title: 'Lazada phishing email variant — same backend domain',
      description: 'New email-based variant uses lazada-coupon-th.com. Looks like the same operator extending to email.' },
    { title: 'Lazada coupon scam — sister site for Shopee',
      description: 'Visiting shopee-coupon-th.com (same registrar, same operator) redirects to the Lazada phishing flow.' },
    { title: 'Lazada coupon URL passed adolescent filtering',
      description: 'My 14-year-old followed the link expecting a real promo. He gave login + parents\' card.' },
    { title: 'Lazada phishing site uses real Lazada CSS bundle',
      description: 'Page bundles the legitimate Lazada CSS via hotlink for visual fidelity.' },
    { title: 'Lazada coupon — fake "lucky wheel" variant',
      description: 'Instead of a static page, this variant shows a "spin to win" wheel that always lands on 500 THB then asks to login to claim.' },
    { title: 'Lazada coupon scam — distributed via LINE OpenChat',
      description: 'Bot accounts dropping the link into LINE OpenChat shopping groups. Same URL.' },
  ],
};

const GOV_GRANT_BANK: VariantBank = {
  scamTypeCode: 'phone_impersonation',
  identifierKind: 'phone',
  suspectedNameAtSubmit: 'Khun Nattapong Sirivat',
  templates: [
    { title: 'Government-grant scam call — Khon-La-Kreung "remainder"',
      description: 'Caller claimed I had an unclaimed 5,500 THB Khon-La-Kreung balance and demanded a 200 THB "release fee".' },
    { title: 'Gov grant scam — pivoted to "stimulus" angle when challenged',
      description: 'When I questioned the Khon-La-Kreung claim, the caller switched to "stimulus reimbursement". Same script underneath.' },
    { title: 'Gov grant scam targeted elderly — 8 victims in our soi',
      description: 'Eight people on our street, mostly 65+, received the same call this month. Caller used real names from voter lists.' },
    { title: 'Gov grant phisher mentioned real Ministry of Finance circular',
      description: 'Quoted a real MoF circular number to add credibility. Circular exists but does not say what they claim.' },
    { title: 'Gov grant scam — caller offered to "process via PromptPay"',
      description: 'Asked me to PromptPay 200 THB to a "release officer" so the 5,500 THB could be released. PromptPay account name was unrelated to MoF.' },
    { title: 'Gov grant scam — sent fake confirmation slip via LINE',
      description: 'After call, sent a Photoshopped Ministry confirmation slip via LINE. Wrong fonts, wrong seal.' },
    { title: 'Gov grant scam — escalation to "police arrest" threat',
      description: 'When I refused, the caller threatened that "police would visit for ignoring a government order". Same MO as Revenue Dept campaign.' },
    { title: 'Gov grant scam coordinated with government-app outage',
      description: 'Calls peaked during a Pao Tang app outage day. Victims couldn\'t verify claims via the real app.' },
  ],
};

// --- Generate the scenario list -----------------------------------------

const ATTRIBUTED: ReportScenario[] = [
  ...variantsFor(scammerByKey('revenue_dept')!,        REVENUE_BANK,       10),
  ...variantsFor(scammerByKey('customs_duty')!,        CUSTOMS_BANK,       10),
  ...variantsFor(scammerByKey('scb_fraud')!,           SCB_BANK,           10),
  ...variantsFor(scammerByKey('kerry_phish')!,         KERRY_BANK,         10),
  ...variantsFor(scammerByKey('ktb_phish')!,           KTB_BANK,           10),
  ...variantsFor(scammerByKey('ig_ghost')!,            IG_BANK,            10),
  ...variantsFor(scammerByKey('line_romance')!,        LINE_ROMANCE_BANK,  10),
  ...variantsFor(scammerByKey('utility_bill_sms')!,    UTILITY_BANK,       10),
  ...variantsFor(scammerByKey('otp_caller')!,          OTP_BANK,            8),
  ...variantsFor(scammerByKey('lazada_coupon')!,       LAZADA_BANK,        10),
  ...variantsFor(scammerByKey('gov_grant')!,           GOV_GRANT_BANK,      8),
];

// QR Swap Crew has no identifier — auto-link by identifier won't fire, but
// the name-based auto-link in admin-reports.service.ts:318 picks it up at
// approve time if scammer.personFullName matches. QR Swap Crew has no
// person, so these effectively stay scammer-less unless an admin links by
// hand — same as production reality. 6 such scenarios.
const QR_SCENARIOS: ReportScenario[] = QR_BANK.templates.slice(0, 6).map((t, i) => {
  const actions = distribute(6);
  return {
    title: `${t.title} [qr_swap#${i + 1}]`,
    description: t.description,
    scamTypeCode: QR_BANK.scamTypeCode,
    scammerKey: 'qr_swap',
    identifierKind: 'other' as const,
    identifier: null,
    action: actions[i] ?? 'pending',
    daysAgo: 1 + Math.floor(((i + 1) * 7919) % 80),
  };
});

// Deliberately-orphan scenarios — no scammer link, no identifier overlap.
// Exercises the "moderator links the scammer by hand" path (or leaves the
// report standalone for the legacy identifier match).
const ORPHAN_SCENARIOS: ReportScenario[] = [
  {
    title: 'Suspicious package from real DHL — turned out legit [orphan#1]',
    description: 'Got a notification from DHL.co.th about a package I forgot I ordered. Was worried it was phishing but the tracking checked out. Adding so others know the real domain.',
    scamTypeCode: 'other',
    scammerKey: null, identifierKind: null, identifier: null,
    action: 'reject', daysAgo: 6,
  },
  {
    title: 'Marketplace iPhone listing — paid but never delivered [orphan#2]',
    description: 'Seller on Facebook Marketplace demanded full transfer up front for a "barely used" iPhone 14, then blocked me after payment of 18,000 THB.',
    scamTypeCode: 'ecommerce_fraud',
    scammerKey: null, identifierKind: null, identifier: null,
    action: 'approve', daysAgo: 17,
  },
  {
    title: 'Fake job posting collected ID card scans [orphan#3]',
    description: 'LinkedIn-style job posting for a "data entry assistant" asked applicants to email a copy of their ID card and bank book.',
    scamTypeCode: 'other',
    scammerKey: null, identifierKind: null, identifier: null,
    action: 'approve', daysAgo: 25,
  },
  {
    title: 'Crypto giveaway scam on Twitter [orphan#4]',
    description: 'Account impersonating a celebrity offered to "double any ETH sent to this address". Classic crypto-giveaway pattern.',
    scamTypeCode: 'investment_fraud',
    scammerKey: null, identifierKind: null, identifier: null,
    action: 'approve', daysAgo: 30,
  },
  {
    title: 'Fake recruiter LINE OpenChat job offer [orphan#5]',
    description: 'Joined an OpenChat about job opportunities. A "recruiter" offered remote work for a HK firm — required a 4,200 THB deposit for "equipment".',
    scamTypeCode: 'other',
    scammerKey: null, identifierKind: null, identifier: null,
    action: 'flag', daysAgo: 33,
  },
  {
    title: 'Investment platform showed paper profits then locked withdrawals [orphan#6]',
    description: 'Deposited 30,000 THB into a "guaranteed return" platform. Dashboard showed 14% monthly gains. Withdrawals were locked behind a "tax fee" of 8,000 THB.',
    scamTypeCode: 'investment_fraud',
    scammerKey: null, identifierKind: null, identifier: null,
    action: 'approve', daysAgo: 41,
  },
  {
    title: 'Fake charity collection during flood relief [orphan#7]',
    description: 'Group posing as a flood-relief charity in the Lopburi area collected donations via PromptPay. The named organisation has no Lopburi field op.',
    scamTypeCode: 'other',
    scammerKey: null, identifierKind: null, identifier: null,
    action: 'pending', daysAgo: 7,
  },
  {
    title: 'Cold-DM crypto trader on Twitter [orphan#8]',
    description: 'A trader followed me and DMed about "exclusive insider tips". Wanted access to my Binance account "to help".',
    scamTypeCode: 'investment_fraud',
    scammerKey: null, identifierKind: null, identifier: null,
    action: 'flag', daysAgo: 11,
  },
  {
    title: 'Fake "ETDA verified" sticker on dubious site [orphan#9]',
    description: 'Site displayed an ETDA verification badge that linked to a non-existent ETDA page. Real ETDA badges link to the official portal.',
    scamTypeCode: 'other',
    scammerKey: null, identifierKind: null, identifier: null,
    action: 'pending', daysAgo: 19,
  },
  {
    title: 'False vaccine-record correction call [orphan#10]',
    description: 'Caller said my Mor-Prom vaccine record was incorrect and demanded a 350 THB "correction fee" via PromptPay. Real Mor-Prom is free.',
    scamTypeCode: 'phone_impersonation',
    scammerKey: null, identifierKind: null, identifier: null,
    action: 'reject', daysAgo: 22,
  },
];

export const REPORT_SCENARIOS: ReportScenario[] = [
  ...ATTRIBUTED,
  ...QR_SCENARIOS,
  ...ORPHAN_SCENARIOS,
];

// =============================================================================
// Ask AI conversations (10)
// =============================================================================

export interface AiConversationScript {
  // Whether this conversation should be linked to a report at seed time.
  // The seed-flow keeps a map of (scammerKey → first verified report id) so
  // we can backfill the link after createReport runs. null = unlinked.
  linkedScammerKey: string | null;
  draft: boolean;                 // 2 of 10 carry a draftState JSON blob
  messages: Array<{
    role: 'user' | 'assistant';
    content: string;
    intentDetected?: boolean;
  }>;
}

export const AI_CONVERSATIONS: AiConversationScript[] = [
  {
    linkedScammerKey: 'revenue_dept',
    draft: true,
    messages: [
      { role: 'user', content: 'I got a call from someone claiming to be from the Revenue Department asking for a tax transfer. Is this a scam?' },
      { role: 'assistant', content: 'That pattern is one of the most-reported scams in Thailand. Real Revenue Dept officers never demand transfers over the phone. Could you tell me the phone number and what they asked for?' },
      { role: 'user', content: '+66 2 999 1234. They wanted 27,800 THB.', intentDetected: true },
      { role: 'assistant', content: 'That number matches a known offender. I can help you file a report — want me to draft it?' },
      { role: 'user', content: 'Yes please.', intentDetected: true },
      { role: 'assistant', content: 'I\'ve drafted the report. You can review it in the My Reports tab and submit when ready.' },
    ],
  },
  {
    linkedScammerKey: 'scb_fraud',
    draft: false,
    messages: [
      { role: 'user', content: 'Bank called and asked for my OTP to "verify a transaction". Should I give it?' },
      { role: 'assistant', content: 'No. Real banks never ask for an OTP over the phone. Hang up and call the bank back through the number on the back of your card.' },
      { role: 'user', content: 'Thanks. The number was +66 2 777 9000.' },
      { role: 'assistant', content: 'That number is a known SCB fraud-desk impersonator. Want me to draft a report?' },
    ],
  },
  {
    linkedScammerKey: null,
    draft: false,
    messages: [
      { role: 'user', content: 'How can I tell if a URL is a phishing site?' },
      { role: 'assistant', content: 'Look for typos in the domain, weird subdomains, and recently-issued certificates. If you can share the URL, I can check our database.' },
      { role: 'user', content: 'https://kerry-th.delivery-check.co' },
      { role: 'assistant', content: 'That domain matches a known phishing campaign. Avoid it. Want me to draft a report?' },
    ],
  },
  {
    linkedScammerKey: 'ig_ghost',
    draft: true,
    messages: [
      { role: 'user', content: 'I paid 8,500 THB to an IG shop and they ghosted me.' },
      { role: 'assistant', content: 'Which handle? Some IG shops are repeat-offender ghost storefronts.' },
      { role: 'user', content: '@best-deals-th', intentDetected: true },
      { role: 'assistant', content: 'That handle has multiple confirmed scam reports. Let me draft a report for you to review.' },
      { role: 'user', content: 'OK please.', intentDetected: true },
      { role: 'assistant', content: 'Draft saved. You can finalise and submit from the My Reports tab.' },
    ],
  },
  {
    linkedScammerKey: null,
    draft: false,
    messages: [
      { role: 'user', content: 'What\'s the difference between a flagged and a rejected report?' },
      { role: 'assistant', content: 'Flagged = a moderator wants a second opinion before deciding. Rejected = the moderator decided the report doesn\'t match scam criteria (might be a misunderstanding, duplicate, or insufficient evidence). Flagged reports stay visible to other moderators; rejected ones are archived.' },
    ],
  },
  {
    linkedScammerKey: 'kerry_phish',
    draft: false,
    messages: [
      { role: 'user', content: 'My mom got a parcel SMS with a Kerry link.' },
      { role: 'assistant', content: 'What was the link?' },
      { role: 'user', content: 'kerry-th.delivery-check.co' },
      { role: 'assistant', content: 'Confirmed phishing. Tell her not to enter any details. I can help draft a report.' },
    ],
  },
  {
    linkedScammerKey: null,
    draft: false,
    messages: [
      { role: 'user', content: 'Is the Khon-La-Kreung programme still running?' },
      { role: 'assistant', content: 'Khon-La-Kreung ended in 2022. Anyone calling about a "remainder balance" is almost certainly a scammer.' },
      { role: 'user', content: 'Right, someone called my dad about a 5,500 THB unclaimed balance.', intentDetected: true },
      { role: 'assistant', content: 'Classic government-grant scam pattern. Want to file a report?' },
    ],
  },
  {
    linkedScammerKey: null,
    draft: false,
    messages: [
      { role: 'user', content: 'What evidence helps a scam report get verified faster?' },
      { role: 'assistant', content: 'Screenshots of the SMS / chat / website, transaction slips if money was lost, and the exact phone number or URL. The clearer the timeline, the easier moderation.' },
    ],
  },
  {
    linkedScammerKey: 'ktb_phish',
    draft: false,
    messages: [
      { role: 'user', content: 'ktb-secure-login.com — is this the real KTB site?' },
      { role: 'assistant', content: 'No. Real KTB uses ktb.co.th and the KTB NEXT app. ktb-secure-login.com is a known phishing domain.' },
      { role: 'user', content: 'My grandmother entered her credentials there.' },
      { role: 'assistant', content: 'Have her call the real KTB hotline immediately to freeze the account. I can also help you file a report.' },
    ],
  },
  {
    linkedScammerKey: null,
    draft: false,
    messages: [
      { role: 'user', content: 'How long does it take for a moderator to review my report?' },
      { role: 'assistant', content: 'Average is under 24 hours on weekdays. Reports with strong evidence and matching identifiers get verified fastest because the moderator can cross-reference them.' },
    ],
  },
];

// =============================================================================
// Announcements (6)
// =============================================================================

export interface AnnouncementScript {
  title: string;
  body: string;
  category: 'fraud_alert' | 'tips' | 'platform_update';
  sendPush: boolean;
}

export const ANNOUNCEMENTS: AnnouncementScript[] = [
  {
    title: 'Active Revenue Department impersonation campaign — beware',
    body: 'We\'re tracking an active phone scam where callers claim to be from the Revenue Department and demand transfers. Real officers will never request transfers over the phone. If you receive such a call, hang up and report it.',
    category: 'fraud_alert',
    sendPush: true,
  },
  {
    title: 'New phishing domain: kerry-th.delivery-check.co',
    body: 'A bulk SMS phishing campaign is sending fake Kerry parcel-tracking links. The domain captures bank credentials. Do not click links in unexpected parcel-tracking SMS.',
    category: 'fraud_alert',
    sendPush: true,
  },
  {
    title: 'IG storefront @best-deals-th confirmed as fraudulent',
    body: 'Multiple verified reports confirm @best-deals-th collects payment via bank transfer and ghosts buyers. Avoid the handle and any clones using the same images.',
    category: 'fraud_alert',
    sendPush: false,
  },
  {
    title: 'How to spot a fake banking call',
    body: 'Three rules: (1) Real banks never ask for your OTP, PIN, or full card number over the phone. (2) Hang up and call back via the number on your card. (3) When in doubt, visit a branch.',
    category: 'tips',
    sendPush: false,
  },
  {
    title: 'Setting up two-factor authentication on banking apps',
    body: 'Most Thai banks support 2FA via authenticator apps. We recommend enabling it for an extra layer beyond SMS codes, which can be intercepted via SIM swaps.',
    category: 'tips',
    sendPush: false,
  },
  {
    title: 'Platform update: faster moderation queue',
    body: 'We\'ve rolled out a new moderation queue with AI-assisted scoring. Average time-to-decision has dropped to under 18 hours.',
    category: 'platform_update',
    sendPush: false,
  },
];
