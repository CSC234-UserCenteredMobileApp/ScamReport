import { describe, it, expect } from 'vitest';
import {
  formatPercent,
  formatNumber,
  formatDateShort,
  formatRelative,
} from './format';

describe('formatPercent', () => {
  it('defaults to 1 fractional digit', () => {
    expect(formatPercent(0.876, 'en')).toBe('87.6%');
  });

  it('honours custom digit count', () => {
    expect(formatPercent(0.5, 'en', { digits: 0 })).toBe('50%');
  });

  it('rounds gracefully', () => {
    expect(formatPercent(0.99999, 'en')).toBe('100.0%');
  });

  it('renders for th locale', () => {
    const out = formatPercent(0.5, 'th');
    expect(out).toContain('50');
    expect(out).toContain('%');
  });
});

describe('formatNumber', () => {
  it('applies thousands grouping in en', () => {
    expect(formatNumber(12345, 'en')).toBe('12,345');
  });

  it('renders 0 without grouping', () => {
    expect(formatNumber(0, 'en')).toBe('0');
  });

  it('renders large numbers for th', () => {
    const out = formatNumber(1234567, 'th');
    expect(out).toContain('1');
    expect(out).toContain('234');
  });
});

describe('formatDateShort', () => {
  it('returns a non-empty string for a valid ISO date', () => {
    const out = formatDateShort('2026-05-28T00:00:00Z', 'en');
    expect(out.length).toBeGreaterThan(0);
  });

  it('accepts a Date instance', () => {
    const out = formatDateShort(new Date('2026-05-28T00:00:00Z'), 'en');
    expect(out.length).toBeGreaterThan(0);
  });
});

describe('formatRelative', () => {
  it('describes a past time', () => {
    const past = new Date(Date.now() - 2 * 3600 * 1000);
    const out = formatRelative(past, 'en');
    expect(out.toLowerCase()).toContain('hour');
  });

  it('describes a future time', () => {
    const future = new Date(Date.now() + 3 * 24 * 3600 * 1000);
    const out = formatRelative(future, 'en');
    expect(out.toLowerCase()).toContain('day');
  });
});
