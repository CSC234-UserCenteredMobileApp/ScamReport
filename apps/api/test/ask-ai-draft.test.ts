import { afterEach, beforeEach, describe, expect, mock, test } from 'bun:test';

// Standalone test file for iter-5 PATCH /draft + GET /:id (draft hydration).
// Reuses the mocking pattern from ask-ai.test.ts but keeps state isolated so
// the two suites can't interfere.

let mockDecoded: { uid: string; email: string | null; role?: string } | null = null;

let mockConversation: {
  id: string;
  userId: string;
  createdAt: Date;
  lastMessageAt: Date;
  linkedReportId: string | null;
  draftState: unknown;
} | null = null;

let mockAttachmentRows: Array<{
  id: string;
  storagePath: string;
  mimeType: string;
  sizeBytes: bigint;
  conversationId: string;
}> = [];

let mockMessages: Array<{
  id: string;
  role: string;
  content: string;
  intentDetected: boolean;
  createdAt: Date;
  attachments: Array<{
    id: string;
    storagePath: string;
    mimeType: string;
    sizeBytes: bigint;
  }>;
}> = [];

let lastDraftWrite: { conversationId: string; payload: unknown } | null = null;

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
  sendFcmBroadcast: async () => {},
}));

mock.module('../src/core/supabase/storage', () => ({
  uploadFile: async () => ({}),
  getSignedUrl: async (_bucket: string, path: string) =>
    `https://signed.example/${path}`,
  deleteFile: async () => {},
  copyFile: async () => {},
}));

mock.module('../src/core/gemini/client', () => ({
  embed: async () => Array(768).fill(0.01),
  generateText: async () => '',
  generateStructured: async () => ({}),
  GeminiStructuredParseError: class extends Error {},
  generateMultimodal: async () => ({ text: '', parsed: null }),
  inlinePart: () => ({ inlineData: { data: '', mimeType: '' } }),
}));

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    user: {
      upsert: async ({ where }: { where: { firebaseUid: string } }) =>
        ({ id: where.firebaseUid }),
    },
    aiConversation: {
      findFirst: async ({ where }: { where: { id: string; userId: string } }) => {
        if (
          !mockConversation ||
          mockConversation.id !== where.id ||
          mockConversation.userId !== where.userId
        ) {
          return null;
        }
        return mockConversation;
      },
      update: async ({
        where,
        data,
      }: {
        where: { id: string };
        data: { draftState?: unknown };
      }) => {
        if (mockConversation && mockConversation.id === where.id) {
          if ('draftState' in data) {
            mockConversation.draftState = data.draftState;
            lastDraftWrite = { conversationId: where.id, payload: data.draftState };
          }
        }
        return mockConversation;
      },
    },
    aiMessage: {
      findMany: async () => mockMessages,
    },
    aiMessageAttachment: {
      findMany: async ({ where }: { where: { id: { in: string[] }; message: { conversationId: string } } }) => {
        return mockAttachmentRows.filter(
          (a) =>
            where.id.in.includes(a.id) &&
            a.conversationId === where.message.conversationId,
        );
      },
    },
    $transaction: async (fn: (tx: unknown) => Promise<unknown>) => fn({}),
  }),
}));

const { app } = await import('../src/index');

const CONV_ID = 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa';
const ATTACH_ID = 'bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb';
const ATTACH_ID_2 = 'cccccccc-cccc-4ccc-cccc-cccccccccccc';

function jsonReq(
  path: string,
  opts?: { method?: string; token?: string; body?: unknown },
) {
  const headers: Record<string, string> = { 'content-type': 'application/json' };
  if (opts?.token) headers['Authorization'] = `Bearer ${opts.token}`;
  return new Request(`http://localhost${path}`, {
    method: opts?.method ?? 'GET',
    headers,
    body: opts?.body !== undefined ? JSON.stringify(opts.body) : undefined,
  });
}

