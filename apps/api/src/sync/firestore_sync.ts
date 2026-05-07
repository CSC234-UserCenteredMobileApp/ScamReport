// =============================================================================
// Firestore mirror writer (PRD §6.5, architecture doc "Firestore mirror")
// =============================================================================
//
// Postgres is the system of record. Firestore mirrors only two read surfaces:
//   - alerts/{announcementId}                  (public)
//   - my-reports/{uid}/items/{reportId}        (per-user)
//
// All writes here are server-only via the Firebase Admin SDK; Firestore rules
// (firestore.rules) deny all client writes. Mirror failure is *logged* and
// *swallowed* — Postgres write succeeded; a nightly reconciliation job
// re-mirrors divergences.
//
// FR-6.1: the reporter sees `flagged` as `pending`. The mirror writer applies
// that mapping at write time, so the mobile listener never has to.

import { getFirestore } from 'firebase-admin/firestore';
import { getFirebaseAdmin } from '../core/firebase/admin';

let _testStub: FirestoreLike | null = null;

interface FirestoreLike {
  collection: (path: string) => CollectionLike;
}
interface CollectionLike {
  doc: (id: string) => DocLike;
}
interface DocLike {
  set: (data: Record<string, unknown>, opts?: { merge?: boolean }) => Promise<unknown>;
  delete: () => Promise<unknown>;
}

// Test seam: replace the Firestore client with a stub. Used by route + sync
// tests so we don't reach Firebase in CI.
export function __setFirestoreForTest(stub: FirestoreLike | null): void {
  _testStub = stub;
}

function db(): FirestoreLike {
  if (_testStub) return _testStub;
  return getFirestore(getFirebaseAdmin()) as unknown as FirestoreLike;
}

export type ReporterStatus = 'pending' | 'verified' | 'rejected' | 'withdrawn';

export interface MirrorMyReportInput {
  id: string;
  reporterId: string | null;
  title: string;
  // Real DB status — including the admin-internal `flagged`. The mirror
  // remaps `flagged → 'pending'` per FR-6.1 before writing.
  status: 'pending' | 'verified' | 'rejected' | 'flagged' | 'withdrawn';
  scamTypeCode: string;
  createdAt: Date | string;
  updatedAt: Date | string;
  verifiedAt?: Date | string | null;
  rejectionRemark?: string | null;
}

function toReporterStatus(status: MirrorMyReportInput['status']): ReporterStatus {
  return status === 'flagged' ? 'pending' : status;
}

function toIso(d: Date | string): string {
  return d instanceof Date ? d.toISOString() : d;
}

/**
 * Writes the per-user My Reports mirror document. Idempotent: uses
 * `set({ merge: true })` so the document converges to the latest Postgres
 * row state, including admin status transitions.
 *
 * No-op (with a warn log) when the report has no reporter (e.g., the reporter
 * account was deleted and reporterId is now null) — the mirror is per-user.
 */
export async function mirrorMyReport(report: MirrorMyReportInput): Promise<void> {
  if (!report.reporterId) {
    console.warn('[firestore-sync] mirrorMyReport: skipping — no reporterId', {
      reportId: report.id,
    });
    return;
  }

  const status = toReporterStatus(report.status);
  if (status === 'withdrawn') {
    // Withdrawn reports drop from the user's list — delete the mirror doc.
    try {
      await db()
        .collection(`my-reports/${report.reporterId}/items`)
        .doc(report.id)
        .delete();
    } catch (err) {
      console.error('[firestore-sync] mirrorMyReport delete failed', {
        reportId: report.id,
        err,
      });
    }
    return;
  }

  try {
    await db()
      .collection(`my-reports/${report.reporterId}/items`)
      .doc(report.id)
      .set(
        {
          id: report.id,
          title: report.title,
          status,
          scamTypeCode: report.scamTypeCode,
          createdAt: toIso(report.createdAt),
          updatedAt: toIso(report.updatedAt),
          verifiedAt: report.verifiedAt ? toIso(report.verifiedAt) : null,
          rejectionRemark: report.rejectionRemark ?? null,
        },
        { merge: true },
      );
  } catch (err) {
    // Mirror failure is non-fatal — Postgres write already succeeded.
    // Logged for the nightly reconciliation job to pick up.
    console.error('[firestore-sync] mirrorMyReport set failed', {
      reportId: report.id,
      reporterId: report.reporterId,
      err,
    });
  }
}
