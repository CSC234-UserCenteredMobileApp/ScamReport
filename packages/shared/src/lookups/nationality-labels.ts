// English ↔ Thai nationality lookup. Crawler stores English ("Thai",
// "Chinese", ...) but a comma-joined value like "Nigerian, Ivorian" can occur;
// callers should split on comma before lookup if they want per-token bilinguals.

export type NationalityLabel = { english: string; thai: string };

const ENTRIES: NationalityLabel[] = [
  { english: 'Thai', thai: 'ไทย' },
  { english: 'Chinese', thai: 'จีน' },
  { english: 'Vietnamese', thai: 'เวียดนาม' },
  { english: 'Lao', thai: 'ลาว' },
  { english: 'Burmese', thai: 'พม่า' },
  { english: 'Myanmar', thai: 'พม่า' },
  { english: 'Cambodian', thai: 'กัมพูชา' },
  { english: 'Malaysian', thai: 'มาเลเซีย' },
  { english: 'Indonesian', thai: 'อินโดนีเซีย' },
  { english: 'Filipino', thai: 'ฟิลิปปินส์' },
  { english: 'Korean', thai: 'เกาหลี' },
  { english: 'Japanese', thai: 'ญี่ปุ่น' },
  { english: 'Taiwanese', thai: 'ไต้หวัน' },
  { english: 'Indian', thai: 'อินเดีย' },
  { english: 'Russian', thai: 'รัสเซีย' },
  { english: 'Ukrainian', thai: 'ยูเครน' },
  { english: 'Nigerian', thai: 'ไนจีเรีย' },
  { english: 'Ivorian', thai: 'ไอวอรีโคสต์' },
  { english: 'British', thai: 'อังกฤษ' },
  { english: 'American', thai: 'อเมริกัน' },
  { english: 'Australian', thai: 'ออสเตรเลีย' },
  { english: 'German', thai: 'เยอรมัน' },
  { english: 'French', thai: 'ฝรั่งเศส' },
  { english: 'Other', thai: 'อื่นๆ' },
];

const INDEX = new Map<string, NationalityLabel>();
for (const e of ENTRIES) {
  INDEX.set(e.english.toLowerCase(), e);
  INDEX.set(e.thai, e);
}

/**
 * Resolve a nationality token (English or Thai) to a bilingual pair. Falls
 * back to `{ english: raw, thai: raw }` when unknown.
 */
export function resolveNationality(raw: string | null | undefined): NationalityLabel | null {
  if (!raw) return null;
  const hit = INDEX.get(raw.toLowerCase()) ?? INDEX.get(raw);
  if (hit) return hit;
  return { english: raw, thai: raw };
}
