import { describe, expect, test } from 'bun:test';
import { FormatRegistry } from '@sinclair/typebox';
import { Value } from '@sinclair/typebox/value';
import {
  CreateReportRequest,
  CreateReportResponse,
  EvidenceUploadResponse,
} from '../src/schemas/reports';

FormatRegistry.Set('uuid', (v) =>
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v),
);
FormatRegistry.Set('date-time', (v) => !Number.isNaN(Date.parse(v)));

const UUID = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';
const UUID2 = '6ba7b811-9dad-11d1-80b4-00c04fd430c8';
const DT = '2026-05-07T00:00:00.000Z';

const baseReport = {
  title: 'Fake Kerry parcel SMS',
  description: 'I received an SMS claiming a parcel was held; the link asked for OTP.',
  scamTypeCode: 'phishing_sms',
  evidenceFileIds: [],
};

describe('CreateReportRequest', () => {
  test('accepts minimum valid request', () => {
    expect(Value.Check(CreateReportRequest, baseReport)).toBe(true);
  });

  test('accepts request with target identifier + kind', () => {
    expect(
      Value.Check(CreateReportRequest, {
        ...baseReport,
        targetIdentifier: 'kerry-th-track.net',
        targetIdentifierKind: 'url',
      }),
    ).toBe(true);
  });

  test('accepts request with conversation linkage', () => {
    expect(
      Value.Check(CreateReportRequest, {
        ...baseReport,
        sourceConversationId: UUID,
        clientSubmissionId: 'client-abc-123',
      }),
    ).toBe(true);
  });

  test('accepts up to 5 evidence file ids', () => {
    expect(
      Value.Check(CreateReportRequest, {
        ...baseReport,
        evidenceFileIds: [UUID, UUID2, UUID, UUID2, UUID],
      }),
    ).toBe(true);
  });

  test('rejects more than 5 evidence file ids', () => {
    expect(
      Value.Check(CreateReportRequest, {
        ...baseReport,
        evidenceFileIds: [UUID, UUID2, UUID, UUID2, UUID, UUID2],
      }),
    ).toBe(false);
  });

  test('rejects short title', () => {
    expect(Value.Check(CreateReportRequest, { ...baseReport, title: 'hi' })).toBe(false);
  });

  test('rejects short description', () => {
    expect(
      Value.Check(CreateReportRequest, { ...baseReport, description: 'short' }),
    ).toBe(false);
  });

  test('rejects empty scamTypeCode', () => {
    expect(Value.Check(CreateReportRequest, { ...baseReport, scamTypeCode: '' })).toBe(false);
  });

  test('rejects invalid targetIdentifierKind', () => {
    expect(
      Value.Check(CreateReportRequest, {
        ...baseReport,
        targetIdentifierKind: 'email',
      }),
    ).toBe(false);
  });

  test('rejects non-uuid evidence file id', () => {
    expect(
      Value.Check(CreateReportRequest, {
        ...baseReport,
        evidenceFileIds: ['not-a-uuid'],
      }),
    ).toBe(false);
  });

  test('rejects non-uuid sourceConversationId', () => {
    expect(
      Value.Check(CreateReportRequest, {
        ...baseReport,
        sourceConversationId: 'not-a-uuid',
      }),
    ).toBe(false);
  });
});

describe('CreateReportResponse', () => {
  test('accepts pending response', () => {
    expect(
      Value.Check(CreateReportResponse, { id: UUID, status: 'pending', createdAt: DT }),
    ).toBe(true);
  });

  test('rejects non-pending status', () => {
    expect(
      Value.Check(CreateReportResponse, { id: UUID, status: 'verified', createdAt: DT }),
    ).toBe(false);
  });
});

describe('EvidenceUploadResponse', () => {
  test('accepts upload response', () => {
    expect(
      Value.Check(EvidenceUploadResponse, {
        evidenceFileId: UUID,
        storagePath: 'evidence/abc.jpg',
      }),
    ).toBe(true);
  });

  test('rejects empty storagePath', () => {
    expect(
      Value.Check(EvidenceUploadResponse, { evidenceFileId: UUID, storagePath: '' }),
    ).toBe(false);
  });
});
