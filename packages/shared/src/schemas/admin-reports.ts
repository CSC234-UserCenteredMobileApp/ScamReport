import { Type, type Static } from '@sinclair/typebox';

export const AiConfidence = Type.Union([
  Type.Literal('high'),
  Type.Literal('medium'),
  Type.Literal('low'),
  Type.Literal('unknown'),
]);
export type AiConfidence = Static<typeof AiConfidence>;

export const ModerationRecord = Type.Object({
  adminId: Type.Union([Type.String({ format: 'uuid' }), Type.Null()]),
  action: Type.Union([
    Type.Literal('approve'),
    Type.Literal('reject'),
    Type.Literal('flag'),
    Type.Literal('unflag'),
  ]),
  remark: Type.String(),
  createdAt: Type.String({ format: 'date-time' }),
});
export type ModerationRecord = Static<typeof ModerationRecord>;

export const AdminEvidenceFile = Type.Object({
  id: Type.String({ format: 'uuid' }),
  storagePath: Type.String(),
  kind: Type.Union([Type.Literal('image'), Type.Literal('pdf')]),
  mimeType: Type.String(),
  sizeBytes: Type.Number(),
});
export type AdminEvidenceFile = Static<typeof AdminEvidenceFile>;

export const AdminQueueItem = Type.Object({
  id: Type.String({ format: 'uuid' }),
  title: Type.String(),
  scamTypeCode: Type.String(),
  scamTypeLabelEn: Type.String(),
  scamTypeLabelTh: Type.String(),
  submittedAt: Type.String({ format: 'date-time' }),
  status: Type.Union([Type.Literal('pending'), Type.Literal('flagged')]),
  priorityFlag: Type.Boolean(),
  evidenceCount: Type.Integer({ minimum: 0 }),
  lastRemarkByAdmin: Type.Union([Type.String(), Type.Null()]),
});
export type AdminQueueItem = Static<typeof AdminQueueItem>;

export const AdminQueueResponse = Type.Object({
  items: Type.Array(AdminQueueItem),
  pendingCount: Type.Integer({ minimum: 0 }),
  flaggedCount: Type.Integer({ minimum: 0 }),
});
export type AdminQueueResponse = Static<typeof AdminQueueResponse>;

export const AdminReportDetail = Type.Object({
  id: Type.String({ format: 'uuid' }),
  title: Type.String(),
  description: Type.String(),
  scamTypeCode: Type.String(),
  scamTypeLabelEn: Type.String(),
  scamTypeLabelTh: Type.String(),
  submittedAt: Type.String({ format: 'date-time' }),
  status: Type.Union([
    Type.Literal('pending'),
    Type.Literal('flagged'),
    Type.Literal('verified'),
    Type.Literal('rejected'),
  ]),
  priorityFlag: Type.Boolean(),
  targetIdentifier: Type.Union([Type.String(), Type.Null()]),
  targetIdentifierKind: Type.Union([
    Type.Literal('phone'),
    Type.Literal('url'),
    Type.Literal('other'),
    Type.Null(),
  ]),
  evidenceFiles: Type.Array(AdminEvidenceFile),
  duplicateCount: Type.Integer({ minimum: 0 }),
  aiScore: Type.Union([Type.Integer({ minimum: 0, maximum: 100 }), Type.Null()]),
  aiConfidence: Type.Union([AiConfidence, Type.Null()]),
  auditTrail: Type.Array(ModerationRecord),
});
export type AdminReportDetail = Static<typeof AdminReportDetail>;

export const AdminReportDetailResponse = Type.Object({
  report: AdminReportDetail,
});
export type AdminReportDetailResponse = Static<typeof AdminReportDetailResponse>;

export const ApproveRejectFlagRequest = Type.Object({
  remark: Type.String({ minLength: 1 }),
});
export type ApproveRejectFlagRequest = Static<typeof ApproveRejectFlagRequest>;

export const AdminActionResponse = Type.Object({
  id: Type.String({ format: 'uuid' }),
  status: Type.String(),
  updatedAt: Type.String({ format: 'date-time' }),
});
export type AdminActionResponse = Static<typeof AdminActionResponse>;
