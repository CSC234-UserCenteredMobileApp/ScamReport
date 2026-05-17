// Thai ↔ English province lookup. Keyed by every form we have seen in the
// news-crawler output (Thai short form, Thai full form, English). Each entry
// resolves to the canonical { thai, english } pair so consumers always get
// both labels regardless of which form was stored.

export type ProvinceLabel = { thai: string; english: string };

const ENTRIES: ProvinceLabel[] = [
  { thai: 'กรุงเทพฯ', english: 'Bangkok' },
  { thai: 'เชียงใหม่', english: 'Chiang Mai' },
  { thai: 'เชียงราย', english: 'Chiang Rai' },
  { thai: 'นนทบุรี', english: 'Nonthaburi' },
  { thai: 'ปทุมธานี', english: 'Pathum Thani' },
  { thai: 'สมุทรปราการ', english: 'Samut Prakan' },
  { thai: 'ชลบุรี', english: 'Chonburi' },
  { thai: 'ระยอง', english: 'Rayong' },
  { thai: 'นครราชสีมา', english: 'Nakhon Ratchasima' },
  { thai: 'ขอนแก่น', english: 'Khon Kaen' },
  { thai: 'อุดรธานี', english: 'Udon Thani' },
  { thai: 'สงขลา', english: 'Songkhla' },
  { thai: 'ภูเก็ต', english: 'Phuket' },
  { thai: 'สุราษฎร์ธานี', english: 'Surat Thani' },
  { thai: 'กระบี่', english: 'Krabi' },
  { thai: 'พังงา', english: 'Phang Nga' },
  { thai: 'ตรัง', english: 'Trang' },
  { thai: 'พัทลุง', english: 'Phatthalung' },
  { thai: 'ปัตตานี', english: 'Pattani' },
  { thai: 'ยะลา', english: 'Yala' },
  { thai: 'นราธิวาส', english: 'Narathiwat' },
  { thai: 'ระนอง', english: 'Ranong' },
  { thai: 'ชุมพร', english: 'Chumphon' },
  { thai: 'นครศรีธรรมราช', english: 'Nakhon Si Thammarat' },
  { thai: 'ราชบุรี', english: 'Ratchaburi' },
  { thai: 'กาญจนบุรี', english: 'Kanchanaburi' },
  { thai: 'สุพรรณบุรี', english: 'Suphan Buri' },
  { thai: 'นครปฐม', english: 'Nakhon Pathom' },
  { thai: 'สมุทรสาคร', english: 'Samut Sakhon' },
  { thai: 'สมุทรสงคราม', english: 'Samut Songkhram' },
  { thai: 'เพชรบุรี', english: 'Phetchaburi' },
  { thai: 'ประจวบคีรีขันธ์', english: 'Prachuap Khiri Khan' },
  { thai: 'พระนครศรีอยุธยา', english: 'Phra Nakhon Si Ayutthaya' },
  { thai: 'อ่างทอง', english: 'Ang Thong' },
  { thai: 'ลพบุรี', english: 'Lop Buri' },
  { thai: 'สิงห์บุรี', english: 'Sing Buri' },
  { thai: 'ชัยนาท', english: 'Chai Nat' },
  { thai: 'สระบุรี', english: 'Saraburi' },
  { thai: 'นครนายก', english: 'Nakhon Nayok' },
  { thai: 'ปราจีนบุรี', english: 'Prachin Buri' },
  { thai: 'สระแก้ว', english: 'Sa Kaeo' },
  { thai: 'ฉะเชิงเทรา', english: 'Chachoengsao' },
  { thai: 'จันทบุรี', english: 'Chanthaburi' },
  { thai: 'ตราด', english: 'Trat' },
  { thai: 'ตาก', english: 'Tak' },
  { thai: 'สุโขทัย', english: 'Sukhothai' },
  { thai: 'พิษณุโลก', english: 'Phitsanulok' },
  { thai: 'กำแพงเพชร', english: 'Kamphaeng Phet' },
  { thai: 'พิจิตร', english: 'Phichit' },
  { thai: 'เพชรบูรณ์', english: 'Phetchabun' },
  { thai: 'อุตรดิตถ์', english: 'Uttaradit' },
  { thai: 'น่าน', english: 'Nan' },
  { thai: 'แพร่', english: 'Phrae' },
  { thai: 'พะเยา', english: 'Phayao' },
  { thai: 'ลำปาง', english: 'Lampang' },
  { thai: 'ลำพูน', english: 'Lamphun' },
  { thai: 'แม่ฮ่องสอน', english: 'Mae Hong Son' },
  { thai: 'เลย', english: 'Loei' },
  { thai: 'หนองคาย', english: 'Nong Khai' },
  { thai: 'บึงกาฬ', english: 'Bueng Kan' },
  { thai: 'นครพนม', english: 'Nakhon Phanom' },
  { thai: 'สกลนคร', english: 'Sakon Nakhon' },
  { thai: 'มุกดาหาร', english: 'Mukdahan' },
  { thai: 'หนองบัวลำภู', english: 'Nong Bua Lam Phu' },
  { thai: 'กาฬสินธุ์', english: 'Kalasin' },
  { thai: 'มหาสารคาม', english: 'Maha Sarakham' },
  { thai: 'ร้อยเอ็ด', english: 'Roi Et' },
  { thai: 'ยโสธร', english: 'Yasothon' },
  { thai: 'อำนาจเจริญ', english: 'Amnat Charoen' },
  { thai: 'อุบลราชธานี', english: 'Ubon Ratchathani' },
  { thai: 'ศรีสะเกษ', english: 'Si Sa Ket' },
  { thai: 'สุรินทร์', english: 'Surin' },
  { thai: 'บุรีรัมย์', english: 'Buri Ram' },
  { thai: 'ชัยภูมิ', english: 'Chaiyaphum' },
  { thai: 'นครสวรรค์', english: 'Nakhon Sawan' },
  { thai: 'อุทัยธานี', english: 'Uthai Thani' },
  { thai: 'ลำปาง', english: 'Lampang' },
];

// Build a case-insensitive index keyed by every known form (Thai short/full +
// English, and historical aliases like 'กรุงเทพ' / 'กรุงเทพมหานคร').
const INDEX = new Map<string, ProvinceLabel>();

function add(key: string, label: ProvinceLabel) {
  INDEX.set(key.toLowerCase(), label);
}

for (const e of ENTRIES) {
  add(e.thai, e);
  add(e.english, e);
}
// Bangkok aliases.
const bangkok = ENTRIES.find((e) => e.english === 'Bangkok')!;
add('กรุงเทพ', bangkok);
add('กรุงเทพมหานคร', bangkok);

/**
 * Resolve a province token (Thai short/full or English) to its bilingual
 * pair. Falls back to `{ thai: raw, english: raw }` when unknown — the
 * dashboard renders the raw value so we never silently drop a province.
 */
export function resolveProvince(raw: string | null | undefined): ProvinceLabel | null {
  if (!raw) return null;
  const hit = INDEX.get(raw.toLowerCase());
  if (hit) return hit;
  return { thai: raw, english: raw };
}
