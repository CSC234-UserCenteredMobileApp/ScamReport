import { getPrisma } from '../../core/db/client';
import { resolveInternalUserId } from '../../core/lib/resolve-user';
import { sendFcmBroadcast } from '../../core/firebase/messaging';
import { Prisma } from '../../generated/prisma/client';
import type { AdminAnnouncementListItem, AdminAnnouncementDetail } from '@my-product/shared';

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
} as const;

function toDetail(row: {
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
}): AdminAnnouncementDetail {
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
    data: { ...data } as never,
    select: detailSelect,
  });
  return toDetail(row);
}

// ---------------------------------------------------------------------------
// Delete
// ---------------------------------------------------------------------------

export async function deleteAnnouncement(
  id: string,
): Promise<'ok' | 'not_found' | 'locked'> {
  const prisma = getPrisma();
  const existing = await prisma.announcement.findUnique({
    where: { id },
    select: { id: true, status: true },
  });
  if (!existing) return 'not_found';
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
    const row = await prisma.announcement.update({
      where: { id },
      data: {
        status: 'published',
        publishedAt: new Date(),
        updatedAt: new Date(),
        ...(pushToFcm ? { pushedToFcmAt: new Date() } : {}),
      },
      select: detailSelect,
    });
    const result = toDetail(row);
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
