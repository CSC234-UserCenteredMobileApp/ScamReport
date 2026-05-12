import { describe, it, expect } from 'vitest';
import { act, renderHook } from '@testing-library/react';
import { useActionDialog } from '@/features/moderation/hooks/use-action-dialog';
import { sampleItem } from '../mocks/handlers';

describe('useActionDialog', () => {
  it('starts closed', () => {
    const { result } = renderHook(() => useActionDialog());
    expect(result.current.state.open).toBe(false);
    expect(result.current.state.kind).toBeNull();
  });

  it('opens with the chosen item + kind', () => {
    const { result } = renderHook(() => useActionDialog());
    act(() => result.current.openDialog(sampleItem, 'approve'));
    expect(result.current.state.open).toBe(true);
    expect(result.current.state.kind).toBe('approve');
    expect(result.current.state.item).toBe(sampleItem);
  });

  it('close keeps the last item but flips open to false', () => {
    const { result } = renderHook(() => useActionDialog());
    act(() => result.current.openDialog(sampleItem, 'flag'));
    act(() => result.current.closeDialog());
    expect(result.current.state.open).toBe(false);
    expect(result.current.state.item).toBe(sampleItem);
  });
});
