import { describe, expect, test } from 'bun:test';
import { FormatRegistry } from '@sinclair/typebox';
import { Value } from '@sinclair/typebox/value';
import { CheckRequest, CheckResponse } from '../src/schemas/check';

// Register formats used by CheckRequest / CheckResponse schemas.
// TypeBox 0.34.x does not include format validators by default —
// unregistered formats cause Value.Check to return false.
FormatRegistry.Set('uuid', (v) =>
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v),
);
FormatRegistry.Set('date-time', (v) => !Number.isNaN(Date.parse(v)));

const VALID_UUID = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';
const VALID_DT = '2026-05-05T00:00:00.000Z';

describe('CheckRequest', () => {
  test('accepts valid phone request', () => {
    expect(Value.Check(CheckRequest, { type: 'phone', payload: '+66812345678' })).toBe(true);
  });

  test('accepts valid url request', () => {
    expect(Value.Check(CheckRequest, { type: 'url', payload: 'https://example.com' })).toBe(true);
  });

  test('accepts valid text request', () => {
    expect(Value.Check(CheckRequest, { type: 'text', payload: 'suspicious message' })).toBe(true);
  });

  test('accepts request with optional meta', () => {
    expect(
      Value.Check(CheckRequest, {
        type: 'phone',
        payload: '0812345678',
        meta: { source: 'clipboard', locale: 'th' },
      }),
    ).toBe(true);
  });

  test('rejects invalid type', () => {
    expect(Value.Check(CheckRequest, { type: 'email', payload: 'x' })).toBe(false);
  });

  test('rejects empty payload', () => {
    expect(Value.Check(CheckRequest, { type: 'phone', payload: '' })).toBe(false);
  });

  test('rejects missing payload', () => {
    expect(Value.Check(CheckRequest, { type: 'phone' })).toBe(false);
  });

  test('rejects additional properties', () => {
    expect(Value.Check(CheckRequest, { type: 'url', payload: 'x', extra: true })).toBe(false);
  });
});

describe('CheckResponse', () => {
  test('accepts scam verdict', () => {
    expect(Value.Check(CheckResponse, { verdict: 'scam', matchedCount: 3, matches: [] })).toBe(true);
  });

  test('accepts all four verdict labels', () => {
    for (const verdict of ['scam', 'suspicious', 'safe', 'unknown'] as const) {
      expect(Value.Check(CheckResponse, { verdict, matchedCount: 0, matches: [] })).toBe(true);
    }
  });

  test('accepts response with populated matches', () => {
    expect(
      Value.Check(CheckResponse, {
        verdict: 'suspicious',
        matchedCount: 1,
        matches: [
          {
            id: VALID_UUID,
            title: 'Test report',
            scamType: 'phone_impersonation',
            verifiedAt: VALID_DT,
          },
        ],
      }),
    ).toBe(true);
  });

  test('rejects unknown verdict label', () => {
    expect(Value.Check(CheckResponse, { verdict: 'maybe', matchedCount: 0, matches: [] })).toBe(false);
  });

  test('rejects negative matchedCount', () => {
    expect(Value.Check(CheckResponse, { verdict: 'safe', matchedCount: -1, matches: [] })).toBe(false);
  });

  test('rejects missing matches array', () => {
    expect(Value.Check(CheckResponse, { verdict: 'safe', matchedCount: 0 })).toBe(false);
  });
});
