// Labelled eval cases for the headless AI accuracy harness. 25 cases —
// 10 phone, 8 url, 7 free-text — mirroring scam patterns from
// seed-scammers + seed-reports. Hand-curated, no DB dependency.
//
// Each row carries the input payload + the expected verdict and (where
// relevant) the expected scammer displayName. The runner resolves
// displayName → scammerId at runtime so this file stays portable across
// reseeds.

export type EvalInputType = 'phone' | 'url' | 'text';
export type EvalVerdict = 'scam' | 'suspicious' | 'safe' | 'unknown';

export interface EvalCase {
  label: string;
  inputType: EvalInputType;
  inputPayload: string;
  expectedVerdict: EvalVerdict;
  /** Display name of the scammer we expect /check to surface; null = no scammer expected. */
  expectedScammerDisplayName?: string | null;
}

export const EVAL_CASES: EvalCase[] = [
  // ---------- phone (10) ----------
  {
    label: 'phone-revenue-known',
    inputType: 'phone',
    inputPayload: '+66 2 999 1234',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'Revenue Dept Impersonator',
  },
  {
    label: 'phone-revenue-known-thai-prefix',
    inputType: 'phone',
    inputPayload: '029991234',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'Revenue Dept Impersonator',
  },
  {
    label: 'phone-customs-known',
    inputType: 'phone',
    inputPayload: '+66 2 999 5678',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'Customs Duty Scam Caller',
  },
  {
    label: 'phone-scb-known',
    inputType: 'phone',
    inputPayload: '+66 2 777 9000',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'SCB Fraud-Team Caller',
  },
  {
    label: 'phone-scb-known-thai-prefix',
    inputType: 'phone',
    inputPayload: '027779000',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'SCB Fraud-Team Caller',
  },
  {
    label: 'phone-unknown-clean',
    inputType: 'phone',
    inputPayload: '+66819998888',
    expectedVerdict: 'safe',
    expectedScammerDisplayName: null,
  },
  {
    label: 'phone-unknown-thai-prefix',
    inputType: 'phone',
    inputPayload: '0812345678',
    expectedVerdict: 'safe',
    expectedScammerDisplayName: null,
  },
  {
    label: 'phone-unknown-random',
    inputType: 'phone',
    inputPayload: '+66 81 555 0000',
    expectedVerdict: 'safe',
    expectedScammerDisplayName: null,
  },
  {
    label: 'phone-empty-pad',
    inputType: 'phone',
    inputPayload: '+66 2 999 9999',
    expectedVerdict: 'safe',
    expectedScammerDisplayName: null,
  },
  {
    label: 'phone-revenue-spaced',
    inputType: 'phone',
    inputPayload: '+66-2-999-1234',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'Revenue Dept Impersonator',
  },

  // ---------- url (8) ----------
  {
    label: 'url-kerry-known',
    inputType: 'url',
    inputPayload: 'https://kerry-th.delivery-check.co',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'Kerry Parcel Phisher',
  },
  {
    label: 'url-kerry-known-no-proto',
    inputType: 'url',
    inputPayload: 'kerry-th.delivery-check.co',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'Kerry Parcel Phisher',
  },
  {
    label: 'url-ktb-known',
    inputType: 'url',
    inputPayload: 'https://ktb-secure-login.com',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'KTB Phishing Ring',
  },
  {
    label: 'url-ktb-known-no-proto',
    inputType: 'url',
    inputPayload: 'ktb-secure-login.com',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'KTB Phishing Ring',
  },
  {
    label: 'url-unknown-clean',
    inputType: 'url',
    inputPayload: 'https://example.com',
    expectedVerdict: 'safe',
    expectedScammerDisplayName: null,
  },
  {
    label: 'url-unknown-google',
    inputType: 'url',
    inputPayload: 'https://www.google.com',
    expectedVerdict: 'safe',
    expectedScammerDisplayName: null,
  },
  {
    label: 'url-unknown-https',
    inputType: 'url',
    inputPayload: 'https://news.example.org',
    expectedVerdict: 'safe',
    expectedScammerDisplayName: null,
  },
  {
    label: 'url-kerry-trailing-slash',
    inputType: 'url',
    inputPayload: 'https://kerry-th.delivery-check.co/',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'Kerry Parcel Phisher',
  },

  // ---------- text / free-form (7) ----------
  {
    label: 'text-revenue-narrative',
    inputType: 'text',
    inputPayload:
      'Got call from revenue department demanding 27800 baht tax penalty, threatening arrest if no transfer.',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'Revenue Dept Impersonator',
  },
  {
    label: 'text-kerry-sms-narrative',
    inputType: 'text',
    inputPayload:
      'Received SMS saying my Kerry parcel was held, link asks for ID card and bank login.',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'Kerry Parcel Phisher',
  },
  {
    label: 'text-ktb-narrative',
    inputType: 'text',
    inputPayload:
      'SMS warned my Krungthai account would be locked, sent me to ktb-secure-login.com which asked for PIN.',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'KTB Phishing Ring',
  },
  {
    label: 'text-scb-otp',
    inputType: 'text',
    inputPayload:
      'Caller from SCB fraud team asked me to read OTP to block suspicious transaction.',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'SCB Fraud-Team Caller',
  },
  {
    label: 'text-ig-shop',
    inputType: 'text',
    inputPayload:
      'Instagram shop @best-deals-th took my payment for iPhone bundle but never shipped.',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'IG Marketplace Ghost',
  },
  {
    label: 'text-safe-question',
    inputType: 'text',
    inputPayload:
      'Got a real Lazada package notification with valid tracking number, just wanted to confirm.',
    expectedVerdict: 'safe',
    expectedScammerDisplayName: null,
  },
  {
    label: 'text-safe-weather',
    inputType: 'text',
    inputPayload: 'The weather is nice today, going for a walk.',
    expectedVerdict: 'safe',
    expectedScammerDisplayName: null,
  },
];
