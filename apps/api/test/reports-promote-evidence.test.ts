import { afterEach, beforeEach, describe, expect, mock, test } from 'bun:test';

// iter-5: POST /reports promotedEvidenceAttachmentIds branch — copies bytes
// from chat-attachments → evidence bucket and inserts evidence_files rows.

let mockDecoded: { uid: string; email: string | null; role?: string } | null = null;
let mockScamType: { id: number; isActive: boolean } | null = null;
let mockChatAttachments: Array<{
  id: string;
  storagePath: string;
  mimeType: string;
  sizeBytes: bigint;
  ownerId: string;
  conversationId: string;
}> = [];
let copyFileCalls: Array<{
  srcBucket: string;
  srcPath: string;
  dstBucket: string;
  dstPath: string;
}> = [];
let evidenceCreateManyCalls: Array<{
  data: Array<{ storagePath: string; kind: string; mimeType: string }>;
}> = [];
let txReturn: unknown = null;

mock.module('firebase-admin/auth', () => ({
  getAuth: () => ({
    verifyIdToken: async () => {
      if (!mockDecoded) throw new Error('mock: no decoded token');
      return mockDecoded;
    },
  }),
}));

mock.module('../src/core/firebase/admin', () => ({
  getFirebaseAdmin: () => ({}),
}));

mock.module('../src/core/firebase/messaging', () => ({
  sendFcmToUser: async () => {},
}));

mock.module('../src/core/gemini/client', () => ({
  embed: async () => Array(768).fill(0.01),
  generateText: async () => '',
}));

// Don't mock ../src/sync/firestore_sync — Bun's mock.module is process-global,
// so registering a stub here would corrupt firestore-sync.test.ts which
// imports mirrorMyReport directly. The real mirrorMyReport call from
// createReport gracefully no-ops because we mock firebase/admin to return
// an empty object — the resulting throw is caught + logged inside the
// mirror module and never affects the response shape.

mock.module('../src/core/supabase/storage', () => ({
  uploadFile: async () => ({}),
  getSignedUrl: async () => 'https://signed.example/url',
  deleteFile: async () => {},
  copyFile: async (
    srcBucket: string,
    srcPath: string,
    dstBucket: string,
    dstPath: string,
  ) => {
    copyFileCalls.push({ srcBucket, srcPath, dstBucket, dstPath });
  },
}));

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    user: {
      upsert: async ({ where }: { where: { firebaseUid: string } }) =>
        ({ id: where.firebaseUid }),
    },
    scamType: {
      findUnique: async () => mockScamType,
    },
    report: {
      findFirst: async () => null,
    },
    aiMessageAttachment: {
      findMany: async ({
        where,
      }: {
        where: {
          id: { in: string[] };
          message: { conversation: { id: string; userId: string } };
        };
      }) => {
        return mockChatAttachments.filter(
          (a) =>
            where.id.in.includes(a.id) &&
            a.conversationId === where.message.conversation.id &&
            a.ownerId === where.message.conversation.userId,
        );
      },
    },
    aiConversation: {
      updateMany: async () => ({ count: 1 }),
    },
    $transaction: async (fn: (tx: unknown) => Promise<unknown>) => {
      const tx = {
        report: {
          create: async () => txReturn,
        },
        evidenceFile: {
          createMany: async (args: { data: Array<{ storagePath: string; kind: string; mimeType: string }> }) => {
            evidenceCreateManyCalls.push(args);
            return { count: args.data.length };
          },
        },
        aiConversation: {
          updateMany: async () => ({ count: 1 }),
        },
      };
      return fn(tx);
    },
  }),
}));

const { app } = await import('../src/index');

const REPORTER_UID = 'user-1';
const CONV_ID = 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa';
const ATTACH_ID = 'bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb';

function jsonReq(path: string, body: unknown) {
  return new Request(`http://localhost${path}`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      Authorization: 'Bearer tok',
    },
    body: JSON.stringify(body),
  });
}

beforeEach(() => {
  mockDecoded = { uid: REPORTER_UID, email: 'u@example.com' };
  mockScamType = { id: 1, isActive: true };
  mockChatAttachments = [];
  copyFileCalls = [];
  evidenceCreateManyCalls = [];
  txReturn = {
    id: '99999999-9999-4999-9999-999999999999',
    status: 'pending',
    createdAt: new Date('2026-05-10T00:00:00Z'),
    title: 'Test',
    scamType: { code: 'phishing_sms' },
  };
});

afterEach(() => {
  mockDecoded = null;
});

const baseReport = {
  title: 'Promoted draft',
  description: 'Description with enough length to satisfy the schema',
  scamTypeCode: 'phishing_sms',
  evidenceFiles: [],
  sourceConversationId: CONV_ID,
};

describe('POST /reports promotedEvidenceAttachmentIds', () => {
  test('400 without sourceConversationId', async () => {
    const res = await app.handle(
      jsonReq('/reports', {
        ...baseReport,
        sourceConversationId: undefined,
        promotedEvidenceAttachmentIds: [ATTACH_ID],
      }),
    );
    expect(res.status).toBe(400);
  });

  test('400 when promoted ids do not belong to conversation/owner', async () => {
    mockChatAttachments = [];
    const res = await app.handle(
      jsonReq('/reports', {
        ...baseReport,
        promotedEvidenceAttachmentIds: [ATTACH_ID],
      }),
    );
    expect(res.status).toBe(400);
  });

  test('copies and creates evidence_files rows for valid promoted ids', async () => {
    mockChatAttachments = [
      {
        id: ATTACH_ID,
        storagePath: `${CONV_ID}/foo.png`,
        mimeType: 'image/png',
        sizeBytes: 12345n,
        ownerId: REPORTER_UID,
        conversationId: CONV_ID,
      },
    ];
    const res = await app.handle(
      jsonReq('/reports', {
        ...baseReport,
        promotedEvidenceAttachmentIds: [ATTACH_ID],
      }),
    );
    expect(res.status).toBe(200);
    expect(copyFileCalls).toHaveLength(1);
    expect(copyFileCalls[0]?.srcBucket).toBe('chat-attachments');
    expect(copyFileCalls[0]?.dstBucket).toBe('evidence');
    expect(copyFileCalls[0]?.srcPath).toBe(`${CONV_ID}/foo.png`);
    expect(evidenceCreateManyCalls).toHaveLength(1);
    expect(evidenceCreateManyCalls[0]?.data).toHaveLength(1);
    expect(evidenceCreateManyCalls[0]?.data[0]?.kind).toBe('image');
  });

  test('rejects when total evidence files exceed cap of 5', async () => {
    mockChatAttachments = Array.from({ length: 4 }, (_, i) => ({
      id: `bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbb${i}`,
      storagePath: `${CONV_ID}/p${i}.png`,
      mimeType: 'image/png',
      sizeBytes: 1n,
      ownerId: REPORTER_UID,
      conversationId: CONV_ID,
    }));
    const res = await app.handle(
      jsonReq('/reports', {
        ...baseReport,
        evidenceFiles: [
          { storagePath: 'evidence/x1.png', kind: 'image', mimeType: 'image/png', sizeBytes: 1 },
          { storagePath: 'evidence/x2.png', kind: 'image', mimeType: 'image/png', sizeBytes: 1 },
        ],
        promotedEvidenceAttachmentIds: mockChatAttachments.map((a) => a.id),
      }),
    );
    expect(res.status).toBe(400);
  });
});
