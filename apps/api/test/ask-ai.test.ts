import { afterEach, beforeEach, describe, expect, mock, test } from 'bun:test';

// ---------------------------------------------------------------------------
// Module-level mock state
// ---------------------------------------------------------------------------
let mockDecoded: { uid: string; email: string | null; role?: string } | null = null;

let mockConversation: {
  id: string;
  userId: string;
  createdAt: Date;
  lastMessageAt: Date;
  linkedReportId: string | null;
} | null = null;
let mockConversationList: typeof mockConversation extends infer T
  ? Array<NonNullable<T> & { messages: Array<{ content: string }> }>
  : never = [] as never;
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

let createdConversationCalls = 0;
let insertedUserMessages: Array<{ conversationId: string; content: string }> = [];
let insertedAssistantMessages: Array<{ conversationId: string; content: string; intentDetected: boolean }> = [];
let touchedConversations: string[] = [];
let deletedConversations: string[] = [];
let geminiTurnCalls: unknown[] = [];

// Default Gemini stub returns a benign response. Tests can override per-case.
let geminiStub: (input: unknown) => unknown = () => ({
  text: JSON.stringify({
    reply: 'Hi! Tell me more.',
    intentDetected: false,
    hasEnoughInfo: false,
    reportable: false,
    similarReportIds: [],
  }),
});

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

let storageUploadCalls: Array<{ bucket: string; path: string; bytes: number }> = [];
mock.module('../src/core/supabase/storage', () => ({
  uploadFile: async (
    bucket: string,
    path: string,
    body: ArrayBuffer | Uint8Array,
  ) => {
    storageUploadCalls.push({
      bucket,
      path,
      bytes: body instanceof Uint8Array ? body.byteLength : (body as ArrayBuffer).byteLength,
    });
    return { path };
  },
  getSignedUrl: async () => 'https://signed.example/url',
  deleteFile: async () => {},
}));

// Embedding + RAG retrieval — return zero matches by default.
mock.module('../src/core/gemini/client', () => ({
  embed: async () => Array(768).fill(0.01),
  generateText: async () => '',
  generateStructured: async <T>(prompt: string, schema: unknown, opts: unknown) => {
    geminiTurnCalls.push({ prompt, schema, opts });
    const out = geminiStub({ prompt, schema, opts }) as { text: string };
    return JSON.parse(out.text) as T;
  },
  GeminiStructuredParseError: class extends Error {
    constructor(msg: string, public raw: string) {
      super(msg);
    }
  },
  generateMultimodal: async <T>(_parts: unknown, _opts: unknown) => {
    const out = geminiStub({ multimodal: true }) as { text: string };
    try {
      return { text: out.text, parsed: JSON.parse(out.text) as T };
    } catch {
      return { text: out.text, parsed: null as T | null };
    }
  },
  inlinePart: () => ({ inlineData: { data: '', mimeType: '' } }),
  __setGeminiClientForTest: () => {},
  DEFAULT_MODEL: 'gemini-2.5-flash',
  EMBEDDING_MODEL: 'gemini-embedding-001',
}));

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    aiConversation: {
      create: async ({ data }: { data: { userId: string } }) => {
        createdConversationCalls++;
        mockConversation = {
          id: '11111111-1111-1111-1111-111111111111',
          userId: data.userId,
          createdAt: new Date('2026-05-07T00:00:00Z'),
          lastMessageAt: new Date('2026-05-07T00:00:00Z'),
          linkedReportId: null,
        };
        return mockConversation;
      },
      findFirst: async ({ where }: { where: { id: string; userId: string } }) => {
        if (!mockConversation) return null;
        if (
          mockConversation.id !== where.id ||
          mockConversation.userId !== where.userId
        ) {
          return null;
        }
        return mockConversation;
      },
      findMany: async () => mockConversationList,
      update: async ({ where }: { where: { id: string } }) => {
        touchedConversations.push(where.id);
        return mockConversation;
      },
      delete: async ({ where }: { where: { id: string } }) => {
        deletedConversations.push(where.id);
        mockConversation = null;
        return { id: where.id };
      },
    },
    aiMessage: {
      findMany: async () => mockMessages,
      create: async ({ data }: { data: {
        conversationId: string;
        role: string;
        content: string;
        intentDetected: boolean;
      } }) => createAiMessageRow(data),
    },
    aiMessageAttachment: {
      create: async ({ data }: {
        data: {
          messageId: string;
          storagePath: string;
          mimeType: string;
          sizeBytes: bigint;
        };
      }) => ({
        id: '99999999-9999-9999-9999-999999999999',
        storagePath: data.storagePath,
        mimeType: data.mimeType,
        sizeBytes: data.sizeBytes,
      }),
    },
    report: {
      findMany: async () => [],
    },
    $queryRaw: async () => [],
    $transaction: async (fn: (tx: unknown) => Promise<unknown>) => {
      const tx = {
        aiMessage: {
          create: async ({ data }: { data: {
            conversationId: string;
            role: string;
            content: string;
            intentDetected: boolean;
          } }) => createAiMessageRow(data),
        },
        aiMessageAttachment: {
          create: async ({ data }: {
            data: {
              messageId: string;
              storagePath: string;
              mimeType: string;
              sizeBytes: bigint;
            };
          }) => ({
            id: '99999999-9999-9999-9999-999999999999',
            storagePath: data.storagePath,
            mimeType: data.mimeType,
            sizeBytes: data.sizeBytes,
          }),
        },
      };
      return fn(tx);
    },
  }),
}));

