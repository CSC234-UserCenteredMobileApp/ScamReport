import { Type, type Static } from '@sinclair/typebox';

export const AuthUser = Type.Object({
  id: Type.String({ format: 'uuid' }),
  firebaseUid: Type.String(),
  email: Type.Union([Type.String(), Type.Null()]),
  displayName: Type.Union([Type.String(), Type.Null()]),
  role: Type.Union([Type.Literal('user'), Type.Literal('admin')]),
  preferredLanguage: Type.Union([Type.Literal('th'), Type.Literal('en')]),
});
export type AuthUser = Static<typeof AuthUser>;

// POST /auth/sync — body is empty. The Authorization: Bearer <Firebase ID
// token> header is the only input; the backend verifies it, upserts the
// users row keyed on firebase_uid, and returns the synced user.
export const AuthSyncResponse = Type.Object({
  user: AuthUser,
});
export type AuthSyncResponse = Static<typeof AuthSyncResponse>;

export const DeleteAccountResponse = Type.Object({
  requestedAt: Type.String({ format: 'date-time' }),
  purgeDueAt: Type.String({ format: 'date-time' }),
});
export type DeleteAccountResponse = Static<typeof DeleteAccountResponse>;

export const CancelDeletionResponse = Type.Object({
  message: Type.String(),
});
export type CancelDeletionResponse = Static<typeof CancelDeletionResponse>;
