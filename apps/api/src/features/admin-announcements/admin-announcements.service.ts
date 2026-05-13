import { getPrisma } from '../../core/db/client';
import { resolveInternalUserId } from '../../core/lib/resolve-user';
import { sendFcmBroadcast } from '../../core/firebase/messaging';
import { Prisma } from '../../generated/prisma/client';
import type { AdminAnnouncementListItem, AdminAnnouncementDetail } from '@my-product/shared';
import { uploadFile, deleteFile, getSignedUrl } from '../../core/supabase/storage';
import type { AnnouncementAttachment } from '@my-product/shared';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function generateSlug(title: string): string {
  const base = title
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 60);
  return `${base}-${Date.now().toString(36)}`;
}

const detailSelect = {
  id: true,
  slug: true,
  title: true,
  body: true,
  category: true,
  status: true,
  createdAt: true,
  updatedAt: true,
  publishedAt: true,
  pushedToFcmAt: true,
  authorId: true,
  attachments: {
    orderBy: { sortOrder: 'asc' as const },
    select: {
      id: true,
      storagePath: true,
      kind: true,
      mimeType: true,
      sizeBytes: true,
      sortOrder: true,
    },
  },
} as const;

const ATTACHMENT_SIGNED_URL_TTL_SECONDS = 3600;

async function signAttachmentUrl(storagePath: string): Promise<string | null> {
  try {
    return await getSignedUrl(BUCKET, storagePath, ATTACHMENT_SIGNED_URL_TTL_SECONDS);
  } catch (err) {
    console.error('[admin-announcements] sign attachment failed', {
      storagePath,
      err,
    });
    return null;
  }
}

async function toDetail(row: {
  id: string;
  slug: string;
  title: string;
  body: string;
  category: string;
  status: string;
  createdAt: Date;
  updatedAt: Date;
  publishedAt: Date | null;
  pushedToFcmAt: Date | null;
  authorId: string | null;
  attachments: Array<{
    id: string;
    storagePath: string;
    kind: string;
    mimeType: string;
    sizeBytes: bigint;
    sortOrder: number;
  }>;
}): Promise<AdminAnnouncementDetail> {
  return {
    id: row.id,
    slug: row.slug,
    title: row.title,
    body: row.body,
    category: row.category as AdminAnnouncementDetail['category'],
    status: row.status as AdminAnnouncementDetail['status'],
    createdAt: row.createdAt.toISOString(),
    updatedAt: row.updatedAt.toISOString(),
    publishedAt: row.publishedAt?.toISOString() ?? null,
    pushedToFcmAt: row.pushedToFcmAt?.toISOString() ?? null,
    authorId: row.authorId ?? null,
    attachments: await Promise.all(
      row.attachments.map(async (a) => ({
        id: a.id,
        storagePath: a.storagePath,
        signedUrl: await signAttachmentUrl(a.storagePath),
        kind: a.kind as AnnouncementAttachment['kind'],
        mimeType: a.mimeType,
        sizeBytes: Number(a.sizeBytes),
        sortOrder: a.sortOrder,
      })),
    ),
  };
}

// ---------------------------------------------------------------------------
// List
// ---------------------------------------------------------------------------

export async function listAll(): Promise<AdminAnnouncementListItem[]> {
  const prisma = getPrisma();
  const rows = await prisma.announcement.findMany({
    orderBy: { createdAt: 'desc' },
    select: {
      id: true,
      slug: true,
      title: true,
      category: true,
      status: true,
      createdAt: true,
      publishedAt: true,
    },
  });
  return rows.map((row) => ({
    id: row.id,
    slug: row.slug,
    title: row.title,
    category: row.category as AdminAnnouncementListItem['category'],
    status: row.status as AdminAnnouncementListItem['status'],
    createdAt: row.createdAt.toISOString(),
    publishedAt: row.publishedAt?.toISOString() ?? null,
  }));
}

// ---------------------------------------------------------------------------
// Detail
// ---------------------------------------------------------------------------

export async function getDetail(id: string): Promise<AdminAnnouncementDetail | null> {
  const prisma = getPrisma();
  const row = await prisma.announcement.findUnique({
    where: { id },
    select: detailSelect,
  });
  if (!row) return null;
  return toDetail(row);
}

// ---------------------------------------------------------------------------
// Create
// ---------------------------------------------------------------------------

export async function createAnnouncement(
  firebaseUid: string,
  email: string | null,
  data: { title: string; body: string; category: string },
): Promise<AdminAnnouncementDetail> {
  const prisma = getPrisma();
  const authorId = await resolveInternalUserId(firebaseUid, email);
  let slug = generateSlug(data.title);

  try {
    const row = await prisma.announcement.create({
      data: {
        title: data.title,
        body: data.body,
        category: data.category as never,
        authorId,
        slug,
        status: 'draft',
      },
      select: detailSelect,
    });
    return toDetail(row);
  } catch (err) {
    if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
      // Slug collision — retry once with a random suffix
      slug = `${slug}-${Math.random().toString(36).slice(2, 6)}`;
      const row = await prisma.announcement.create({
        data: {
          title: data.title,
          body: data.body,
          category: data.category as never,
          authorId,
          slug,
          status: 'draft',
        },
        select: detailSelect,
      });
      return toDetail(row);
    }
    throw err;
  }
}

