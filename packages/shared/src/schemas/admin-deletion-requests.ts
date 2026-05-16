import { Type, type Static } from '@sinclair/typebox';

export const DeletionRequestStatus = Type.Union([
  Type.Literal('pending'),
  Type.Literal('approved'),
  Type.Literal('rejected'),
]);
export type DeletionRequestStatus = Static<typeof DeletionRequestStatus>;

export const AdminDeletionRequestItem = Type.Object({
  id:              Type.String({ format: 'uuid' }),
  userHandle:      Type.String(),
  userEmail:       Type.Union([Type.String(), Type.Null()]),
  requestedAt:     Type.String({ format: 'date-time' }),
  purgeDueAt:      Type.String({ format: 'date-time' }),
  status:          DeletionRequestStatus,
  rejectionReason: Type.Union([Type.String(), Type.Null()]),
  reviewedAt:      Type.Union([Type.String({ format: 'date-time' }), Type.Null()]),
});
export type AdminDeletionRequestItem = Static<typeof AdminDeletionRequestItem>;

export const AdminDeletionRequestListResponse = Type.Object({
  items:        Type.Array(AdminDeletionRequestItem),
  pendingCount: Type.Number(),
});
export type AdminDeletionRequestListResponse = Static<typeof AdminDeletionRequestListResponse>;

export const AdminDeletionRejectRequest = Type.Object({
  reason: Type.String({ minLength: 1, maxLength: 500 }),
});
export type AdminDeletionRejectRequest = Static<typeof AdminDeletionRejectRequest>;

export const AdminDeletionActionResponse = Type.Object({
  id:         Type.String({ format: 'uuid' }),
  status:     DeletionRequestStatus,
  reviewedAt: Type.String({ format: 'date-time' }),
});
export type AdminDeletionActionResponse = Static<typeof AdminDeletionActionResponse>;
