import { Type, type Static } from '@sinclair/typebox';

export const ReportCard = Type.Object({
  id: Type.String({ format: 'uuid' }),
  title: Type.String(),
  excerpt: Type.String(),
  scamTypeCode: Type.String(),
  scamTypeLabelEn: Type.String(),
  scamTypeLabelTh: Type.String(),
  verifiedAt: Type.String({ format: 'date-time' }),
  reportCount: Type.Integer({ minimum: 1 }),
});
export type ReportCard = Static<typeof ReportCard>;

export const ReportListResponse = Type.Object({
  items: Type.Array(ReportCard),
});
export type ReportListResponse = Static<typeof ReportListResponse>;
