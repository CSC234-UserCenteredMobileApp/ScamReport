import { Type, type Static } from '@sinclair/typebox';

const BilingualCount = Type.Object({
  code: Type.String(),
  labelEn: Type.String(),
  labelTh: Type.String(),
  count: Type.Integer({ minimum: 0 }),
});
export type ScamOverviewBilingualCount = Static<typeof BilingualCount>;

const SiteCount = Type.Object({
  site: Type.String(),
  count: Type.Integer({ minimum: 0 }),
});
export type ScamOverviewSiteCount = Static<typeof SiteCount>;

const ProvinceCount = Type.Object({
  thai: Type.String(),
  english: Type.String(),
  count: Type.Integer({ minimum: 0 }),
});
export type ScamOverviewProvinceCount = Static<typeof ProvinceCount>;

const NationalityCount = Type.Object({
  english: Type.String(),
  thai: Type.String(),
  count: Type.Integer({ minimum: 0 }),
});
export type ScamOverviewNationalityCount = Static<typeof NationalityCount>;

const DailyBucket = Type.Object({
  date: Type.String(),
  count: Type.Integer({ minimum: 0 }),
});
export type ScamOverviewDailyBucket = Static<typeof DailyBucket>;

export const AdminScamOverviewResponse = Type.Object({
  totalReports: Type.Integer({ minimum: 0 }),
  totalScammers: Type.Integer({ minimum: 0 }),
  totalPersons: Type.Integer({ minimum: 0 }),
  byScamType: Type.Array(BilingualCount),
  bySourceSite: Type.Array(SiteCount),
  byProvince: Type.Array(ProvinceCount),
  byNationality: Type.Array(NationalityCount),
  byArrestStatus: Type.Array(BilingualCount),
  dailyReports: Type.Array(DailyBucket),
  generatedAt: Type.String({ format: 'date-time' }),
});
export type AdminScamOverviewResponse = Static<typeof AdminScamOverviewResponse>;
