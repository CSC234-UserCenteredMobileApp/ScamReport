// Extract + normalise phone-number and URL identifiers from free-text user
// input. Shared between `POST /check` (which receives the raw payload from
// the verdict flow) and Ask AI (which scans every conversation turn for
// identifiers the user mentioned).
//
// The patterns are intentionally narrow — false negatives are fine because
// Ask AI's semantic retrieval is a safety net. False positives matter more:
// matching against `reports.target_identifier_normalized` is exact, so a
// spurious match would surface an unrelated verified report as "evidence."
// If you tune these regexes, run the identifier-extractor.test fixtures.

/**
 * Normalise a phone number to E.164-ish (`+66…`) when the input looks Thai
 * (`0XXXXXXXX`), otherwise strip separators. Matches the long-standing
 * behaviour the /check route relied on.
 */
export function normalizePhone(raw: string): string {
  const stripped = raw.replace(/[\s\-\(\)]/g, '');
  if (/^0\d{8,9}$/.test(stripped)) return '+66' + stripped.slice(1);
  return stripped;
}

/**
 * Normalise a URL to its lowercased hostname. Bare domains are tolerated by
 * prepending `https://` before parsing.
 */
export function normalizeUrl(raw: string): string {
  try {
    const url = new URL(raw.startsWith('http') ? raw : 'https://' + raw);
    return url.hostname.toLowerCase();
  } catch (_e) {
    return raw.toLowerCase().trim();
  }
}

// Match http(s) URLs and bare domain-like tokens (`k-bank.xyz`).
// Anchored to word boundaries so it doesn't pick up the `.` at end of a
// sentence as part of the token.
const URL_RE = /\bhttps?:\/\/[^\s<>"']+|\b(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,}\b/gi;

// Match Thai phone numbers. Requires a leading 0 or +66, ≥9 digits total,
// allows spaces / hyphens / dots / parens inside the run. The post-extract
// `normalizePhone` strips the separators.
const PHONE_RE = /(?:\+66|0)(?:[\s\-\.()]?\d){8,9}/g;

export interface ExtractedIdentifiers {
  phones: string[];
  urls: string[];
}

/**
 * Scan free-text input for phone-number / URL identifiers. Returns
 * deduplicated, normalised values — what `reports.target_identifier_normalized`
 * stores. Empty arrays when nothing matches.
 */
export function extractIdentifiers(text: string): ExtractedIdentifiers {
  if (!text) return { phones: [], urls: [] };

  const phones = new Set<string>();
  for (const match of text.matchAll(PHONE_RE)) {
    phones.add(normalizePhone(match[0]));
  }

  const urls = new Set<string>();
  for (const match of text.matchAll(URL_RE)) {
    // A bare hostname like `k-bank.xyz` is valid; full URL match is normalised
    // to its hostname. Skip phone-like all-digit "domains" the regex might
    // accidentally catch.
    const candidate = match[0];
    if (/^\d+$/.test(candidate)) continue;
    urls.add(normalizeUrl(candidate));
  }

  return {
    phones: [...phones],
    urls: [...urls],
  };
}