function createAiMessageRow(data: {
  conversationId: string;
  role: string;
  content: string;
  intentDetected: boolean;
}) {
  const row = {
    id:
      data.role === 'user'
        ? '22222222-2222-2222-2222-222222222222'
        : '33333333-3333-3333-3333-333333333333',
    role: data.role,
    content: data.content,
    intentDetected: data.intentDetected,
    createdAt: new Date('2026-05-07T00:00:01Z'),
    attachments: [] as Array<{
      id: string;
      storagePath: string;
      mimeType: string;
      sizeBytes: bigint;
    }>,
  };
  if (data.role === 'user') {
    insertedUserMessages.push({
      conversationId: data.conversationId,
      content: data.content,
    });
  } else {
    insertedAssistantMessages.push({
      conversationId: data.conversationId,
      content: data.content,
      intentDetected: data.intentDetected,
    });
  }
  mockMessages.push(row);
  return row;
}

const { app } = await import('../src/index');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
const VALID_CONV_ID = '11111111-1111-1111-1111-111111111111';
const NON_OWNER_TOKEN = 'tok-other';

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
  mockConversationList = [] as never;
  mockMessages = [];
  createdConversationCalls = 0;
  insertedUserMessages = [];
  insertedAssistantMessages = [];
  touchedConversations = [];
  deletedConversations = [];
  geminiTurnCalls = [];
  geminiStub = () => ({
    text: JSON.stringify({
      reply: 'Hi! Tell me more.',
      intentDetected: false,
      hasEnoughInfo: false,
      reportable: false,
      similarReportIds: [],
    }),
  });
});

afterEach(() => {
  mockDecoded = null;
});

// ---------------------------------------------------------------------------
// POST /ask-ai/conversations
// ---------------------------------------------------------------------------

describe('POST /ask-ai/conversations', () => {
  test('401 when unauthenticated', async () => {
    const res = await app.handle(
      jsonReq('/ask-ai/conversations', { method: 'POST', body: {} }),
    );
    expect(res.status).toBe(401);
  });

  test('creates a conversation for the user', async () => {
    mockDecoded = { uid: 'user-1', email: 'u@example.com' };
    const res = await app.handle(
      jsonReq('/ask-ai/conversations', { method: 'POST', token: 'tok', body: {} }),
    );
    expect(res.status).toBe(200);
    const body = (await res.json()) as { conversationId: string; createdAt: string };
    expect(body.conversationId).toBe(VALID_CONV_ID);
    expect(createdConversationCalls).toBe(1);
  });
});

// ---------------------------------------------------------------------------
// GET /ask-ai/conversations
// ---------------------------------------------------------------------------

describe('GET /ask-ai/conversations', () => {
  test('401 when unauthenticated', async () => {
    const res = await app.handle(jsonReq('/ask-ai/conversations'));
    expect(res.status).toBe(401);
  });

  test('returns user conversation list with previews', async () => {
    mockDecoded = { uid: 'user-1', email: 'u@example.com' };
    mockConversationList = [
      {
        id: VALID_CONV_ID,
        userId: 'user-1',
        createdAt: new Date('2026-05-07T00:00:00Z'),
        lastMessageAt: new Date('2026-05-07T01:00:00Z'),
        linkedReportId: null,
        messages: [{ content: 'parcel from kerry…' }],
      },
    ] as never;
    const res = await app.handle(
      jsonReq('/ask-ai/conversations', { token: 'tok' }),
    );
    expect(res.status).toBe(200);
    const body = (await res.json()) as { items: Array<{ preview: string }> };
    expect(body.items).toHaveLength(1);
    expect(body.items[0]?.preview).toBe('parcel from kerry…');
  });
});