beforeEach(() => {
  mockDecoded = null;
  mockConversation = null;
  mockAttachmentRows = [];
  mockMessages = [];
  lastDraftWrite = null;
});

afterEach(() => {
  mockDecoded = null;
});

const validDraft = {
  title: 'Fake Kerry parcel SMS with phishing link',
  description: 'I received an SMS claiming a parcel was held; the link asked for OTP.',
  scamTypeCode: 'phishing_sms',
  targetIdentifier: 'kerry-th-track.net',
  targetIdentifierKind: 'url' as const,
  userEditedDraft: false,
  evidenceAttachmentIds: [] as string[],
};

describe('PATCH /ask-ai/conversations/:id/draft', () => {
  test('401 when unauthenticated', async () => {
    const res = await app.handle(
      jsonReq(`/ask-ai/conversations/${CONV_ID}/draft`, {
        method: 'PATCH',
        body: validDraft,
      }),
    );
    expect(res.status).toBe(401);
  });

  test('404 when conversation not owned', async () => {
    mockDecoded = { uid: 'someone-else', email: 'x@example.com' };
    mockConversation = {
      id: CONV_ID,
      userId: 'user-1',
      createdAt: new Date('2026-05-07T00:00:00Z'),
      lastMessageAt: new Date('2026-05-07T00:00:00Z'),
      linkedReportId: null,
      draftState: null,
    };
    const res = await app.handle(
      jsonReq(`/ask-ai/conversations/${CONV_ID}/draft`, {
        method: 'PATCH',
        token: 'tok',
        body: validDraft,
      }),
    );
    expect(res.status).toBe(404);
  });

  test('persists a valid draft', async () => {
    mockDecoded = { uid: 'user-1', email: 'u@example.com' };
    mockConversation = {
      id: CONV_ID,
      userId: 'user-1',
      createdAt: new Date('2026-05-07T00:00:00Z'),
      lastMessageAt: new Date('2026-05-07T00:00:00Z'),
      linkedReportId: null,
      draftState: null,
    };
    const res = await app.handle(
      jsonReq(`/ask-ai/conversations/${CONV_ID}/draft`, {
        method: 'PATCH',
        token: 'tok',
        body: validDraft,
      }),
    );
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      ok: boolean;
      draft: { title: string } | null;
    };
    expect(body.ok).toBe(true);
    expect(body.draft?.title).toBe(validDraft.title);
    expect(lastDraftWrite?.payload).toMatchObject({ title: validDraft.title });
  });

  test('clears the draft on null body', async () => {
    mockDecoded = { uid: 'user-1', email: 'u@example.com' };
    mockConversation = {
      id: CONV_ID,
      userId: 'user-1',
      createdAt: new Date('2026-05-07T00:00:00Z'),
      lastMessageAt: new Date('2026-05-07T00:00:00Z'),
      linkedReportId: null,
      draftState: { ...validDraft },
    };
    const res = await app.handle(
      jsonReq(`/ask-ai/conversations/${CONV_ID}/draft`, {
        method: 'PATCH',
        token: 'tok',
        body: null,
      }),
    );
    expect(res.status).toBe(200);
    const body = (await res.json()) as { draft: unknown };
    expect(body.draft).toBeNull();
    // Prisma.DbNull marker — service writes the marker when null is passed.
    expect(lastDraftWrite?.payload).toBeDefined();
  });

  test('400 when evidenceAttachmentIds reference foreign attachments', async () => {
    mockDecoded = { uid: 'user-1', email: 'u@example.com' };
    mockConversation = {
      id: CONV_ID,
      userId: 'user-1',
      createdAt: new Date('2026-05-07T00:00:00Z'),
      lastMessageAt: new Date('2026-05-07T00:00:00Z'),
      linkedReportId: null,
      draftState: null,
    };
    // No matching rows for ATTACH_ID under CONV_ID — the service should reject.
    mockAttachmentRows = [
      {
        id: ATTACH_ID,
        conversationId: 'other-conv',
        storagePath: 'p',
        mimeType: 'image/png',
        sizeBytes: 100n,
      },
    ];
    const res = await app.handle(
      jsonReq(`/ask-ai/conversations/${CONV_ID}/draft`, {
        method: 'PATCH',
        token: 'tok',
        body: { ...validDraft, evidenceAttachmentIds: [ATTACH_ID] },
      }),
    );
    expect(res.status).toBe(400);
  });

  test('accepts evidence ids that belong to the conversation', async () => {
    mockDecoded = { uid: 'user-1', email: 'u@example.com' };
    mockConversation = {
      id: CONV_ID,
      userId: 'user-1',
      createdAt: new Date('2026-05-07T00:00:00Z'),
      lastMessageAt: new Date('2026-05-07T00:00:00Z'),
      linkedReportId: null,
      draftState: null,
    };
    mockAttachmentRows = [
      {
        id: ATTACH_ID,
        conversationId: CONV_ID,
        storagePath: 'foo.png',
        mimeType: 'image/png',
        sizeBytes: 100n,
      },
      {
        id: ATTACH_ID_2,
        conversationId: CONV_ID,
        storagePath: 'bar.png',
        mimeType: 'image/png',
        sizeBytes: 200n,
      },
    ];
    const res = await app.handle(
      jsonReq(`/ask-ai/conversations/${CONV_ID}/draft`, {
        method: 'PATCH',
        token: 'tok',
        body: { ...validDraft, evidenceAttachmentIds: [ATTACH_ID, ATTACH_ID_2] },
      }),
    );
    expect(res.status).toBe(200);
  });
});

