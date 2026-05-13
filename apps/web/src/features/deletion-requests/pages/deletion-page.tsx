import { Inbox } from 'lucide-react';
import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { toast } from 'sonner';
import type {
  AdminDeletionRequestItem,
  DeletionRequestStatus,
} from '@my-product/shared';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import { PageHeader } from '@/components/page-header';
import { ApiError } from '@/lib/api/client';
import { useDeletionRequests } from '@/features/deletion-requests/api/list';
import {
  useApproveDeletion,
  useRejectDeletion,
} from '@/features/deletion-requests/api/mutations';
import { ApproveConfirmDialog } from '@/features/deletion-requests/components/approve-confirm-dialog';
import { DeletionTable } from '@/features/deletion-requests/components/deletion-table';
import { RejectDialog } from '@/features/deletion-requests/components/reject-dialog';
import { cn } from '@/lib/utils';

const filters: DeletionRequestStatus[] = ['pending', 'approved', 'rejected'];

export function DeletionRequestsPage() {
  const { t } = useTranslation('announcements');
  const [status, setStatus] = useState<DeletionRequestStatus>('pending');
  const { data, isLoading, isError, refetch } = useDeletionRequests(status);

  const [approveTarget, setApproveTarget] = useState<AdminDeletionRequestItem | null>(null);
  const [rejectTarget, setRejectTarget] = useState<AdminDeletionRequestItem | null>(null);

  const approve = useApproveDeletion();
  const reject = useRejectDeletion();
  const submitting = approve.isPending || reject.isPending;

  const onApproveConfirm = () => {
    if (!approveTarget) return;
    approve.mutate(
      { id: approveTarget.id },
      {
        onSuccess: () => {
          toast.success(t('deletionRequests.toast.approved'));
          setApproveTarget(null);
        },
        onError: (err) => {
          if (err instanceof ApiError && err.status === 409) {
            toast.error(t('deletionRequests.toast.alreadyReviewed'));
            setApproveTarget(null);
            return;
          }
          toast.error(t('deletionRequests.toast.actionError'));
        },
      },
    );
  };

  const onRejectSubmit = (reason: string) => {
    if (!rejectTarget) return;
    reject.mutate(
      { id: rejectTarget.id, reason },
      {
        onSuccess: () => {
          toast.success(t('deletionRequests.toast.rejected'));
          setRejectTarget(null);
        },
        onError: (err) => {
          if (err instanceof ApiError && err.status === 409) {
            toast.error(t('deletionRequests.toast.alreadyReviewed'));
            setRejectTarget(null);
            return;
          }
          toast.error(t('deletionRequests.toast.actionError'));
        },
      },
    );
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title={t('deletionRequests.title')}
        subtitle={t('deletionRequests.subtitle')}
      />

      <section
        aria-label={t('deletionRequests.stats')}
        className="rounded-lg border bg-card p-4"
      >
        <p className="text-xs uppercase tracking-wide text-muted-foreground">
          {t('deletionRequests.stats')}
        </p>
        <p className="mt-1 text-2xl font-semibold">
          {data?.pendingCount ?? 0}
        </p>
      </section>

      <div role="tablist" aria-label={t('deletionRequests.filter')} className="flex flex-wrap gap-2">
        {filters.map((f) => {
          const selected = status === f;
          return (
            <button
              key={f}
              type="button"
              role="tab"
              aria-selected={selected}
              onClick={() => setStatus(f)}
              className={cn(
                'rounded-xl border px-3 py-1.5 text-sm transition-colors',
                selected
                  ? 'border-primary bg-primary text-primary-foreground'
                  : 'border-border bg-card text-foreground hover:bg-muted',
              )}
            >
              {t(`deletionRequests.status.${f}`)}
            </button>
          );
        })}
      </div>

      {isLoading && (
        <div className="space-y-4">
          <Skeleton className="h-12" />
          <Skeleton className="h-72" />
        </div>
      )}

      {isError && (
        <Alert variant="destructive" role="alert">
          <AlertTitle>{t('deletionRequests.error')}</AlertTitle>
          <AlertDescription className="flex items-center justify-between gap-4">
            <span>{t('deletionRequests.error')}</span>
            <Button variant="outline" size="sm" onClick={() => void refetch()}>
              {t('retry')}
            </Button>
          </AlertDescription>
        </Alert>
      )}

      {data && data.items.length === 0 && (
        <div className="flex flex-col items-center gap-2 rounded-lg border bg-card py-16 text-center text-muted-foreground">
          <Inbox className="size-8" aria-hidden />
          <p className="text-sm font-medium">{t('deletionRequests.empty')}</p>
        </div>
      )}

      {data && data.items.length > 0 && (
        <DeletionTable
          items={data.items}
          onApprove={setApproveTarget}
          onReject={setRejectTarget}
        />
      )}

      <ApproveConfirmDialog
        open={approveTarget !== null}
        onOpenChange={(o) => (o ? undefined : setApproveTarget(null))}
        submitting={submitting}
        handle={approveTarget?.userHandle ?? ''}
        onConfirm={onApproveConfirm}
      />

      <RejectDialog
        open={rejectTarget !== null}
        onOpenChange={(o) => (o ? undefined : setRejectTarget(null))}
        submitting={submitting}
        handle={rejectTarget?.userHandle ?? ''}
        onSubmit={onRejectSubmit}
      />
    </div>
  );
}