// ---------------------------------------------------------------------------
// GET /ask-ai/conversations/:id
// ---------------------------------------------------------------------------

describe('GET /ask-ai/conversations/:id', () => {
  test('401 when unauthenticated', async () => {
    const res = await app.handle(
      jsonReq(`/ask-ai/conversations/${VALID_CONV_ID}`),
    );
    expect(res.status).toBe(401);
  });

  test('404 when conversation missing', async () => {
    mockDecoded = { uid: 'user-1', email: 'u@example.com' };
    const res = await app.handle(
      jsonReq(`/ask-ai/conversations/${VALID_CONV_ID}`, { token: 'tok' }),
    );
    expect(res.status).toBe(404);
  });

  test('404 when conversation owned by other user', async () => {
    mockDecoded = { uid: 'user-other', email: 'o@example.com' };
    mockConversation = {
      id: VALID_CONV_ID,
      userId: 'user-1',
      createdAt: new Date('2026-05-07T00:00:00Z'),
      lastMessageAt: new Date('2026-05-07T00:00:00Z'),
      linkedReportId: null,
    };
    const res = await app.handle(
      jsonReq(`/ask-ai/conversations/${VALID_CONV_ID}`, { token: NON_OWNER_TOKEN }),
    );
    expect(res.status).toBe(404);
  });

  test('returns conversation detail with messages', async () => {
    mockDecoded = { uid: 'user-1', email: 'u@example.com' };
    mockConversation = {
      id: VALID_CONV_ID,
      userId: 'user-1',
      createdAt: new Date('2026-05-07T00:00:00Z'),
      lastMessageAt: new Date('2026-05-07T01:00:00Z'),
      linkedReportId: null,
    };
    mockMessages = [
      {
        id: '44444444-4444-4444-4444-444444444444',
        role: 'user',
        content: 'hi',
        intentDetected: false,
        createdAt: new Date('2026-05-07T00:00:01Z'),
        attachments: [],
      },
      {
        id: '55555555-5555-5555-5555-555555555555',
        role: 'assistant',
        content: 'Hello!',
        intentDetected: false,
        createdAt: new Date('2026-05-07T00:00:02Z'),
        attachments: [],
      },
    ];
    const res = await app.handle(
      jsonReq(`/ask-ai/conversations/${VALID_CONV_ID}`, { token: 'tok' }),
    );
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      id: string;
      messages: Array<{ id: string; role: string }>;
    };
    expect(body.id).toBe(VALID_CONV_ID);
    expect(body.messages).toHaveLength(2);
    expect(body.messages[0]?.role).toBe('user');
  });
});

// ---------------------------------------------------------------------------
// DELETE /ask-ai/conversations/:id
// ---------------------------------------------------------------------------

describe('DELETE /ask-ai/conversations/:id', () => {
  test('404 when not owned', async () => {
    mockDecoded = { uid: 'user-1', email: 'u@example.com' };
    const res = await app.handle(
      jsonReq(`/ask-ai/conversations/${VALID_CONV_ID}`, {
        method: 'DELETE',
        token: 'tok',
      }),
    );
    expect(res.status).toBe(404);
  });

  test('deletes when owned', async () => {
    mockDecoded = { uid: 'user-1', email: 'u@example.com' };
    mockConversation = {
      id: VALID_CONV_ID,
      userId: 'user-1',
      createdAt: new Date('2026-05-07T00:00:00Z'),
      lastMessageAt: new Date('2026-05-07T00:00:00Z'),
      linkedReportId: null,
    };
    const res = await app.handle(
      jsonReq(`/ask-ai/conversations/${VALID_CONV_ID}`, {
        method: 'DELETE',
        token: 'tok',
      }),
    );
    expect(res.status).toBe(200);
    expect(deletedConversations).toContain(VALID_CONV_ID);
  });
});

// ---------------------------------------------------------------------------
// POST /ask-ai/conversations/:id/messages
// ---------------------------------------------------------------------------

