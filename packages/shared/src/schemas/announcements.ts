import { Type, type Static } from '@sinclair/typebox';

export const AnnouncementCategory = Type.Union([
  Type.Literal('fraud_alert'),
  Type.Literal('tips'),
  Type.Literal('platform_update'),
]);
export type AnnouncementCategory = Static<typeof AnnouncementCategory>;

export const AnnouncementCard = Type.Object({
  id: Type.String({ format: 'uuid' }),
  title: Type.String(),
  category: AnnouncementCategory,
  publishedAt: Type.String({ format: 'date-time' }),
  province: Type.Optional(Type.String()),
});
export type AnnouncementCard = Static<typeof AnnouncementCard>;

export const AnnouncementListResponse = Type.Object({
  items: Type.Array(AnnouncementCard),
});
export type AnnouncementListResponse = Static<typeof AnnouncementListResponse>;

export const AnnouncementListQuery = Type.Object({
  limit: Type.Optional(Type.Integer({ minimum: 1, maximum: 50 })),
  province: Type.Optional(Type.String({ minLength: 1 })),
});
export type AnnouncementListQuery = Static<typeof AnnouncementListQuery>;
