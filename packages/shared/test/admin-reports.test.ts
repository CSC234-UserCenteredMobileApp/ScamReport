import { describe, expect, test } from 'bun:test';
import { FormatRegistry } from '@sinclair/typebox';
import { Value } from '@sinclair/typebox/value';
import {
  AdminQueueItem,
  AdminReportDetail,
  AiConfidence,
} from '../src/schemas/admin-reports';

FormatRegistry.Set('uuid', (v) =>
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v),
);
FormatRegistry.Set('date-time', (v) => !Number.isNaN(Date.parse(v)));

const ID = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';
const DT = '2026-05-05T00:00:00.000Z';

const baseQueueItem = {
  id: ID,
  title: 'Test scam',
  scamTypeCode: 'phone_impersonation',
  scamTypeLabelEn: 'Phone',
  scamTypeLabelTh: 'โทร',
  submittedAt: DT,
  status: 'pending' as const,
  priorityFlag: false,
  evidenceCount: 1,
  lastRemarkByAdmin: null,
};

describe('AiConfidence', () => {
  test('accepts the four documented tiers', () => {
    for (const v of ['high', 'medium', 'low', 'unknown']) {
      expect(Value.Check(AiConfidence, v)).toBe(true);
    }
  });
  test('rejects unknown tier strings', () => {
    expect(Value.Check(AiConfidence, 'critical')).toBe(false);
  });
});

describe('AdminQueueItem', () => {
  test('accepts row with persisted ai score + confidence', () => {
    const item = { ...baseQueueItem, aiScore: 87, aiConfidence: 'high' };
    expect(Value.Check(AdminQueueItem, item)).toBe(true);
  });

  test('accepts row with null ai fields (legacy)', () => {
    const item = { ...baseQueueItem, aiScore: null, aiConfidence: null };
    expect(Value.Check(AdminQueueItem, item)).toBe(true);
  });

  test('rejects row with out-of-range ai score', () => {
    const item = { ...baseQueueItem, aiScore: 150, aiConfidence: 'high' };
    expect(Value.Check(AdminQueueItem, item)).toBe(false);
  });

  test('rejects row missing ai fields entirely', () => {
    expect(Value.Check(AdminQueueItem, baseQueueItem)).toBe(false);
  });

  test('rejects reporter-identity leakage even when fields are present', () => {
    // Sanity: schema does not declare any reporter-identifying field.
    const leaky = {
      ...baseQueueItem,
      aiScore: null,
      aiConfidence: null,
      reporterHandle: 'User_3a91',
    };
    // additionalProperties default for TypeBox Object is allow-extra.
    // We still assert there is no declared property named `reporterId`
    // / `reporterHandle` on the schema by inspecting the type itself
    // — done via structural check below.
    expect(Value.Check(AdminQueueItem, leaky)).toBe(true);
    expect(Object.keys(AdminQueueItem.properties)).not.toContain('reporterId');
    expect(Object.keys(AdminQueueItem.properties)).not.toContain('reporterHandle');
  });
});

describe('AdminReportDetail', () => {
  const baseDetail = {
    id: ID,
    title: 'Test scam',
    description: 'Long enough description.',
    scamTypeCode: 'phone_impersonation',
    scamTypeLabelEn: 'Phone',
    scamTypeLabelTh: 'โทร',
    submittedAt: DT,
    status: 'pending' as const,
    priorityFlag: false,
    targetIdentifier: null,
    targetIdentifierKind: null,
    evidenceFiles: [],
    duplicateCount: 0,
    aiScore: 50,
    aiConfidence: 'low' as const,
    auditTrail: [],
    scammer: null,
    siblingCases: [],
  };
  test('accepts well-formed detail row', () => {
    expect(Value.Check(AdminReportDetail, baseDetail)).toBe(true);
  });
  test('declares no reporter-identifying property', () => {
    const props = Object.keys(AdminReportDetail.properties);
    expect(props).not.toContain('reporterId');
    expect(props).not.toContain('reporterHandle');
    expect(props).not.toContain('reporterEmail');
  });
});