describe('POST /ask-ai/conversations/:id/messages', () => {
  beforeEach(() => {
    mockConversation = {
      id: VALID_CONV_ID,
      userId: 'user-1',
      createdAt: new Date('2026-05-07T00:00:00Z'),
      lastMessageAt: new Date('2026-05-07T00:00:00Z'),
      linkedReportId: null,
    };
  });

  test('401 when unauthenticated', async () => {
    const res = await app.handle(
      jsonReq(`/ask-ai/conversations/${VALID_CONV_ID}/messages`, {
        method: 'POST',
        body: { content: 'hi', attachmentIds: [] },
      }),
    );
    expect(res.status).toBe(401);
  });

  test('422 when content empty', async () => {
    mockDecoded = { uid: 'user-1', email: 'u@example.com' };
    const res = await app.handle(
      jsonReq(`/ask-ai/conversations/${VALID_CONV_ID}/messages`, {
        method: 'POST',
        token: 'tok',
        body: { content: '', attachmentIds: [] },
      }),
    );
    expect(res.status).toBe(422);
  });

  test('400 when attachmentIds are passed via JSON endpoint (use multipart)', async () => {
    mockDecoded = { uid: 'user-1', email: 'u@example.com' };
    const res = await app.handle(
      jsonReq(`/ask-ai/conversations/${VALID_CONV_ID}/messages`, {
        method: 'POST',
        token: 'tok',
        body: {
          content: 'hi with file',
          attachmentIds: ['22222222-2222-2222-2222-222222222222'],
        },
      }),
    );
    expect(res.status).toBe(400);
    const body = (await res.json()) as { code: string };
    expect(body.code).toBe('use_multipart');
  });

  test('happy path: persists user msg + assistant msg + returns turn', async () => {
    mockDecoded = { uid: 'user-1', email: 'u@example.com' };
    geminiStub = () => ({
      text: JSON.stringify({
        reply: 'Tell me more about the SMS.',
        intentDetected: false,
        hasEnoughInfo: false,
        reportable: false,
        similarReportIds: [],
      }),
    });
    const res = await app.handle(
      jsonReq(`/ask-ai/conversations/${VALID_CONV_ID}/messages`, {
        method: 'POST',
        token: 'tok',
        body: { content: 'I got a weird SMS', attachmentIds: [] },
      }),
    );
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      userMessage: { content: string };
      assistantMessage: { content: string };
      reportable: boolean;
      draft: unknown;
    };
    expect(body.userMessage.content).toBe('I got a weird SMS');
    expect(body.assistantMessage.content).toBe('Tell me more about the SMS.');
    expect(body.reportable).toBe(false);
    expect(body.draft).toBeNull();
    expect(insertedUserMessages).toHaveLength(1);
    expect(insertedAssistantMessages).toHaveLength(1);
    expect(touchedConversations).toContain(VALID_CONV_ID);
  });

  test('reportable + draft path: surfaces draft', async () => {
    mockDecoded = { uid: 'user-1', email: 'u@example.com' };
    geminiStub = () => ({
      text: JSON.stringify({
        reply: 'That sounds like a phishing SMS. I drafted a report.',
        intentDetected: true,
        hasEnoughInfo: true,
        reportable: true,
        similarReportIds: [],
        draft: {
          title: 'Fake Kerry parcel SMS',
          description: 'I received an SMS asking me to click a tracking link with OTP form.',
          scamTypeCode: 'phishing_sms',
          targetIdentifier: 'kerry-th-track.net',
          targetIdentifierKind: 'url',
        },
      }),
    });
    const res = await app.handle(
      jsonReq(`/ask-ai/conversations/${VALID_CONV_ID}/messages`, {
        method: 'POST',
        token: 'tok',
        body: {
          content: 'I clicked a link from kerry-th-track.net and entered OTP.',
          attachmentIds: [],
        },
      }),
    );
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      reportable: boolean;
      intentDetected: boolean;
      draft: { title: string; scamTypeCode: string };
    };
    expect(body.reportable).toBe(true);
    expect(body.intentDetected).toBe(true);
    expect(body.draft?.scamTypeCode).toBe('phishing_sms');
  });

  test('parser failure produces fallback assistant reply (still 200)', async () => {
    mockDecoded = { uid: 'user-1', email: 'u@example.com' };
    geminiStub = () => ({
      text: 'this is not JSON',
    });
    const res = await app.handle(
      jsonReq(`/ask-ai/conversations/${VALID_CONV_ID}/messages`, {
        method: 'POST',
        token: 'tok',
        body: { content: 'whatever', attachmentIds: [] },
      }),
    );
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      assistantMessage: { content: string };
      reportable: boolean;
      draft: unknown;
    };
    expect(body.reportable).toBe(false);
    expect(body.draft).toBeNull();
    expect(body.assistantMessage.content.length).toBeGreaterThan(0);
  });

  test('404 when conversation does not belong to user', async () => {
    mockDecoded = { uid: 'user-other', email: 'o@example.com' };
    const res = await app.handle(
      jsonReq(`/ask-ai/conversations/${VALID_CONV_ID}/messages`, {
        method: 'POST',
        token: NON_OWNER_TOKEN,
        body: { content: 'hi', attachmentIds: [] },
      }),
    );
    expect(res.status).toBe(404);
  });
});

