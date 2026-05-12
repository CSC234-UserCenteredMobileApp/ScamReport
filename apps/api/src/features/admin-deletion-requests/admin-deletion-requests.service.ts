import { getAuth } from 'firebase-admin/auth';
import { getPrisma } from '../../core/db/client';
import { getFirebaseAdmin } from '../../core/firebase/admin';
import { sendFcmToUser } from '../../core/firebase/messaging';
import type {
  AdminDeletionRequestListResponse,
  AdminDeletionActionResponse,
} from '@my-product/shared';

function maskHandle(_email: string | null, uid: string): string {
  return `User_${uid.slice(0, 8)}`;
}

export async function listRequests(
  statusFilter?: string,
): Promise<AdminDeletionRequestListResponse> {
  const prisma = getPrisma();
  const where = statusFilter ? { status: statusFilter as never } : {};
  const [items, pendingCount] = await Promise.all([
    prisma.accountDeletionRequest.findMany({
      where,
      orderBy: { requestedAt: 'desc' },
      include: { user: { select: { email: true, firebaseUid: true } } },
    }),
    prisma.accountDeletionRequest.count({ where: { status: 'pending' } }),
  ]);

  return {
    items: items.map((r) => ({
      id: r.id,
      userHandle: maskHandle(r.user.email, r.user.firebaseUid),
      requestedAt: r.requestedAt.toISOString(),
      purgeDueAt: r.purgeDueAt.toISOString(),
      status: r.status as AdminDeletionRequestListResponse['items'][number]['status'],
      rejectionReason: r.rejectionReason ?? null,
      reviewedAt: r.reviewedAt?.toISOString() ?? null,
    })),
    pendingCount,
  };
}

export async function approveRequest(
  requestId: string,
  adminFirebaseUid: string,
): Promise<AdminDeletionActionResponse | null | 'already_reviewed'> {
  const prisma = getPrisma();
  const req = await prisma.accountDeletionRequest.findUnique({
    where: { id: requestId },
    include: { user: { select: { id: true, firebaseUid: true } } },
  });
  if (!req) return null;
  if (req.status !== 'pending') return 'already_reviewed';

  const reviewedAt = new Date();

  // 1. Mark as approved in DB first (so state is consistent even if Firebase fails)
  await prisma.accountDeletionRequest.update({
    where: { id: requestId },
    data: {
      status: 'approved',
      reviewedAt,
      reviewedByAdminId: adminFirebaseUid,
      purgedAt: reviewedAt,
    },
  });

  // 2. Delete Firebase account (revokes all tokens)
  try {
    await getAuth(getFirebaseAdmin()).deleteUser(req.user.firebaseUid);
  } catch (err: unknown) {
    // Ignore if user already deleted in Firebase
    if ((err as { code?: string }).code !== 'auth/user-not-found') throw err;
  }

  // 3. Cascade-delete Postgres user (FcmDevice, AiConversation, etc. cascade automatically)
  try {
    await prisma.user.delete({ where: { id: req.user.id } });
  } catch (err: unknown) {
    // Ignore P2025 (user already gone)
    if ((err as { code?: string }).code !== 'P2025') throw err;
  }

  return {
    id: requestId,
    status: 'approved',
    reviewedAt: reviewedAt.toISOString(),
  };
}

export async function rejectRequest(
  requestId: string,
  adminFirebaseUid: string,
  reason: string,
): Promise<AdminDeletionActionResponse | null | 'already_reviewed'> {
  const prisma = getPrisma();
  const req = await prisma.accountDeletionRequest.findUnique({
    where: { id: requestId },
    include: { user: { select: { id: true } } },
  });
  if (!req) return null;
  if (req.status !== 'pending') return 'already_reviewed';

  const reviewedAt = new Date();
  await prisma.accountDeletionRequest.update({
    where: { id: requestId },
    data: {
      status: 'rejected',
      reviewedAt,
      reviewedByAdminId: adminFirebaseUid,
      rejectionReason: reason,
    },
  });

  // Notify user (non-fatal — user may have already revoked FCM tokens)
  await sendFcmToUser(req.user.id, {
    title: 'Account deletion request declined',
    body: reason.slice(0, 100),
  });

  return {
    id: requestId,
    status: 'rejected',
    reviewedAt: reviewedAt.toISOString(),
  };
}
