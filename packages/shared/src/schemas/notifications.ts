import { Type, type Static } from '@sinclair/typebox';

export const FcmPlatform = Type.Union([
  Type.Literal('ios'),
  Type.Literal('android'),
  Type.Literal('web'),
]);
export type FcmPlatform = Static<typeof FcmPlatform>;

export const RegisterFcmTokenRequest = Type.Object({
  fcmToken: Type.String({ minLength: 1 }),
  platform: FcmPlatform,
  appVersion: Type.Optional(Type.String()),
});
export type RegisterFcmTokenRequest = Static<typeof RegisterFcmTokenRequest>;

export const RegisterFcmTokenResponse = Type.Object({
  registered: Type.Boolean(),
});
export type RegisterFcmTokenResponse = Static<typeof RegisterFcmTokenResponse>;

export const NotificationKind = Type.Union([
  Type.Literal('report_verified'),
  Type.Literal('report_rejected'),
  Type.Literal('report_flagged'),
]);
export type NotificationKind = Static<typeof NotificationKind>;

export const AppNotification = Type.Object({
  id: Type.String(),
  kind: NotificationKind,
  title: Type.String(),
  body: Type.String(),
  reportId: Type.Union([Type.String({ format: 'uuid' }), Type.Null()]),
  isRead: Type.Boolean(),
  createdAt: Type.String({ format: 'date-time' }),
});
export type AppNotification = Static<typeof AppNotification>;

export const NotificationListResponse = Type.Object({
  items: Type.Array(AppNotification),
  unreadCount: Type.Integer({ minimum: 0 }),
});
export type NotificationListResponse = Static<typeof NotificationListResponse>;

export const MarkNotificationReadRequest = Type.Object({
  ids: Type.Array(Type.String(), { minItems: 1 }),
});
export type MarkNotificationReadRequest = Static<
  typeof MarkNotificationReadRequest
>;

export const MarkNotificationReadResponse = Type.Object({
  updated: Type.Integer({ minimum: 0 }),
  unreadCount: Type.Integer({ minimum: 0 }),
});
export type MarkNotificationReadResponse = Static<
  typeof MarkNotificationReadResponse
>;