// ---------------------------------------------------------------------------
// POST /ask-ai/conversations/:id/messages/multipart
// ---------------------------------------------------------------------------

function multipartReq(token: string, fields: Record<string, string | File>) {
  const fd = new FormData();
  for (const [k, v] of Object.entries(fields)) {
    fd.append(k, v as Blob | string);
  }
  return new Request(
    `http://localhost/ask-ai/conversations/${VALID_CONV_ID}/messages/multipart`,
    {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
      body: fd,
    },
  );
}

describe('POST /ask-ai/conversations/:id/messages/multipart', () => {
  beforeEach(() => {
    storageUploadCalls = [];
    mockConversation = {
      id: VALID_CONV_ID,
      userId: 'user-1',
      createdAt: new Date('2026-05-07T00:00:00Z'),
      lastMessageAt: new Date('2026-05-07T00:00:00Z'),
      linkedReportId: null,
    };
  });

  test('uploads attachment + persists message + returns turn', async () => {
    mockDecoded = { uid: 'user-1', email: 'u@example.com' };
    const file = new File([new Uint8Array([1, 2, 3, 4])], 'screen.jpg', {
      type: 'image/jpeg',
    });
    const res = await app.handle(
      multipartReq('tok', {
        content: 'I got this SMS — see screenshot',
        file0: file,
      }),
    );
    expect(res.status).toBe(200);
    expect(storageUploadCalls).toHaveLength(1);
    expect(storageUploadCalls[0]?.bucket).toBe('chat-attachments');
    expect(storageUploadCalls[0]?.path.startsWith(`${VALID_CONV_ID}/`)).toBe(true);
  });

  test('413 when attachment is over the 10MB limit', async () => {
    mockDecoded = { uid: 'user-1', email: 'u@example.com' };
    const big = new Uint8Array(11 * 1024 * 1024);
    const file = new File([big], 'big.png', { type: 'image/png' });
    const res = await app.handle(
      multipartReq('tok', { content: 'big file', file0: file }),
    );
    expect(res.status).toBe(413);
    const body = (await res.json()) as { code: string };
    expect(body.code).toBe('attachment_too_large');
  });

  test('415 when MIME type is unsupported', async () => {
    mockDecoded = { uid: 'user-1', email: 'u@example.com' };
    const file = new File([new Uint8Array([1, 2])], 'a.exe', {
      type: 'application/octet-stream',
    });
    const res = await app.handle(
      multipartReq('tok', { content: 'unsupported', file0: file }),
    );
    expect(res.status).toBe(415);
    const body = (await res.json()) as { code: string };
    expect(body.code).toBe('unsupported_media_type');
  });

  test('400 when content is empty even if a file is attached', async () => {
    mockDecoded = { uid: 'user-1', email: 'u@example.com' };
    const file = new File([new Uint8Array([1, 2])], 'a.jpg', { type: 'image/jpeg' });
    const res = await app.handle(
      multipartReq('tok', { content: '', file0: file }),
    );
    expect([400, 422]).toContain(res.status);
  });

  test('401 when unauthenticated', async () => {
    const file = new File([new Uint8Array([1, 2])], 'a.jpg', { type: 'image/jpeg' });
    const fd = new FormData();
    fd.append('content', 'hi');
    fd.append('file0', file);
    const res = await app.handle(
      new Request(
        `http://localhost/ask-ai/conversations/${VALID_CONV_ID}/messages/multipart`,
        { method: 'POST', body: fd },
      ),
    );
    expect(res.status).toBe(401);
  });
});
