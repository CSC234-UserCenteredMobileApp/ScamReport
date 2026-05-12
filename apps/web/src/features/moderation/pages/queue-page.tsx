import { differenceInHours } from 'date-fns';
import { Inbox } from 'lucide-react';
import { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { toast } from 'sonner';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import { PageHeader } from '@/components/page-header';
import { useQueue } from '@/features/moderation/api/queue';
import {
  useModerationAction,
  type ModerationActionKind,
} from '@/features/moderation/api/actions';
import { useActionDialog } from '@/features/moderation/hooks/use-action-dialog';
import { ActionDialog } from '@/features/moderation/components/action-dialog';
import { QueueStats } from '@/features/moderation/components/queue-stats';
import { QueueTable } from '@/features/moderation/components/queue-table';

const toastKey: Record<ModerationActionKind, string> = {
  approve: 'toast.approved',
  reject: 'toast.rejected',
  flag: 'toast.flagged',
  unflag: 'toast.unflagged',
};

export function QueuePage() {
  const { t } = useTranslation('moderation');
  const { data, isLoading, isError, refetch } = useQueue();
  const dialog = useActionDialog();

  const approve = useModerationAction('approve');
  const reject = useModerationAction('reject');
  const flag = useModerationAction('flag');
  const unflag = useModerationAction('unflag');
  const mutations = { approve, reject, flag, unflag } as const;
  const submitting = Object.values(mutations).some((m) => m.isPending);

  const avgAgeHours = useMemo(() => {
    if (!data || data.items.length === 0) return null;
    const total = data.items.reduce(
      (sum, it) => sum + differenceInHours(new Date(), new Date(it.submittedAt)),
      0,
    );
    return total / data.items.length;
  }, [data]);

  const onSubmit = (remark: string) => {
    if (!dialog.state.item || !dialog.state.kind) return;
    const kind = dialog.state.kind;
    const id = dialog.state.item.id;
    mutations[kind].mutate(
      { id, remark },
      {
        onSuccess: () => {
          toast.success(t(toastKey[kind]));
          dialog.closeDialog();
        },
        onError: () => {
          toast.error(t('toast.actionError'));
        },
      },
    );
  };

  return (
    <div className="space-y-6">
      <PageHeader title={t('queueTitle')} subtitle={t('queueSubtitle')} />

      {isLoading && (
        <div className="space-y-4">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
            <Skeleton className="h-24" />
            <Skeleton className="h-24" />
            <Skeleton className="h-24" />
          </div>
          <Skeleton className="h-72" />
        </div>
      )}

      {isError && (
        <Alert variant="destructive">
          <AlertTitle>{t('error')}</AlertTitle>
          <AlertDescription className="flex items-center justify-between gap-4">
            <span>{t('error')}</span>
            <Button variant="outline" size="sm" onClick={() => void refetch()}>
              {t('action.review')}
            </Button>
          </AlertDescription>
        </Alert>
      )}

      {data && (
        <>
          <QueueStats
            pendingCount={data.pendingCount}
            flaggedCount={data.flaggedCount}
            avgAgeHours={avgAgeHours}
          />
          {data.items.length === 0 ? (
            <div className="flex flex-col items-center gap-2 rounded-lg border bg-card py-16 text-center text-muted-foreground">
              <Inbox className="size-8" aria-hidden />
              <p className="text-sm font-medium">{t('empty')}</p>
            </div>
          ) : (
            <QueueTable items={data.items} onAction={dialog.openDialog} />
          )}
        </>
      )}

      <ActionDialog
        open={dialog.state.open}
        onOpenChange={(o) => (o ? undefined : dialog.closeDialog())}
        kind={dialog.state.kind}
        reportTitle={dialog.state.item?.title ?? ''}
        submitting={submitting}
        onSubmit={onSubmit}
      />
    </div>
  );
}
