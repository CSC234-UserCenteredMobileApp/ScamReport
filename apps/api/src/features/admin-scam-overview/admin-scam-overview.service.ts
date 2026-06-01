// DB-backed admin scam-overview aggregations. Reads from Postgres only —
// every label is materialised in both EN and TH so the dashboard renders
// bilingually without depending on the client's locale state.
//
// Crawler-imported reports populate the geo/source columns (province on
// Scammer, source_site/scraped_at on Report); user-submitted reports leave
// them NULL, so those breakdowns count only the crawler-imported subset.

import type {
  AdminScamOverviewResponse,
  ScamOverviewBilingualCount,
  ScamOverviewNationalityCount,
  ScamOverviewProvinceCount,
  ScamOverviewSiteCount,
  ScamOverviewDailyBucket,
} from '@my-product/shared';
import {
  resolveArrestStatus,
  resolveNationality,
  resolveProvince,
} from '@my-product/shared';
import { getPrisma } from '../../core/db/client';

const TOP_LIMIT = 10;

type RawCount<T extends string> = { [K in T]: string | null } & { count: bigint };

export async function getScamOverview(): Promise<AdminScamOverviewResponse> {
  const prisma = getPrisma();

  const [
    totalReports,
    totalScammers,
    totalPersons,
    scamTypeRows,
    sourceSiteRows,
    provinceRows,
    nationalityRows,
    arrestStatusRows,
    dailyRows,
    sourceSiteTotalRows,
    provinceTotalRows,
    nationalityTotalRows,
    arrestStatusTotalRows,
  ] = await Promise.all([
    prisma.report.count(),
    prisma.scammer.count(),
    prisma.person.count(),
    prisma.report.groupBy({
      by: ['scamTypeId'],
      _count: { scamTypeId: true },
      orderBy: { _count: { scamTypeId: 'desc' } },
    }),
    prisma.$queryRaw<RawCount<'site'>[]>`
      SELECT source_site AS site, COUNT(*)::bigint AS count
      FROM reports
      WHERE source_site IS NOT NULL
      GROUP BY source_site
      ORDER BY count DESC, source_site ASC
      LIMIT ${TOP_LIMIT}
    `,
    prisma.$queryRaw<RawCount<'province'>[]>`
      SELECT s.province AS province, COUNT(r.id)::bigint AS count
      FROM reports r
      JOIN scammers s ON s.id = r.scammer_id
      WHERE s.province IS NOT NULL
      GROUP BY s.province
      ORDER BY count DESC, s.province ASC
    `,
    prisma.$queryRaw<RawCount<'nationality'>[]>`
      SELECT s.nationality AS nationality, COUNT(r.id)::bigint AS count
      FROM reports r
      JOIN scammers s ON s.id = r.scammer_id
      WHERE s.nationality IS NOT NULL
      GROUP BY s.nationality
      ORDER BY count DESC, s.nationality ASC
    `,
    prisma.$queryRaw<RawCount<'arrest_status'>[]>`
      SELECT s.arrest_status, COUNT(r.id)::bigint AS count
      FROM reports r
      JOIN scammers s ON s.id = r.scammer_id
      WHERE s.arrest_status IS NOT NULL
      GROUP BY s.arrest_status
      ORDER BY count DESC, s.arrest_status ASC
    `,
    prisma.$queryRaw<{ date: string; count: bigint }[]>`
      SELECT to_char(date_trunc('day', COALESCE(verified_at, created_at)), 'YYYY-MM-DD') AS date,
             COUNT(*)::bigint AS count
      FROM reports
      GROUP BY 1
      ORDER BY 1 ASC
    `,
    // Full-population denominators for the truncated/filtered breakdowns, so the
    // dashboard can show an honest share-of-total (top-N rows won't sum to 100%).
    prisma.$queryRaw<{ count: bigint }[]>`
      SELECT COUNT(*)::bigint AS count FROM reports WHERE source_site IS NOT NULL
    `,
    prisma.$queryRaw<{ count: bigint }[]>`
      SELECT COUNT(r.id)::bigint AS count
      FROM reports r JOIN scammers s ON s.id = r.scammer_id
      WHERE s.province IS NOT NULL
    `,
    prisma.$queryRaw<{ count: bigint }[]>`
      SELECT COUNT(r.id)::bigint AS count
      FROM reports r JOIN scammers s ON s.id = r.scammer_id
      WHERE s.nationality IS NOT NULL
    `,
    prisma.$queryRaw<{ count: bigint }[]>`
      SELECT COUNT(r.id)::bigint AS count
      FROM reports r JOIN scammers s ON s.id = r.scammer_id
      WHERE s.arrest_status IS NOT NULL
    `,
  ]);

  const scamTypeIds = scamTypeRows.map((r) => r.scamTypeId);
  const scamTypes = scamTypeIds.length
    ? await prisma.scamType.findMany({
        where: { id: { in: scamTypeIds } },
        select: { id: true, code: true, labelEn: true, labelTh: true },
      })
    : [];
  const scamTypeById = new Map(scamTypes.map((s) => [s.id, s]));

  const byScamType: ScamOverviewBilingualCount[] = scamTypeRows.map((r) => {
    const st = scamTypeById.get(r.scamTypeId);
    return {
      code: st?.code ?? `id:${r.scamTypeId}`,
      labelEn: st?.labelEn ?? 'Unknown',
      labelTh: st?.labelTh ?? 'ไม่ทราบ',
      count: r._count.scamTypeId,
    };
  });

  const bySourceSite: ScamOverviewSiteCount[] = sourceSiteRows.map((r) => ({
    site: r.site ?? '',
    count: Number(r.count),
  }));

  // Multiple raw spellings ('กรุงเทพ' vs 'กรุงเทพมหานคร' vs 'Bangkok') resolve
  // to the same canonical pair — merge them after the SQL GROUP BY so the
  // dashboard doesn't show three Bangkok rows.
  const provinceAcc = new Map<string, ScamOverviewProvinceCount>();
  for (const r of provinceRows) {
    const pair = resolveProvince(r.province) ?? {
      thai: r.province ?? '',
      english: r.province ?? '',
    };
    const k = pair.english.toLowerCase();
    const prev = provinceAcc.get(k);
    const count = Number(r.count);
    if (prev) prev.count += count;
    else provinceAcc.set(k, { thai: pair.thai, english: pair.english, count });
  }
  const byProvince = [...provinceAcc.values()]
    .sort((a, b) => b.count - a.count || a.english.localeCompare(b.english))
    .slice(0, TOP_LIMIT);

  const nationalityAcc = new Map<string, ScamOverviewNationalityCount>();
  for (const r of nationalityRows) {
    const pair = resolveNationality(r.nationality) ?? {
      english: r.nationality ?? '',
      thai: r.nationality ?? '',
    };
    const k = pair.english.toLowerCase();
    const prev = nationalityAcc.get(k);
    const count = Number(r.count);
    if (prev) prev.count += count;
    else nationalityAcc.set(k, { english: pair.english, thai: pair.thai, count });
  }
  const byNationality = [...nationalityAcc.values()]
    .sort((a, b) => b.count - a.count || a.english.localeCompare(b.english))
    .slice(0, TOP_LIMIT);

  const byArrestStatus: ScamOverviewBilingualCount[] = arrestStatusRows.map((r) => {
    const code = r.arrest_status ?? 'unknown';
    const label = resolveArrestStatus(code) ?? {
      code,
      labelEn: code,
      labelTh: code,
    };
    return {
      code: label.code,
      labelEn: label.labelEn,
      labelTh: label.labelTh,
      count: Number(r.count),
    };
  });

  const dailyReports: ScamOverviewDailyBucket[] = dailyRows.map((r) => ({
    date: r.date,
    count: Number(r.count),
  }));

  const scalar = (rows: { count: bigint }[]) => Number(rows[0]?.count ?? 0n);

  return {
    totalReports,
    totalScammers,
    totalPersons,
    byScamType,
    bySourceSite,
    byProvince,
    byNationality,
    byArrestStatus,
    sourceSiteTotal: scalar(sourceSiteTotalRows),
    provinceTotal: scalar(provinceTotalRows),
    nationalityTotal: scalar(nationalityTotalRows),
    arrestStatusTotal: scalar(arrestStatusTotalRows),
    dailyReports,
    generatedAt: new Date().toISOString(),
  };
}