describe('GET /ask-ai/conversations/:id (iter-5 hydration)', () => {
  test('returns draft + evidenceAttachments when draft has evidence', async () => {
    mockDecoded = { uid: 'user-1', email: 'u@example.com' };
    mockConversation = {
      id: CONV_ID,
      userId: 'user-1',
      createdAt: new Date('2026-05-07T00:00:00Z'),
      lastMessageAt: new Date('2026-05-07T00:00:00Z'),
      linkedReportId: null,
      draftState: { ...validDraft, evidenceAttachmentIds: [ATTACH_ID] },
    };
    mockAttachmentRows = [
      {
        id: ATTACH_ID,
        conversationId: CONV_ID,
        storagePath: 'foo.png',
        mimeType: 'image/png',
        sizeBytes: 100n,
      },
    ];
    const res = await app.handle(
      jsonReq(`/ask-ai/conversations/${CONV_ID}`, { token: 'tok' }),
    );
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      draft: { title: string; evidenceAttachmentIds: string[] } | null;
      evidenceAttachments: Array<{ id: string; signedUrl: string | null }>;
    };
    expect(body.draft?.title).toBe(validDraft.title);
    expect(body.draft?.evidenceAttachmentIds).toContain(ATTACH_ID);
    expect(body.evidenceAttachments).toHaveLength(1);
    expect(body.evidenceAttachments[0]?.id).toBe(ATTACH_ID);
    expect(body.evidenceAttachments[0]?.signedUrl).toContain('foo.png');
  });

  test('omits evidenceAttachments when draft is null', async () => {
    mockDecoded = { uid: 'user-1', email: 'u@example.com' };
    mockConversation = {
      id: CONV_ID,
      userId: 'user-1',
      createdAt: new Date('2026-05-07T00:00:00Z'),
      lastMessageAt: new Date('2026-05-07T00:00:00Z'),
      linkedReportId: null,
      draftState: null,
    };
    const res = await app.handle(
      jsonReq(`/ask-ai/conversations/${CONV_ID}`, { token: 'tok' }),
    );
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      draft: unknown;
      evidenceAttachments: unknown[];
    };
    expect(body.draft).toBeNull();
    expect(body.evidenceAttachments).toHaveLength(0);
  });
});
