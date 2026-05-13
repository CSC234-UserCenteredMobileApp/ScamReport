// =============================================================================
// notifications.service — orchestration for the persistent inbox + FCM devices
// =============================================================================

import type {
  AppNotification,
  FcmPlatform,
  NotificationKind,
  NotificationListResponse,
} from '@my-product/shared';
import { sendFcmToUser } from '../../core/firebase/messaging';
import {
  countUnreadForUser,
  createNotification,
  deleteFcmDeviceForUser,
  listNotificationsForUser,
  markNotificationsRead,
  upsertFcmDevice,
} from './notifications.repo';

const INBOX_PAGE_SIZE = 50;

export async function registerDevice(
  userId: string,
  fcmToken: string,
  platform: FcmPlatform,
  appVersion: string | undefined,
): Promise<void> {
  await upsertFcmDevice(userId, fcmToken, platform, appVersion ?? null);
}

export async function unregisterDevice(
  userId: string,
  fcmToken: string,
): Promise<number> {
  return deleteFcmDeviceForUser(userId, fcmToken);
}

export async function listInbox(userId: string): Promise<NotificationListResponse> {
  const [rows, unreadCount] = await Promise.all([
    listNotificationsForUser(userId, INBOX_PAGE_SIZE),
    countUnreadForUser(userId),
  ]);
  const items: AppNotification[] = rows.map((r) => ({
    id: r.id,
    kind: r.kind as NotificationKind,
    title: r.title,
    body: r.body,
    reportId: r.reportId,
    isRead: r.isRead,
    createdAt: r.createdAt.toISOString(),
  }));
  return { items, unreadCount };
}

export async function markRead(
  userId: string,
  ids: string[],
): Promise<{ updated: number; unreadCount: number }> {
  const updated = await markNotificationsRead(userId, ids);
  const unreadCount = await countUnreadForUser(userId);
  return { updated, unreadCount };
}

// Used by admin-reports.service on approve/reject. Writes the persistent row
// first (source of truth for the inbox), then fires FCM with deep-link data.
// FCM is best-effort — failure is logged inside `sendFcmToUser` and never
// rolls back the inbox row or the moderation transaction upstream.
export async function notifyReporter(
  userId: string,
  kind: NotificationKind,
  title: string,
  body: string,
  reportId: string,
): Promise<void> {
  const { id } = await createNotification(userId, kind, title, body, reportId);
  await sendFcmToUser(
    userId,
    { title, body },
    {
      kind,
      reportId,
      notificationId: id,
      deeplink: `scamreport://report/${reportId}`,
    },
  );
}
