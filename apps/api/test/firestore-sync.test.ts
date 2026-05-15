import { afterEach, beforeEach, describe, expect, mock, spyOn, test } from 'bun:test';
import { __setFirestoreForTest, mirrorMyReport } from '../src/sync/firestore_sync';

interface Recorded {
  collectionPath: string;
  docId: string;
  setData?: Record<string, unknown>;
  setOptions?: { merge?: boolean };
  deleted?: boolean;
}

function makeStubFirestore() {
  const recorded: Recorded[] = [];
  let throwOnNextWrite = false;
  const stub = {
    collection: (collectionPath: string) => ({
      doc: (docId: string) => ({
        set: async (
          data: Record<string, unknown>,
          opts?: { merge?: boolean },
        ) => {
          if (throwOnNextWrite) {
            throwOnNextWrite = false;
            throw new Error('mock: firestore unavailable');
          }
          recorded.push({ collectionPath, docId, setData: data, setOptions: opts });
        },
        delete: async () => {
          if (throwOnNextWrite) {
            throwOnNextWrite = false;
            throw new Error('mock: firestore unavailable');
          }
          recorded.push({ collectionPath, docId, deleted: true });
        },
      }),
    }),
    failNext() {
      throwOnNextWrite = true;
    },
  };
  return { stub, recorded };
}

describe('mirrorMyReport', () => {
  let stubCtx: ReturnType<typeof makeStubFirestore>;
  let warnSpy: ReturnType<typeof spyOn>;
  let errorSpy: ReturnType<typeof spyOn>;

  beforeEach(() => {
    stubCtx = makeStubFirestore();
    __setFirestoreForTest(stubCtx.stub);
    warnSpy = spyOn(console, 'warn').mockImplementation(() => {});
    errorSpy = spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    __setFirestoreForTest(null);
    warnSpy.mockRestore();
    errorSpy.mockRestore();
  });

  test('writes pending report to my-reports/{uid}/items/{id}', async () => {
    const created = new Date('2026-05-07T00:00:00Z');
    await mirrorMyReport({
      id: 'rep-1',
      reporterId: 'user-1',
      title: 'Fake parcel SMS',
      status: 'pending',
      scamTypeCode: 'phishing_sms',
      createdAt: created,
      updatedAt: created,
    });
    expect(stubCtx.recorded).toHaveLength(1);
    const row = stubCtx.recorded[0]!;
    expect(row.collectionPath).toBe('my-reports/user-1/items');
    expect(row.docId).toBe('rep-1');
    expect(row.setOptions).toEqual({ merge: true });
    expect(row.setData?.status).toBe('pending');
    expect(row.setData?.title).toBe('Fake parcel SMS');
    expect(row.setData?.createdAt).toBe(created.toISOString());
    expect(row.setData?.verifiedAt).toBeNull();
    expect(row.setData?.rejectionRemark).toBeNull();
  });

  test('maps flagged status to pending for reporter view (FR-6.1)', async () => {
    await mirrorMyReport({
      id: 'rep-2',
      reporterId: 'user-2',
      title: 'Under team review',
      status: 'flagged',
      scamTypeCode: 'phone_impersonation',
      createdAt: new Date('2026-05-07T00:00:00Z'),
      updatedAt: new Date('2026-05-07T00:00:00Z'),
    });
    expect(stubCtx.recorded[0]?.setData?.status).toBe('pending');
  });

  test('writes verified status with verifiedAt + null rejectionRemark', async () => {
    const verified = new Date('2026-05-07T01:00:00Z');
    await mirrorMyReport({
      id: 'rep-3',
      reporterId: 'user-3',
      title: 'Verified report',
      status: 'verified',
      scamTypeCode: 'fake_qr',
      createdAt: new Date('2026-05-07T00:00:00Z'),
      updatedAt: verified,
      verifiedAt: verified,
    });
    expect(stubCtx.recorded[0]?.setData?.status).toBe('verified');
    expect(stubCtx.recorded[0]?.setData?.verifiedAt).toBe(verified.toISOString());
  });

  test('passes rejection remark through on rejected status', async () => {
    await mirrorMyReport({
      id: 'rep-4',
      reporterId: 'user-4',
      title: 'Rejected report',
      status: 'rejected',
      scamTypeCode: 'other',
      createdAt: new Date('2026-05-07T00:00:00Z'),
      updatedAt: new Date('2026-05-07T01:00:00Z'),
      rejectionRemark: 'Insufficient evidence',
    });
    expect(stubCtx.recorded[0]?.setData?.status).toBe('rejected');
    expect(stubCtx.recorded[0]?.setData?.rejectionRemark).toBe('Insufficient evidence');
  });

  test('deletes the mirror doc on withdrawn status', async () => {
    await mirrorMyReport({
      id: 'rep-5',
      reporterId: 'user-5',
      title: 'Withdrawn report',
      status: 'withdrawn',
      scamTypeCode: 'other',
      createdAt: new Date('2026-05-07T00:00:00Z'),
      updatedAt: new Date('2026-05-07T01:00:00Z'),
    });
    expect(stubCtx.recorded).toHaveLength(1);
    expect(stubCtx.recorded[0]?.deleted).toBe(true);
  });

  test('skips when reporterId is null and warns', async () => {
    await mirrorMyReport({
      id: 'rep-6',
      reporterId: null,
      title: 'Orphaned report',
      status: 'pending',
      scamTypeCode: 'other',
      createdAt: new Date('2026-05-07T00:00:00Z'),
      updatedAt: new Date('2026-05-07T00:00:00Z'),
    });
    expect(stubCtx.recorded).toHaveLength(0);
    expect(warnSpy).toHaveBeenCalled();
  });

  test('swallows write errors and logs them (Postgres is authoritative)', async () => {
    stubCtx.stub.failNext();
    await mirrorMyReport({
      id: 'rep-7',
      reporterId: 'user-7',
      title: 'Will fail to mirror',
      status: 'pending',
      scamTypeCode: 'other',
      createdAt: new Date('2026-05-07T00:00:00Z'),
      updatedAt: new Date('2026-05-07T00:00:00Z'),
    });
    expect(errorSpy).toHaveBeenCalled();
  });

  test('swallows delete errors on withdrawn status', async () => {
    stubCtx.stub.failNext();
    await mirrorMyReport({
      id: 'rep-8',
      reporterId: 'user-8',
      title: 'Withdraw failure',
      status: 'withdrawn',
      scamTypeCode: 'other',
      createdAt: new Date('2026-05-07T00:00:00Z'),
      updatedAt: new Date('2026-05-07T00:00:00Z'),
    });
    expect(errorSpy).toHaveBeenCalled();
  });
});
