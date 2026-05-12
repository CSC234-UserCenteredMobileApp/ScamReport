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
//
// Evidence flow: POST /reports/evidence uploads bytes to Supabase Storage and
// returns metadata only (no DB row — `evidence_files.report_id` is NOT NULL,
// so the row is created during POST /reports inside the same transaction).
// The client passes the returned EvidenceMetadata back inside the
// CreateReportRequest.evidenceFiles array.

export const TargetIdentifierKindLiteral = Type.Union([
  Type.Literal('phone'),
  Type.Literal('url'),
  Type.Literal('other'),
]);

export const EvidenceKindLiteral = Type.Union([
  Type.Literal('image'),
  Type.Literal('pdf'),
]);

export const EvidenceMetadata = Type.Object({
  storagePath: Type.String({ minLength: 1, maxLength: 512 }),
  kind: EvidenceKindLiteral,
  mimeType: Type.String({ minLength: 1, maxLength: 128 }),
  sizeBytes: Type.Integer({ minimum: 1 }),
});
export type EvidenceMetadata = Static<typeof EvidenceMetadata>;

export const EvidenceUploadResponse = EvidenceMetadata;
export type EvidenceUploadResponse = Static<typeof EvidenceUploadResponse>;

export const CreateReportRequest = Type.Object({
  title: Type.String({ minLength: 3, maxLength: 200 }),
  description: Type.String({ minLength: 10, maxLength: 2000 }),
  scamTypeCode: Type.String({ minLength: 1 }),
  targetIdentifier: Type.Optional(Type.Union([Type.String(), Type.Null()])),
  targetIdentifierKind: Type.Optional(Type.Union([TargetIdentifierKindLiteral, Type.Null()])),
  evidenceFiles: Type.Array(EvidenceMetadata, { maxItems: 5, default: [] }),
  clientSubmissionId: Type.Optional(Type.String({ minLength: 1, maxLength: 128 })),
  // When provided, the server links ai_conversations.linked_report_id → new report.
  sourceConversationId: Type.Optional(Type.String({ format: 'uuid' })),
  // Chat-attachment IDs (ai_message_attachments.id) the user curated as evidence
  // in a restored draft. Server copies each from chat-attachments → evidence
  // bucket and inserts an evidence_files row in the same transaction. iter-5.
  promotedEvidenceAttachmentIds: Type.Optional(
    Type.Array(Type.String({ format: 'uuid' }), { maxItems: 5 }),
  ),
});
export type CreateReportRequest = Static<typeof CreateReportRequest>;

export const CreateReportResponse = Type.Object({
  id: Type.String({ format: 'uuid' }),
  status: Type.Literal('pending'),
  createdAt: Type.String({ format: 'date-time' }),
});
export type CreateReportResponse = Static<typeof CreateReportResponse>;

// Reporter-facing status (flagged is remapped to pending server-side per FR-6.1)
export const MyReportStatusLiteral = Type.Union([
  Type.Literal('pending'),
  Type.Literal('verified'),
  Type.Literal('rejected'),
  Type.Literal('withdrawn'),
]);

export const MyReportItem = Type.Object({
  id: Type.String({ format: 'uuid' }),
  title: Type.String(),
  scamTypeCode: Type.String(),
  scamTypeLabelEn: Type.String(),
  scamTypeLabelTh: Type.String(),
  status: MyReportStatusLiteral,
  createdAt: Type.String({ format: 'date-time' }),
  updatedAt: Type.String({ format: 'date-time' }),
  rejectionRemark: Type.Union([Type.String(), Type.Null()]),
});
export type MyReportItem = Static<typeof MyReportItem>;

export const MyReportsResponse = Type.Object({
  items: Type.Array(MyReportItem),
});
export type MyReportsResponse = Static<typeof MyReportsResponse>;

export const UpdateReportRequest = Type.Object({
  title: Type.String({ minLength: 3, maxLength: 200 }),
  description: Type.String({ minLength: 10, maxLength: 2000 }),
  scamTypeCode: Type.String({ minLength: 1 }),
  targetIdentifier: Type.Optional(Type.Union([Type.String(), Type.Null()])),
  targetIdentifierKind: Type.Optional(Type.Union([TargetIdentifierKindLiteral, Type.Null()])),
  evidenceFiles: Type.Array(EvidenceMetadata, { maxItems: 5, default: [] }),
});
export type UpdateReportRequest = Static<typeof UpdateReportRequest>;

export const UpdateReportResponse = Type.Object({
  id: Type.String({ format: 'uuid' }),
  status: MyReportStatusLiteral,
  updatedAt: Type.String({ format: 'date-time' }),
});
export type UpdateReportResponse = Static<typeof UpdateReportResponse>;

export const WithdrawReportResponse = Type.Object({
  id: Type.String({ format: 'uuid' }),
  status: Type.Literal('withdrawn'),
});
export type WithdrawReportResponse = Static<typeof WithdrawReportResponse>;

// Evidence file returned for edit pre-fill — includes storagePath + sizeBytes
// so the client can echo them back unchanged in the PATCH evidenceFiles array.
export const EditReportEvidenceFile = Type.Object({
  id: Type.String({ format: 'uuid' }),
  storagePath: Type.String(),
  signedUrl: Type.Union([Type.String(), Type.Null()]),
  kind: EvidenceKindLiteral,
  mimeType: Type.String(),
  sizeBytes: Type.Integer({ minimum: 1 }),
});
export type EditReportEvidenceFile = Static<typeof EditReportEvidenceFile>;

export const EditReportDetailResponse = Type.Object({
  id: Type.String({ format: 'uuid' }),
  title: Type.String(),
  description: Type.String(),
  scamTypeCode: Type.String(),
  scamTypeLabelEn: Type.String(),
  scamTypeLabelTh: Type.String(),
  status: MyReportStatusLiteral,
  targetIdentifier: Type.Union([Type.String(), Type.Null()]),
  targetIdentifierKind: Type.Union([TargetIdentifierKindLiteral, Type.Null()]),
  evidenceFiles: Type.Array(EditReportEvidenceFile),
});
export type EditReportDetailResponse = Static<typeof EditReportDetailResponse>;
