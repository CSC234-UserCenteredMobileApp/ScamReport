// =============================================================================
// notifications.repo — Prisma data layer for in-app notifications + FCM devices
// =============================================================================

import type { NotificationKind } from '@my-product/shared';
import { getPrisma } from '../../core/db/client';

type DevicePlatform = 'ios' | 'android' | 'web';

export interface NotificationRow {
  id: string;
  kind: string;
  title: string;
  body: string;
  reportId: string | null;
  isRead: boolean;
  createdAt: Date;
}

// FcmDevice has `fcmToken` as a unique column. The upsert key is therefore the
// token itself: if a token migrates between users (e.g. signing out + signing
// in as someone else on the same device) the row is reassigned to the new
// userId. Prior implementation would have inserted a duplicate.
export async function upsertFcmDevice(
  userId: string,
  fcmToken: string,
  platform: DevicePlatform | null,
  appVersion: string | null,
): Promise<void> {
  const prisma = getPrisma();
  await prisma.fcmDevice.upsert({
    where: { fcmToken },
    create: {
      userId,
      fcmToken,
      platform: platform ?? undefined,
      appVersion: appVersion ?? undefined,
    },
    update: {
      userId,
      platform: platform ?? undefined,
      appVersion: appVersion ?? undefined,
      lastSeenAt: new Date(),
    },
  });
}

// Only deletes when the token *currently* belongs to the caller. Prevents a
// stale token belonging to a different user from being kicked off the device
// list by a sign-out fired on this one.
export async function deleteFcmDeviceForUser(
  userId: string,
  fcmToken: string,
): Promise<number> {
  const prisma = getPrisma();
  const { count } = await prisma.fcmDevice.deleteMany({
    where: { userId, fcmToken },
  });
  return count;
}

export async function listNotificationsForUser(
  userId: string,
  limit: number,
): Promise<NotificationRow[]> {
  const prisma = getPrisma();
  return prisma.notification.findMany({
    where: { userId },
    orderBy: { createdAt: 'desc' },
    take: limit,
    select: {
      id: true,
      kind: true,
      title: true,
      body: true,
      reportId: true,
      isRead: true,
      createdAt: true,
    },
  });
}

export async function countUnreadForUser(userId: string): Promise<number> {
  const prisma = getPrisma();
  return prisma.notification.count({ where: { userId, isRead: false } });
}

export async function markNotificationsRead(
  userId: string,
  ids: string[],
): Promise<number> {
  const prisma = getPrisma();
  const { count } = await prisma.notification.updateMany({
    where: { userId, id: { in: ids }, isRead: false },
    data: { isRead: true },
  });
  return count;
}

export async function createNotification(
  userId: string,
  kind: NotificationKind,
  title: string,
  body: string,
  reportId: string | null,
): Promise<{ id: string }> {
  const prisma = getPrisma();
  const row = await prisma.notification.create({
    data: { userId, kind, title, body, reportId: reportId ?? undefined },
    select: { id: true },
  });
  return row;
}
