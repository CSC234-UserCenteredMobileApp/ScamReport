// Labelled eval cases for the headless AI accuracy harness. 50 cases —
// 15 phone, 15 url, 20 free-text — mirroring scam patterns from
// seed-scammers + seed-reports plus adversarial coverage. Hand-curated,
// no DB dependency.
//
// Each row carries the input payload + the expected verdict and (where
// relevant) the expected scammer displayName. The runner resolves
// displayName → scammerId at runtime so this file stays portable across
// reseeds.
//
// Tags (optional): adversarial, paraphrase, lookalike, mixed-lang, garbage.
// Tags are filterable metadata — not aggregated in summaries today.

export type EvalInputType = 'phone' | 'url' | 'text';
export type EvalVerdict = 'scam' | 'suspicious' | 'safe' | 'unknown';

export interface EvalCase {
  label: string;
  inputType: EvalInputType;
  inputPayload: string;
  expectedVerdict: EvalVerdict;
  /** Display name of the scammer we expect /check to surface; null = no scammer expected. */
  expectedScammerDisplayName?: string | null;
  tags?: string[];
}

export const EVAL_CASES: EvalCase[] = [
  // ---------- phone (15) ----------
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
  // adversarial / new
  {
    label: 'phone-revenue-lookalike',
    inputType: 'phone',
    inputPayload: '+66 2 999 1235',
    expectedVerdict: 'safe',
    expectedScammerDisplayName: null,
    tags: ['adversarial', 'lookalike'],
  },
  {
    label: 'phone-intl-foreign',
    inputType: 'phone',
    inputPayload: '+1-555-019-9000',
    expectedVerdict: 'safe',
    expectedScammerDisplayName: null,
    tags: ['adversarial'],
  },
  {
    label: 'phone-customs-spaced',
    inputType: 'phone',
    inputPayload: '+66-2-999-5678',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'Customs Duty Scam Caller',
  },
  {
    label: 'phone-scb-dots',
    inputType: 'phone',
    inputPayload: '+66.2.777.9000',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'SCB Fraud-Team Caller',
    tags: ['adversarial'],
  },
  {
    label: 'phone-unknown-mobile',
    inputType: 'phone',
    inputPayload: '+66 95 111 2233',
    expectedVerdict: 'safe',
    expectedScammerDisplayName: null,
  },

  // ---------- url (15) ----------
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
  // adversarial / new
  {
    label: 'url-kerry-lookalike-safe',
    inputType: 'url',
    inputPayload: 'https://kerry-th.com',
    expectedVerdict: 'safe',
    expectedScammerDisplayName: null,
    tags: ['adversarial', 'lookalike'],
  },
  {
    label: 'url-ktb-uppercase',
    inputType: 'url',
    inputPayload: 'HTTPS://KTB-SECURE-LOGIN.COM',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'KTB Phishing Ring',
    tags: ['adversarial'],
  },
  {
    label: 'url-kerry-deep-path',
    inputType: 'url',
    inputPayload: 'https://kerry-th.delivery-check.co/track/parcel?id=42',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'Kerry Parcel Phisher',
    tags: ['adversarial'],
  },
  {
    label: 'url-malformed',
    inputType: 'url',
    inputPayload: 'htttps://broken',
    expectedVerdict: 'safe',
    expectedScammerDisplayName: null,
    tags: ['adversarial', 'garbage'],
  },
  {
    label: 'url-shortener-bitly',
    inputType: 'url',
    inputPayload: 'https://bit.ly/3xK9abc',
    expectedVerdict: 'safe',
    expectedScammerDisplayName: null,
    tags: ['adversarial'],
  },
  {
    label: 'url-typo-google',
    inputType: 'url',
    inputPayload: 'https://gogle.com',
    expectedVerdict: 'safe',
    expectedScammerDisplayName: null,
    tags: ['adversarial', 'lookalike'],
  },
  {
    label: 'url-unknown-thai-co',
    inputType: 'url',
    inputPayload: 'https://example.co.th',
    expectedVerdict: 'safe',
    expectedScammerDisplayName: null,
  },

  // ---------- text / free-form (20) ----------
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
  // paraphrased scams (+8)
  {
    label: 'text-revenue-paraphrase',
    inputType: 'text',
    inputPayload:
      'Someone from the taxation department called about overdue penalty of 27,800 baht and threatened an arrest warrant if I did not transfer immediately.',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'Revenue Dept Impersonator',
    tags: ['paraphrase'],
  },
  {
    label: 'text-kerry-paraphrase',
    inputType: 'text',
    inputPayload:
      'A courier SMS claimed my package was detained and the link wanted my national ID card number and bank login credentials.',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'Kerry Parcel Phisher',
    tags: ['paraphrase'],
  },
  {
    label: 'text-ktb-paraphrase',
    inputType: 'text',
    inputPayload:
      'SMS pretending to be Krungthai bank warned my account would be suspended, link asked for my online banking password.',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'KTB Phishing Ring',
    tags: ['paraphrase'],
  },
  {
    label: 'text-customs-paraphrase',
    inputType: 'text',
    inputPayload:
      'Customs department phoned demanding import duty payment for an international parcel I had never ordered.',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'Customs Duty Scam Caller',
    tags: ['paraphrase'],
  },
  {
    label: 'text-scb-paraphrase',
    inputType: 'text',
    inputPayload:
      'Caller said they were SCB security team and asked me to read out the OTP code to verify my identity.',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'SCB Fraud-Team Caller',
    tags: ['paraphrase'],
  },
  {
    label: 'text-ig-paraphrase',
    inputType: 'text',
    inputPayload:
      'Paid deposit to an Instagram seller @best-deals-th for an iPhone bundle, the shop went silent and never shipped.',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'IG Marketplace Ghost',
    tags: ['paraphrase'],
  },
  {
    label: 'text-investment-paraphrase',
    inputType: 'text',
    inputPayload:
      'Online trading platform promised 50% weekly returns, after I deposited the operators disappeared with my money.',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: null,
    tags: ['paraphrase'],
  },
  {
    label: 'text-otp-paraphrase',
    inputType: 'text',
    inputPayload:
      'Someone calling himself bank staff insisted I share the SMS verification code so he could cancel a fake unauthorized transaction.',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: null,
    tags: ['paraphrase'],
  },
  // scam-tone-but-safe (+3)
  {
    label: 'text-safe-tone-bank-verified',
    inputType: 'text',
    inputPayload:
      'My bank called about a real fraud alert; I hung up and called back via the official hotline on the back of my card to confirm.',
    expectedVerdict: 'safe',
    expectedScammerDisplayName: null,
    tags: ['adversarial'],
  },
  {
    label: 'text-safe-courier-real',
    inputType: 'text',
    inputPayload:
      'Real Kerry delivery driver dropped off my package today, tracking number matched and signature was collected.',
    expectedVerdict: 'safe',
    expectedScammerDisplayName: null,
    tags: ['adversarial'],
  },
  {
    label: 'text-safe-tax-real',
    inputType: 'text',
    inputPayload:
      'Revenue department mailed me the legitimate annual tax filing form with no money request, just paperwork.',
    expectedVerdict: 'safe',
    expectedScammerDisplayName: null,
    tags: ['adversarial'],
  },
  // mixed Thai/English (+2)
  {
    label: 'text-mixed-otp',
    inputType: 'text',
    inputPayload:
      'มีคนโทรมาอ้างว่าเป็น SCB security team ขอ OTP เพื่อยืนยันการทำรายการ suspicious.',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'SCB Fraud-Team Caller',
    tags: ['paraphrase', 'mixed-lang'],
  },
  {
    label: 'text-mixed-courier',
    inputType: 'text',
    inputPayload:
      'ได้รับ SMS อ้างว่า Kerry parcel ถูกกัก link ขอเลขบัตรประชาชน และ bank login.',
    expectedVerdict: 'scam',
    expectedScammerDisplayName: 'Kerry Parcel Phisher',
    tags: ['paraphrase', 'mixed-lang'],
  },
];
