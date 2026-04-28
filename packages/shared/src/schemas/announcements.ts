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
});
export type AnnouncementCard = Static<typeof AnnouncementCard>;

export const AnnouncementListResponse = Type.Object({
  items: Type.Array(AnnouncementCard),
});
export type AnnouncementListResponse = Static<typeof AnnouncementListResponse>;
