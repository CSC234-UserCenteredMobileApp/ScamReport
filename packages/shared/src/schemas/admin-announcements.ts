import { Type, type Static } from '@sinclair/typebox';
import { AnnouncementCategory } from './announcements';

export const AnnouncementAttachmentSchema = Type.Object({
  id:          Type.String({ format: 'uuid' }),
  storagePath: Type.String(),
  signedUrl:   Type.Union([Type.String(), Type.Null()]),
  kind:        Type.Union([Type.Literal('image'), Type.Literal('pdf')]),
  mimeType:    Type.String(),
  sizeBytes:   Type.Number(),
  sortOrder:   Type.Number(),
});
export type AnnouncementAttachment = Static<typeof AnnouncementAttachmentSchema>;

const AnnouncementStatus = Type.Union([
  Type.Literal('draft'),
  Type.Literal('published'),
  Type.Literal('unpublished'),
]);
type AnnouncementStatus = Static<typeof AnnouncementStatus>;

// slug is server-derived from title; clients do not send it.
export const CreateAnnouncementRequest = Type.Object({
  title: Type.String({ minLength: 1, maxLength: 200 }),
  body: Type.String({ minLength: 1, maxLength: 5000 }),
  category: AnnouncementCategory,
});
export type CreateAnnouncementRequest = Static<typeof CreateAnnouncementRequest>;

export const UpdateAnnouncementRequest = Type.Object({
  title: Type.Optional(Type.String({ minLength: 1, maxLength: 200 })),
  body: Type.Optional(Type.String({ minLength: 1, maxLength: 5000 })),
  category: Type.Optional(AnnouncementCategory),
}, { minProperties: 1 });
export type UpdateAnnouncementRequest = Static<typeof UpdateAnnouncementRequest>;

export const AdminAnnouncementListItem = Type.Object({
  id: Type.String({ format: 'uuid' }),
  slug: Type.String(),
  title: Type.String(),
  category: AnnouncementCategory,
  status: AnnouncementStatus,
  createdAt: Type.String({ format: 'date-time' }),
  publishedAt: Type.Union([Type.String({ format: 'date-time' }), Type.Null()]),
});
export type AdminAnnouncementListItem = Static<typeof AdminAnnouncementListItem>;

export const AdminAnnouncementListResponse = Type.Object({
  items: Type.Array(AdminAnnouncementListItem),
});
export type AdminAnnouncementListResponse = Static<typeof AdminAnnouncementListResponse>;

export const AdminAnnouncementDetail = Type.Object({
  id: Type.String({ format: 'uuid' }),
  slug: Type.String(),
  title: Type.String(),
  body: Type.String(),
  category: AnnouncementCategory,
  status: AnnouncementStatus,
  createdAt: Type.String({ format: 'date-time' }),
  updatedAt: Type.String({ format: 'date-time' }),
  publishedAt: Type.Union([Type.String({ format: 'date-time' }), Type.Null()]),
  pushedToFcmAt: Type.Union([Type.String({ format: 'date-time' }), Type.Null()]),
  authorId: Type.Union([Type.String({ format: 'uuid' }), Type.Null()]),
  attachments: Type.Array(AnnouncementAttachmentSchema),
});
export type AdminAnnouncementDetail = Static<typeof AdminAnnouncementDetail>;

export const AdminAnnouncementDetailResponse = Type.Object({
  item: AdminAnnouncementDetail,
});
export type AdminAnnouncementDetailResponse = Static<typeof AdminAnnouncementDetailResponse>;

export const PublishAnnouncementRequest = Type.Object({
  pushToFcm: Type.Boolean(),
});
export type PublishAnnouncementRequest = Static<typeof PublishAnnouncementRequest>;

export const AdminAnnouncementActionResponse = Type.Object({
  id: Type.String({ format: 'uuid' }),
  status: Type.String(),
  updatedAt: Type.String({ format: 'date-time' }),
});
export type AdminAnnouncementActionResponse = Static<typeof AdminAnnouncementActionResponse>;

export const AdminAnnouncementAttachmentResponse = Type.Object({
  attachment: AnnouncementAttachmentSchema,
});
export type AdminAnnouncementAttachmentResponse = Static<typeof AdminAnnouncementAttachmentResponse>;