// ---------------------------------------------------------------------------
// Update
// ---------------------------------------------------------------------------

export async function updateAnnouncement(
  id: string,
  data: Partial<{ title: string; body: string; category: string }>,
): Promise<AdminAnnouncementDetail | null | 'locked'> {
  const prisma = getPrisma();
  const existing = await prisma.announcement.findUnique({
    where: { id },
    select: { id: true, status: true },
  });
  if (!existing) return null;
  if (existing.status === 'published') return 'locked';

  const row = await prisma.announcement.update({
    where: { id },
    data: { ...data, updatedAt: new Date() } as never,
    select: detailSelect,
  });
  return toDetail(row);
}

// ---------------------------------------------------------------------------
// Delete
// ---------------------------------------------------------------------------

export async function deleteAnnouncement(
  id: string,
): Promise<'ok' | 'locked' | null> {
  const prisma = getPrisma();
  const existing = await prisma.announcement.findUnique({
    where: { id },
    select: { id: true, status: true },
  });
  if (!existing) return null;
  if (existing.status === 'published') return 'locked';

  await prisma.announcement.delete({ where: { id } });
  return 'ok';
}

// ---------------------------------------------------------------------------
// Publish
// ---------------------------------------------------------------------------

export async function publishAnnouncement(
  id: string,
  pushToFcm: boolean,
): Promise<AdminAnnouncementDetail | null> {
  const prisma = getPrisma();
  try {
    // Re-publish is intentional — resets publishedAt and re-broadcasts if pushToFcm=true.
    const row = await prisma.announcement.update({
      where: { id },
      data: {
        status: 'published',
        publishedAt: new Date(),
        updatedAt: new Date(),
        // pushedToFcmAt records when broadcast was attempted, not confirmed delivery.
        ...(pushToFcm ? { pushedToFcmAt: new Date() } : {}),
      },
      select: detailSelect,
    });
    const result = await toDetail(row);
    if (pushToFcm) {
      await sendFcmBroadcast({
        title: result.title,
        body: result.body.slice(0, 120),
      });
    }
    return result;
  } catch (err) {
    if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2025') {
      return null;
    }
    throw err;
  }
}

// ---------------------------------------------------------------------------
// Unpublish
// ---------------------------------------------------------------------------

export async function unpublishAnnouncement(
  id: string,
): Promise<AdminAnnouncementDetail | null | 'not_published'> {
  const prisma = getPrisma();
  const existing = await prisma.announcement.findUnique({
    where: { id },
    select: { id: true, status: true },
  });
  if (!existing) return null;
  if (existing.status !== 'published') return 'not_published';

  const row = await prisma.announcement.update({
    where: { id },
    data: { status: 'unpublished', updatedAt: new Date() },
    select: detailSelect,
  });
  return toDetail(row);
}

// ---------------------------------------------------------------------------
// Attachments
// ---------------------------------------------------------------------------

const ALLOWED_MIME = new Set([
  'image/jpeg', 'image/png', 'image/webp', 'image/gif', 'application/pdf',
]);
const MAX_SIZE_BYTES = 10 * 1024 * 1024; // 10 MB
const BUCKET = 'announcement-attachments';

export async function uploadAttachment(
  announcementId: string,
  file: File,
): Promise<AnnouncementAttachment | null | 'invalid_mime' | 'too_large' | 'limit_reached'> {
  if (!ALLOWED_MIME.has(file.type)) return 'invalid_mime';
  if (file.size > MAX_SIZE_BYTES) return 'too_large';

  const prisma = getPrisma();
  const announcement = await prisma.announcement.findUnique({
    where: { id: announcementId },
    select: { id: true, _count: { select: { attachments: true } } },
  });
  if (!announcement) return null;
  if (announcement._count.attachments >= 10) return 'limit_reached';

  const ext = file.name.split('.').pop() ?? 'bin';
  const storagePath = `${announcementId}/${crypto.randomUUID()}.${ext}`;
  const kind = file.type.startsWith('image/') ? 'image' : 'pdf';

  const bytes = await file.arrayBuffer();
  await uploadFile(BUCKET, storagePath, bytes, { contentType: file.type, upsert: false });

  const row = await prisma.announcementAttachment.create({
    data: {
      announcementId,
      storagePath,
      kind,
      mimeType: file.type,
      sizeBytes: BigInt(file.size),
      sortOrder: announcement._count.attachments,
    },
  });

  return {
    id: row.id,
    storagePath: row.storagePath,
    signedUrl: await signAttachmentUrl(row.storagePath),
    kind: row.kind as AnnouncementAttachment['kind'],
    mimeType: row.mimeType,
    sizeBytes: Number(row.sizeBytes),
    sortOrder: row.sortOrder,
  };
}

export async function deleteAttachment(
  announcementId: string,
  attachmentId: string,
): Promise<'ok' | null> {
  const prisma = getPrisma();
  const attachment = await prisma.announcementAttachment.findFirst({
    where: { id: attachmentId, announcementId },
    select: { id: true, storagePath: true },
  });
  if (!attachment) return null;

  await deleteFile(BUCKET, [attachment.storagePath]);
  await prisma.announcementAttachment.delete({ where: { id: attachmentId } });
  return 'ok';
}
