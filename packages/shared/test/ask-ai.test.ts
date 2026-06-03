import { describe, expect, test } from 'bun:test';
import { FormatRegistry } from '@sinclair/typebox';
import { Value } from '@sinclair/typebox/value';
import {
  AskAiTurnRequest,
  AskAiTurnResponse,
  AskAiDraft,
  AskAiConversationListResponse,
  AskAiConversationDetail,
} from '../src/schemas/ask-ai';

FormatRegistry.Set('uuid', (v) =>
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v),
);
FormatRegistry.Set('date-time', (v) => !Number.isNaN(Date.parse(v)));

const UUID = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';
const UUID2 = '6ba7b811-9dad-11d1-80b4-00c04fd430c8';
const DT = '2026-05-07T00:00:00.000Z';

const validDraft = {
  title: 'Fake Kerry parcel SMS with phishing link',
  description: 'I received an SMS claiming a parcel was held; the link asked for OTP.',
  scamTypeCode: 'phishing_sms',
  targetIdentifier: 'kerry-th-track.net',
  targetIdentifierKind: 'url' as const,
  suspectedScammerName: null,
};

describe('AskAiTurnRequest', () => {
  test('accepts text-only', () => {
    expect(Value.Check(AskAiTurnRequest, { content: 'hi', attachmentIds: [] })).toBe(true);
  });

  test('accepts up to 3 attachments', () => {
    expect(
      Value.Check(AskAiTurnRequest, {
        content: 'with files',
        attachmentIds: [UUID, UUID2, UUID],
      }),
    ).toBe(true);
  });

  test('rejects more than 3 attachments', () => {
    expect(
      Value.Check(AskAiTurnRequest, {
        content: 'too many',
        attachmentIds: [UUID, UUID2, UUID, UUID2],
      }),
    ).toBe(false);
  });

  test('rejects empty content', () => {
    expect(Value.Check(AskAiTurnRequest, { content: '', attachmentIds: [] })).toBe(false);
  });

  test('rejects content over 4000 chars', () => {
    expect(
      Value.Check(AskAiTurnRequest, { content: 'x'.repeat(4001), attachmentIds: [] }),
    ).toBe(false);
  });

  test('rejects non-uuid attachment id', () => {
    expect(
      Value.Check(AskAiTurnRequest, { content: 'x', attachmentIds: ['not-a-uuid'] }),
    ).toBe(false);
  });
});

describe('AskAiDraft', () => {
  test('accepts a complete draft', () => {
    expect(Value.Check(AskAiDraft, validDraft)).toBe(true);
  });

  test('accepts null target identifier', () => {
    expect(
      Value.Check(AskAiDraft, {
        ...validDraft,
        targetIdentifier: null,
        targetIdentifierKind: null,
      }),
    ).toBe(true);
  });

  test('rejects short title', () => {
    expect(Value.Check(AskAiDraft, { ...validDraft, title: 'no' })).toBe(false);
  });

  test('rejects short description', () => {
    expect(Value.Check(AskAiDraft, { ...validDraft, description: 'short' })).toBe(false);
  });

  test('rejects empty scamTypeCode', () => {
    expect(Value.Check(AskAiDraft, { ...validDraft, scamTypeCode: '' })).toBe(false);
  });
});

