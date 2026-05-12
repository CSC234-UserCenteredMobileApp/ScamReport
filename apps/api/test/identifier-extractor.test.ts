import { describe, expect, test } from 'bun:test';
import {
  extractIdentifiers,
  normalizePhone,
  normalizeUrl,
} from '../src/core/lib/identifier-extractor';

describe('normalizePhone', () => {
  test('Thai mobile (10 digit) → E.164', () => {
    expect(normalizePhone('0871234567')).toBe('+66871234567');
  });

  test('strips separators', () => {
    expect(normalizePhone('087-123 4567')).toBe('+66871234567');
    expect(normalizePhone('(087) 123-4567')).toBe('+66871234567');
  });

  test('non-Thai format unchanged after stripping', () => {
    expect(normalizePhone('+44 20 7946 0958')).toBe('+442079460958');
  });
});

describe('normalizeUrl', () => {
  test('extracts lowercased hostname', () => {
    expect(normalizeUrl('https://K-Bank.xyz/login?x=1')).toBe('k-bank.xyz');
  });

  test('tolerates bare domain', () => {
    expect(normalizeUrl('k-bank.xyz')).toBe('k-bank.xyz');
  });

  test('falls back to trimmed lowercase for garbage', () => {
    expect(normalizeUrl('   FOO   ')).toBe('foo');
  });
});

describe('extractIdentifiers', () => {
  test('finds Thai phone in mixed text', () => {
    const { phones, urls } = extractIdentifiers(
      'Got an SMS from 0871234567 saying my parcel was held',
    );
    expect(phones).toEqual(['+66871234567']);
    expect(urls).toEqual([]);
  });

  test('finds URL in mixed text', () => {
    const { phones, urls } = extractIdentifiers(
      'visit http://k-bank.xyz/login to unlock',
    );
    expect(phones).toEqual([]);
    expect(urls).toEqual(['k-bank.xyz']);
  });

  test('finds bare domain', () => {
    const { urls } = extractIdentifiers('check k-bank.xyz first');
    expect(urls).toEqual(['k-bank.xyz']);
  });

  test('returns both when message mentions phone + URL', () => {
    const { phones, urls } = extractIdentifiers(
      'SMS from 0871234567 with link https://k-bank.xyz',
    );
    expect(phones).toEqual(['+66871234567']);
    expect(urls).toEqual(['k-bank.xyz']);
  });

  test('deduplicates repeated identifiers', () => {
    const { phones } = extractIdentifiers(
      '0871234567 then again 087-123-4567 and 087 123 4567',
    );
    expect(phones).toEqual(['+66871234567']);
  });

  test('does not match pure digit strings that look like numbers', () => {
    // 12345 is too short for the phone regex and shouldn't be matched as a URL.
    const { phones, urls } = extractIdentifiers('order 12345 confirmed');
    expect(phones).toEqual([]);
    expect(urls).toEqual([]);
  });

  test('returns empty arrays for empty input', () => {
    expect(extractIdentifiers('')).toEqual({ phones: [], urls: [] });
  });

  test('finds phone in Thai-language message', () => {
    const { phones } = extractIdentifiers(
      'มีคนโทรมาจาก 0871234567 บอกว่ามาจากธนาคาร',
    );
    expect(phones).toEqual(['+66871234567']);
  });
});
