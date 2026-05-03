import { getMessaging } from 'firebase-admin/messaging';
import { getFirebaseAdmin } from './admin';
import { getPrisma } from '../db/client';

export async function sendFcmToUser(
  userId: string,
  notification: { title: string; body: string },
  data?: Record<string, string>,
): Promise<void> {
  try {
    const prisma = getPrisma();
    const devices = await prisma.fcmDevice.findMany({
      where: { userId },
      select: { fcmToken: true },
    });
    if (devices.length === 0) return;

    const tokens = devices.map((d) => d.fcmToken);
    await getMessaging(getFirebaseAdmin()).sendEachForMulticast({
      tokens,
      notification,
      data,
    });
  } catch (err) {
    // Non-fatal: FCM failure must not roll back the moderation action.
    console.error('[fcm] sendFcmToUser failed:', err);
  }
}
