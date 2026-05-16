import { differenceInHours } from 'date-fns';
import { Inbox, SlidersHorizontal } from 'lucide-react';
import { useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { toast } from 'sonner';
import type { AdminQueueItem } from '@my-product/shared';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import { PageHeader } from '@/components/page-header';
import { useQueue } from '@/features/moderation/api/queue';
import { useScamTypes } from '@/features/moderation/api/scam-types';
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

type StatusFilter = 'all' | 'pending' | 'flagged';
type PriorityFilter = 'all' | 'priority';
type ConfidenceFilter = 'all' | 'high' | 'medium' | 'low';

function FilterPill({
  active,
  onClick,
  children,
}: {
  active: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={[
        'rounded-xl border px-3 py-1 text-xs transition-colors',
        active
          ? 'border-primary bg-primary text-primary-foreground'
          : 'border-border bg-card text-foreground hover:bg-muted',
      ].join(' ')}
    >
      {children}
    </button>
  );
}

export function QueuePage() {
  const { t, i18n } = useTranslation('moderation');
  const [scamTypeFilter, setScamTypeFilter] = useState<string | undefined>();
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');
  const [priorityFilter, setPriorityFilter] = useState<PriorityFilter>('all');
  const [confidenceFilter, setConfidenceFilter] = useState<ConfidenceFilter>('all');
  const { data, isLoading, isError, refetch } = useQueue(scamTypeFilter);
  const { data: scamTypesData } = useScamTypes();
  const dialog = useActionDialog();

  const approve = useModerationAction('approve');
  const reject = useModerationAction('reject');
  const flag = useModerationAction('flag');
  const unflag = useModerationAction('unflag');
  const mutations = { approve, reject, flag, unflag } as const;
  const submitting = Object.values(mutations).some((m) => m.isPending);

  const filteredItems = useMemo<AdminQueueItem[]>(() => {
    if (!data) return [];
    return data.items.filter((it) => {
      if (statusFilter !== 'all' && it.status !== statusFilter) return false;
      if (priorityFilter === 'priority' && !it.priorityFlag) return false;
      if (confidenceFilter !== 'all') {
        if (it.aiConfidence !== confidenceFilter) return false;
      }
      return true;
    });
  }, [data, statusFilter, priorityFilter, confidenceFilter]);

  const avgAgeHours = useMemo(() => {
    if (filteredItems.length === 0) return null;
    const total = filteredItems.reduce(
      (sum, it) => sum + differenceInHours(new Date(), new Date(it.submittedAt)),
      0,
    );
    return total / filteredItems.length;
  }, [filteredItems]);

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

      <div className="space-y-3 rounded-lg border bg-card p-4">
        <div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wide text-muted-foreground">
          <SlidersHorizontal className="size-3.5" aria-hidden />
          {t('filter.label')}
        </div>

        <div className="flex flex-wrap items-center gap-x-6 gap-y-3">
          <div className="flex flex-wrap items-center gap-1.5">
            <span className="text-xs text-muted-foreground">{t('filter.statusLabel')}:</span>
            <FilterPill active={statusFilter === 'all'} onClick={() => setStatusFilter('all')}>{t('filter.statusAll')}</FilterPill>
            <FilterPill active={statusFilter === 'pending'} onClick={() => setStatusFilter('pending')}>{t('status.pending')}</FilterPill>
            <FilterPill active={statusFilter === 'flagged'} onClick={() => setStatusFilter('flagged')}>{t('status.flagged')}</FilterPill>
          </div>

          <div className="flex flex-wrap items-center gap-1.5">
            <span className="text-xs text-muted-foreground">{t('filter.priorityLabel')}:</span>
            <FilterPill active={priorityFilter === 'all'} onClick={() => setPriorityFilter('all')}>{t('filter.priorityAll')}</FilterPill>
            <FilterPill active={priorityFilter === 'priority'} onClick={() => setPriorityFilter('priority')}>🚩 {t('filter.priorityOnly')}</FilterPill>
          </div>

          <div className="flex flex-wrap items-center gap-1.5">
            <span className="text-xs text-muted-foreground">{t('filter.confidenceLabel')}:</span>
            <FilterPill active={confidenceFilter === 'all'} onClick={() => setConfidenceFilter('all')}>{t('filter.confidenceAll')}</FilterPill>
            <FilterPill active={confidenceFilter === 'high'} onClick={() => setConfidenceFilter('high')}>
              <span className="text-red-600 dark:text-red-400">{t('filter.confidenceHigh')}</span>
            </FilterPill>
            <FilterPill active={confidenceFilter === 'medium'} onClick={() => setConfidenceFilter('medium')}>
              <span className="text-amber-600 dark:text-amber-400">{t('filter.confidenceMedium')}</span>
            </FilterPill>
            <FilterPill active={confidenceFilter === 'low'} onClick={() => setConfidenceFilter('low')}>
              <span className="text-green-600 dark:text-green-400">{t('filter.confidenceLow')}</span>
            </FilterPill>
          </div>
        </div>

        {scamTypesData && scamTypesData.items.length > 0 && (
          <div className="flex flex-wrap items-center gap-1.5">
            <span className="text-xs text-muted-foreground">{t('filter.typeLabel')}:</span>
            <FilterPill active={scamTypeFilter === undefined} onClick={() => setScamTypeFilter(undefined)}>{t('filter.scamTypeAll')}</FilterPill>
            {scamTypesData.items.map((st) => (
              <FilterPill
                key={st.code}
                active={scamTypeFilter === st.code}
                onClick={() => setScamTypeFilter(st.code)}
              >
                {i18n.language === 'th' ? st.labelTh : st.labelEn}
              </FilterPill>
            ))}
          </div>
        )}
      </div>

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
          {filteredItems.length === 0 ? (
            <div className="flex flex-col items-center gap-2 rounded-lg border bg-card py-16 text-center text-muted-foreground">
              <Inbox className="size-8" aria-hidden />
              <p className="text-sm font-medium">
                {data.items.length === 0 ? t('empty') : t('filter.noMatch')}
              </p>
            </div>
          ) : (
            <QueueTable items={filteredItems} onAction={dialog.openDialog} />
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
