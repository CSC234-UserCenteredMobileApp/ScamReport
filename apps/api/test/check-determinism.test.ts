import { describe, expect, mock, test } from 'bun:test';

mock.module('../src/core/firebase/admin', () => ({
  getFirebaseAdmin: () => ({ name: '[mock]' }),
}));

mock.module('../src/core/gemini/client', () => ({
  __setGeminiClientForTest: () => {},
  DEFAULT_MODEL: 'gemini-2.5-flash',
  EMBEDDING_MODEL: 'gemini-embedding-001',
  embed: async () => [],
  generateText: async () =>
    '{"verdict":"suspicious","reason":"deterministic stub"}',
  generateStructured: async () => ({}),
  generateMultimodal: async () => '',
  inlinePart: () => ({}),
  GeminiStructuredParseError: class GeminiStructuredParseError extends Error {},
}));

mock.module('../src/core/db/client', () => ({
  getPrisma: () => ({
    scammerIdentifier: { findUnique: async () => null },
    report: { findMany: async () => [] },
    checkLog: { create: async () => ({}) },
    $queryRaw: async () => [],
  }),
}));

import { runCheck } from '../src/features/check/check.service';

describe('runCheck determinism', () => {
  test('two identical text inputs produce identical verdicts', async () => {
    const payload = 'Your parcel is held at customs. Pay 250 THB to release.';
    const a = await runCheck(payload, 'text', null);
    const b = await runCheck(payload, 'text', null);
    expect(a.verdict).toBe(b.verdict);
  });

  test('two identical url inputs produce identical verdicts', async () => {
    const payload = 'https://example.test/path';
    const a = await runCheck(payload, 'url', null);
    const b = await runCheck(payload, 'url', null);
    expect(a.verdict).toBe(b.verdict);
  });
});
