import { getPrisma } from '../../core/db/client';

// Counts unique users with at least one registered FCM device. Drives the
// "Send push to ~N users?" confirmation copy in the admin announcement
// editor. Distinct on userId so a single user with multiple devices counts
// once.
export async function countSubscribers(): Promise<number> {
  const prisma = getPrisma();
  const rows = await prisma.fcmDevice.findMany({
    distinct: ['userId'],
    select: { userId: true },
  });
  return rows.length;
}
