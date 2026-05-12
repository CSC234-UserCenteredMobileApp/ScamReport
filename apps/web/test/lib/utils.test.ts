import { describe, it, expect } from 'vitest';
import { cn } from '@/lib/utils';

describe('cn', () => {
  it('merges Tailwind classes and dedupes conflicting utilities', () => {
    expect(cn('p-2', 'p-4')).toBe('p-4');
  });

  it('handles falsy values', () => {
    const flag: boolean = false;
    expect(cn('a', flag && 'b', null, undefined, 'c')).toBe('a c');
  });
});
