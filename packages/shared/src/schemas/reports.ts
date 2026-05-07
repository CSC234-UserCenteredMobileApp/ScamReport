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

// Submit pipeline (PR-2 will mount the routes; PR-1 lands the schemas).

export const TargetIdentifierKindLiteral = Type.Union([
  Type.Literal('phone'),
  Type.Literal('url'),
  Type.Literal('other'),
]);

export const EvidenceUploadResponse = Type.Object({
  evidenceFileId: Type.String({ format: 'uuid' }),
  storagePath: Type.String({ minLength: 1 }),
});
export type EvidenceUploadResponse = Static<typeof EvidenceUploadResponse>;

export const CreateReportRequest = Type.Object({
  title: Type.String({ minLength: 3, maxLength: 200 }),
  description: Type.String({ minLength: 10, maxLength: 2000 }),
  scamTypeCode: Type.String({ minLength: 1 }),
  targetIdentifier: Type.Optional(Type.Union([Type.String(), Type.Null()])),
  targetIdentifierKind: Type.Optional(Type.Union([TargetIdentifierKindLiteral, Type.Null()])),
  evidenceFileIds: Type.Array(Type.String({ format: 'uuid' }), { maxItems: 5, default: [] }),
  clientSubmissionId: Type.Optional(Type.String({ minLength: 1, maxLength: 128 })),
  // When provided, the server links ai_conversations.linked_report_id → new report.
  sourceConversationId: Type.Optional(Type.String({ format: 'uuid' })),
});
export type CreateReportRequest = Static<typeof CreateReportRequest>;

export const CreateReportResponse = Type.Object({
  id: Type.String({ format: 'uuid' }),
  status: Type.Literal('pending'),
  createdAt: Type.String({ format: 'date-time' }),
});
export type CreateReportResponse = Static<typeof CreateReportResponse>;
