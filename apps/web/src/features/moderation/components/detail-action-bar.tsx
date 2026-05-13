import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import { toast } from 'sonner';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { ActionDialog } from '@/features/moderation/components/action-dialog';
import {
  useModerationAction,
  type ModerationActionKind,
} from '@/features/moderation/api/actions';
import type { AdminReportDetail } from '@my-product/shared';

interface DetailActionBarProps {
  report: AdminReportDetail;
}

const toastKey: Record<ModerationActionKind, string> = {
  approve: 'toast.approved',
  reject: 'toast.rejected',
  flag: 'toast.flagged',
  unflag: 'toast.unflagged',
};

export function DetailActionBar({ report }: DetailActionBarProps) {
  const { t } = useTranslation('moderation');
  const navigate = useNavigate();
  const [active, setActive] = useState<ModerationActionKind | null>(null);

  const approve = useModerationAction('approve');
  const reject = useModerationAction('reject');
  const flag = useModerationAction('flag');
  const unflag = useModerationAction('unflag');
  const mutations = { approve, reject, flag, unflag } as const;
  const submitting = Object.values(mutations).some((m) => m.isPending);

  const alreadyDone = report.status === 'verified' || report.status === 'rejected';

  if (alreadyDone) {
    return (
      <Alert variant="default" className="border-muted-foreground/20">
        <AlertDescription>{t('detail.alreadyActioned')}</AlertDescription>
      </Alert>
    );
  }

  const onSubmit = (remark: string) => {
    if (!active) return;
    mutations[active].mutate(
      { id: report.id, remark },
      {
        onSuccess: () => {
          toast.success(t(toastKey[active]));
          setActive(null);
          navigate('/moderation');
        },
        onError: () => {
          toast.error(t('toast.actionError'));
        },
      },
    );
  };

  const flagKind: ModerationActionKind = report.status === 'flagged' ? 'unflag' : 'flag';
  const flagLabelKey =
    report.status === 'flagged' ? 'detail.actions.unflag' : 'detail.actions.flag';

  return (
    <>
      <div className="sticky bottom-0 -mx-4 flex flex-wrap items-center justify-end gap-2 border-t bg-background/95 px-4 py-3 backdrop-blur sm:mx-0 sm:rounded-lg sm:border">
        <Button
          variant="outline"
          onClick={() => setActive('reject')}
          disabled={submitting}
          className="border-destructive/40 text-destructive hover:bg-destructive/10"
        >
          {t('detail.actions.reject')}
        </Button>
        <Button
          variant="outline"
          onClick={() => setActive(flagKind)}
          disabled={submitting}
          className="border-verdict-suspicious-fg/40 text-verdict-suspicious-fg hover:bg-verdict-suspicious-bg"
        >
          {t(flagLabelKey)}
        </Button>
        <Button onClick={() => setActive('approve')} disabled={submitting}>
          {t('detail.actions.approve')}
        </Button>
      </div>

      <ActionDialog
        open={active !== null}
        onOpenChange={(open) => (open ? undefined : setActive(null))}
        kind={active}
        reportTitle={report.title}
        submitting={submitting}
        onSubmit={onSubmit}
      />
    </>
  );
}
