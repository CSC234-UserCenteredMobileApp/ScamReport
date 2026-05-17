import { Type, type Static } from '@sinclair/typebox';
import { ScammerProfileSummary } from './scammers';

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
  signedUrl: Type.Union([Type.String(), Type.Null()]),
  kind: Type.Union([Type.Literal('image'), Type.Literal('pdf')]),
  mimeType: Type.String(),
  sizeBytes: Type.Number(),
});
export type AdminEvidenceFile = Static<typeof AdminEvidenceFile>;

// Reporter identity is intentionally absent from every admin-facing payload
// (PRD v1.2 FR-7.4 + FR-7.8). The reporter linkage is retained server-side in
// `reports.reporter_id` for legal traceability and FCM fan-out only.
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
  aiScore: Type.Union([Type.Integer({ minimum: 0, maximum: 100 }), Type.Null()]),
  aiConfidence: Type.Union([AiConfidence, Type.Null()]),
});
export type AdminQueueItem = Static<typeof AdminQueueItem>;

export const AdminQueueResponse = Type.Object({
  items: Type.Array(AdminQueueItem),
  pendingCount: Type.Integer({ minimum: 0 }),
  flaggedCount: Type.Integer({ minimum: 0 }),
  total: Type.Integer({ minimum: 0 }),
  page: Type.Integer({ minimum: 1 }),
  pageSize: Type.Integer({ minimum: 1 }),
});
export type AdminQueueResponse = Static<typeof AdminQueueResponse>;

export const AdminSiblingCase = Type.Object({
  id: Type.String({ format: 'uuid' }),
  title: Type.String(),
  status: Type.String(),
  scamTypeCode: Type.String(),
  verifiedAt: Type.Union([Type.String({ format: 'date-time' }), Type.Null()]),
});
export type AdminSiblingCase = Static<typeof AdminSiblingCase>;

// matchKind discriminates how the related case was tied to the current
// one. Ordered by accuracy:
//   - `same_scammer`    — both reports FK to the same Scammer row.
//   - `same_person`     — both Scammers FK to the same Person row.
//   - `same_identifier` — same normalised target identifier value.
// Lower-priority sources are dropped when a higher one already covered
// the same case (dedupe by id in service-layer merge).
export const AdminRelatedCaseMatchKind = Type.Union([
  Type.Literal('same_scammer'),
  Type.Literal('same_person'),
  Type.Literal('same_identifier'),
]);
export type AdminRelatedCaseMatchKind = Static<typeof AdminRelatedCaseMatchKind>;

export const AdminRelatedCase = Type.Object({
  id: Type.String({ format: 'uuid' }),
  title: Type.String(),
  status: Type.String(),
  scamTypeCode: Type.String(),
  verifiedAt: Type.Union([Type.String({ format: 'date-time' }), Type.Null()]),
  matchKind: AdminRelatedCaseMatchKind,
});
export type AdminRelatedCase = Static<typeof AdminRelatedCase>;

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
  // Snapshot of `suspectedScammerName` at submit time. Null when the
  // reporter didn't surface a name (or the report pre-dates the field).
  suspectedNameAtSubmit: Type.Union([Type.String(), Type.Null()]),
  auditTrail: Type.Array(ModerationRecord),
  // Linked scammer profile (when this case has been associated with one) +
  // sibling cases attributed to the same scammer.
  scammer: Type.Union([ScammerProfileSummary, Type.Null()]),
  siblingCases: Type.Array(AdminSiblingCase),
  // High-accuracy related cases from three sources (same_scammer,
  // same_person, same_identifier). Deduped server-side. Capped at 20.
  relatedCases: Type.Array(AdminRelatedCase),
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

export const AdminEvidenceUrlResponse = Type.Object({
  url: Type.String({ format: 'uri' }),
  expiresAt: Type.String({ format: 'date-time' }),
});
export type AdminEvidenceUrlResponse = Static<typeof AdminEvidenceUrlResponse>;

export const AdminReportSearchItem = Type.Object({
  id: Type.String({ format: 'uuid' }),
  title: Type.String(),
  status: Type.String(),
  scamTypeCode: Type.String(),
  scamTypeLabelEn: Type.String(),
  scamTypeLabelTh: Type.String(),
  targetIdentifier: Type.Union([Type.String(), Type.Null()]),
  submittedAt: Type.String({ format: 'date-time' }),
  aiScore: Type.Union([Type.Integer({ minimum: 0, maximum: 100 }), Type.Null()]),
});
export type AdminReportSearchItem = Static<typeof AdminReportSearchItem>;

export const AdminReportSearchResponse = Type.Object({
  items: Type.Array(AdminReportSearchItem),
  total: Type.Integer({ minimum: 0 }),
});
export type AdminReportSearchResponse = Static<typeof AdminReportSearchResponse>;
