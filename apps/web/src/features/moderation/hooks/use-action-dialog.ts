import { useCallback, useState } from 'react';
import type { AdminQueueItem } from '@my-product/shared';
import type { ModerationActionKind } from '@/features/moderation/api/actions';

interface ActionDialogState {
  open: boolean;
  item: AdminQueueItem | null;
  kind: ModerationActionKind | null;
}

const closedState: ActionDialogState = { open: false, item: null, kind: null };

export function useActionDialog() {
  const [state, setState] = useState<ActionDialogState>(closedState);

  const openDialog = useCallback(
    (item: AdminQueueItem, kind: ModerationActionKind) => {
      setState({ open: true, item, kind });
    },
    [],
  );

  const closeDialog = useCallback(() => {
    setState((prev) => ({ ...prev, open: false }));
  }, []);

  return { state, openDialog, closeDialog };
}
