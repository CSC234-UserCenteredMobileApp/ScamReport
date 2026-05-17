// Bilingual labels for the crawler's `arrest_status` enum.
// Values seen in current crawler output: arrested | wanted | unknown.

export type ArrestStatusLabel = { code: string; labelEn: string; labelTh: string };

const ENTRIES: ArrestStatusLabel[] = [
  { code: 'arrested', labelEn: 'Arrested', labelTh: 'ถูกจับกุม' },
  { code: 'wanted', labelEn: 'Wanted', labelTh: 'หมายจับ' },
  { code: 'fled', labelEn: 'Fled', labelTh: 'หลบหนี' },
  { code: 'unknown', labelEn: 'Unknown', labelTh: 'ไม่ทราบ' },
];

const INDEX = new Map<string, ArrestStatusLabel>(ENTRIES.map((e) => [e.code, e]));

/**
 * Resolve an arrest-status code to a bilingual label. Falls back to a
 * synthetic label with the raw code when unknown so the dashboard never
 * drops a value.
 */
export function resolveArrestStatus(raw: string | null | undefined): ArrestStatusLabel | null {
  if (!raw) return null;
  const hit = INDEX.get(raw.toLowerCase());
  if (hit) return hit;
  return { code: raw, labelEn: raw, labelTh: raw };
}
