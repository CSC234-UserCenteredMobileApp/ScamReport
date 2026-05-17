import { differenceInHours } from 'date-fns';
import { Inbox } from 'lucide-react';
import { useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { useSearchParams } from 'react-router-dom';
import { toast } from 'sonner';
import { z } from 'zod';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import { PageHeader } from '@/components/page-header';
import { useQueue, type QueueParams } from '@/features/moderation/api/queue';
import { useScamTypes } from '@/features/moderation/api/scam-types';
import {
  useModerationAction,
  type ModerationActionKind,
} from '@/features/moderation/api/actions';
import { useActionDialog } from '@/features/moderation/hooks/use-action-dialog';
import { ActionDialog } from '@/features/moderation/components/action-dialog';
import { QueueStats } from '@/features/moderation/components/queue-stats';
import { QueueTable } from '@/features/moderation/components/queue-table';
import { QueueToolbar } from '@/features/moderation/components/queue-toolbar';
import { QueuePagination } from '@/features/moderation/components/queue-pagination';
import { ExportButton } from '@/features/exports/components/export-button';
import type { ExportConfidence, ExportFilters } from '@/features/exports/api/export';

const toastKey: Record<ModerationActionKind, string> = {
  approve: 'toast.approved',
  reject: 'toast.rejected',
  flag: 'toast.flagged',
  unflag: 'toast.unflagged',
};

const QueueSearchSchema = z.object({
  q: z.string().optional(),
  status: z.enum(['pending', 'flagged', 'all']).optional(),
  priority: z.enum(['true', 'false']).optional(),
  confidence: z.enum(['high', 'medium', 'low', 'all']).optional(),
  scam_type: z.string().optional(),
  page: z.coerce.number().int().min(1).catch(1).optional(),
  page_size: z.coerce
    .number()
    .int()
    .refine((v) => [25, 50, 100].includes(v))
    .catch(25)
    .optional(),
});
export type QueueSearch = z.infer<typeof QueueSearchSchema>;

function parseSearch(sp: URLSearchParams): QueueSearch {
  const obj = Object.fromEntries(sp.entries());
  const parsed = QueueSearchSchema.safeParse(obj);
  return parsed.success ? parsed.data : {};
}

export function QueuePage() {
  const { t } = useTranslation('moderation');
  const [searchParams, setSearchParams] = useSearchParams();
  const search = useMemo(() => parseSearch(searchParams), [searchParams]);

  const queueParams: QueueParams = {
    q: search.q,
    status: search.status,
    priority: search.priority,
    confidence: search.confidence,
    scam_type: search.scam_type,
    page: search.page ?? 1,
    page_size: search.page_size ?? 25,
  };

  const { data, isLoading, isError, refetch } = useQueue(queueParams);
  const { data: scamTypesData } = useScamTypes();
  const dialog = useActionDialog();

  const approve = useModerationAction('approve');
  const reject = useModerationAction('reject');
  const flag = useModerationAction('flag');
  const unflag = useModerationAction('unflag');
  const mutations = { approve, reject, flag, unflag } as const;
  const submitting = Object.values(mutations).some((m) => m.isPending);

  const setSearch = useCallback(
    (updates: Partial<QueueSearch>, opts?: { replace?: boolean }) => {
      setSearchParams(
        (prev) => {
          const next = new URLSearchParams(prev);
          for (const [k, v] of Object.entries(updates)) {
            if (v === undefined || v === '' || v === 'all') next.delete(k);
            else next.set(k, String(v));
          }
          // Any non-page change resets pagination to 1.
          if (Object.keys(updates).some((k) => k !== 'page')) next.delete('page');
          return next;
        },
        { replace: opts?.replace ?? false },
      );
    },
    [setSearchParams],
  );

  const exportFilters = useMemo<ExportFilters>(() => {
    const statuses: string[] = [];
    if (!search.status || search.status === 'all') {
      statuses.push('pending', 'flagged');
    } else {
      statuses.push(search.status);
    }
    return {
      status: statuses,
      scamType: search.scam_type,
      priority: search.priority === 'true' ? true : undefined,
      confidence:
        !search.confidence || search.confidence === 'all'
          ? undefined
          : (search.confidence as ExportConfidence),
    };
  }, [search.status, search.priority, search.confidence, search.scam_type]);

  // Avg age is page-local — derives from currently displayed rows, not the
  // global queue. Same behaviour as before the redesign (filtered subset).
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
      <PageHeader
        title={t('queueTitle')}
        subtitle={t('queueSubtitle')}
        actions={<ExportButton filters={exportFilters} />}
      />

      <QueueToolbar
        search={search}
        scamTypes={scamTypesData?.items ?? []}
        onChange={setSearch}
      />

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
              <p className="text-sm font-medium">
                {data.total === 0 ? t('empty') : t('filter.noMatch')}
              </p>
            </div>
          ) : (
            <>
              <QueueTable items={data.items} onAction={dialog.openDialog} />
              <QueuePagination
                page={data.page}
                pageSize={data.pageSize}
                total={data.total}
                onChange={(u) => setSearch(u as Partial<QueueSearch>)}
              />
            </>
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