describe('AskAiTurnResponse', () => {
  const baseMessage = {
    id: UUID,
    role: 'user' as const,
    content: 'hi',
    intentDetected: false,
    createdAt: DT,
    attachments: [],
  };
  const assistantMessage = { ...baseMessage, id: UUID2, role: 'assistant' as const };

  const sampleSimilarReport = {
    id: UUID,
    title: 'Fake Kerry parcel SMS',
    scamTypeCode: 'phishing_sms',
    scamTypeLabelEn: 'Phishing SMS',
    scamTypeLabelTh: 'ฟิชชิง SMS',
    verifiedAt: DT,
  };

  test('accepts a not-reportable turn (with missingFacts)', () => {
    expect(
      Value.Check(AskAiTurnResponse, {
        userMessage: baseMessage,
        assistantMessage,
        intentDetected: false,
        searchIntent: false,
        reportable: false,
        hasEnoughInfo: false,
        draft: null,
        similarReports: [],
        matchedScammers: [],
        missingFacts: ['description', 'targetIdentifier', 'scamTypeCue', 'userAction'],
      }),
    ).toBe(true);
  });

  test('accepts a reportable turn with draft and empty missingFacts', () => {
    expect(
      Value.Check(AskAiTurnResponse, {
        userMessage: baseMessage,
        assistantMessage: { ...assistantMessage, intentDetected: true },
        intentDetected: true,
        searchIntent: false,
        reportable: true,
        hasEnoughInfo: true,
        draft: validDraft,
        similarReports: [sampleSimilarReport],
        matchedScammers: [],
        missingFacts: [],
      }),
    ).toBe(true);
  });

  test('accepts a search turn (cards, no draft, no missingFacts)', () => {
    expect(
      Value.Check(AskAiTurnResponse, {
        userMessage: baseMessage,
        assistantMessage,
        intentDetected: false,
        searchIntent: true,
        reportable: false,
        hasEnoughInfo: false,
        draft: null,
        similarReports: [sampleSimilarReport],
        matchedScammers: [],
        missingFacts: [],
      }),
    ).toBe(true);
  });

  test('rejects a turn missing searchIntent', () => {
    expect(
      Value.Check(AskAiTurnResponse, {
        userMessage: baseMessage,
        assistantMessage,
        intentDetected: false,
        reportable: false,
        hasEnoughInfo: false,
        draft: null,
        similarReports: [],
        matchedScammers: [],
        missingFacts: [],
      }),
    ).toBe(false);
  });

  test('rejects unknown missingFacts value', () => {
    expect(
      Value.Check(AskAiTurnResponse, {
        userMessage: baseMessage,
        assistantMessage,
        intentDetected: false,
        searchIntent: false,
        reportable: false,
        hasEnoughInfo: false,
        draft: null,
        similarReports: [],
        missingFacts: ['nope'],
      }),
    ).toBe(false);
  });

  test('rejects more than 5 similarReports', () => {
    expect(
      Value.Check(AskAiTurnResponse, {
        userMessage: baseMessage,
        assistantMessage,
        intentDetected: false,
        searchIntent: false,
        reportable: false,
        hasEnoughInfo: false,
        draft: null,
        similarReports: [
          sampleSimilarReport,
          { ...sampleSimilarReport, id: UUID2 },
          sampleSimilarReport,
          { ...sampleSimilarReport, id: UUID2 },
          sampleSimilarReport,
          { ...sampleSimilarReport, id: UUID2 },
        ],
        missingFacts: [],
      }),
    ).toBe(false);
  });

  test('rejects a similarReports entry missing required fields', () => {
    expect(
      Value.Check(AskAiTurnResponse, {
        userMessage: baseMessage,
        assistantMessage,
        intentDetected: false,
        searchIntent: false,
        reportable: false,
        hasEnoughInfo: false,
        draft: null,
        // Missing scamTypeLabelTh.
        similarReports: [{ ...sampleSimilarReport, scamTypeLabelTh: undefined }],
        missingFacts: [],
      }),
    ).toBe(false);
  });
});

describe('AskAiConversationListResponse', () => {
  test('accepts an empty list', () => {
    expect(Value.Check(AskAiConversationListResponse, { items: [] })).toBe(true);
  });

  test('accepts a populated list', () => {
    expect(
      Value.Check(AskAiConversationListResponse, {
        items: [
          {
            id: UUID,
            createdAt: DT,
            lastMessageAt: DT,
            preview: 'parcel from kerry…',
            linkedReportId: null,
          },
        ],
      }),
    ).toBe(true);
  });
});

describe('AskAiConversationDetail', () => {
  test('accepts a detail with messages', () => {
    expect(
      Value.Check(AskAiConversationDetail, {
        id: UUID,
        createdAt: DT,
        linkedReportId: null,
        messages: [
          {
            id: UUID2,
            role: 'user',
            content: 'hi',
            intentDetected: false,
            createdAt: DT,
            attachments: [],
          },
        ],
      }),
    ).toBe(true);
  });

  test('rejects a non-uuid linkedReportId', () => {
    expect(
      Value.Check(AskAiConversationDetail, {
        id: UUID,
        createdAt: DT,
        linkedReportId: 'not-a-uuid',
        messages: [],
      }),
    ).toBe(false);
  });
});
