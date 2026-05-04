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

export const ReportEvidenceFile = Type.Object({
  id: Type.String({ format: 'uuid' }),
  signedUrl: Type.Union([Type.String(), Type.Null()]),
  kind: Type.Union([Type.Literal('image'), Type.Literal('pdf')]),
  mimeType: Type.String(),
});
export type ReportEvidenceFile = Static<typeof ReportEvidenceFile>;

export const ReportDetailResponse = Type.Object({
  id: Type.String({ format: 'uuid' }),
  title: Type.String(),
  description: Type.String(),
  scamTypeCode: Type.String(),
  scamTypeLabelEn: Type.String(),
  scamTypeLabelTh: Type.String(),
  verifiedAt: Type.String({ format: 'date-time' }),
  reportCount: Type.Integer({ minimum: 1 }),
  targetIdentifier: Type.Union([Type.String(), Type.Null()]),
  targetIdentifierKind: Type.Union([
    Type.Literal('phone'),
    Type.Literal('url'),
    Type.Literal('other'),
    Type.Null(),
  ]),
  evidenceFiles: Type.Array(ReportEvidenceFile),
});
export type ReportDetailResponse = Static<typeof ReportDetailResponse>;
