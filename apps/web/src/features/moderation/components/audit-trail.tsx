import { format } from 'date-fns';
import { enUS, th } from 'date-fns/locale';
import { CheckCircle2, FileSearch, Flag, FlagOff, XCircle } from 'lucide-react';
import type { ComponentType, SVGProps } from 'react';
import { useTranslation } from 'react-i18next';
import type { ModerationRecord } from '@my-product/shared';

interface AuditTrailProps {
  records: ModerationRecord[];
  submittedAt: string;
}

const actionIcon: Record<ModerationRecord['action'], ComponentType<SVGProps<SVGSVGElement>>> = {
  approve: CheckCircle2,
  reject: XCircle,
  flag: Flag,
  unflag: FlagOff,
};

const actionTone: Record<ModerationRecord['action'], string> = {
  approve: 'text-verdict-safe-fg',
  reject: 'text-destructive',
  flag: 'text-verdict-suspicious-fg',
  unflag: 'text-muted-foreground',
};

export function AuditTrail({ records, submittedAt }: AuditTrailProps) {
  const { t, i18n } = useTranslation('moderation');
  const locale = i18n.language === 'th' ? th : enUS;

  // Newest first; the synthetic Submitted row anchors the bottom.
  const sorted = [...records].sort(
    (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
  );

  return (
    <ol className="space-y-3" data-testid="audit-trail">
      {sorted.map((r, idx) => {
        const Icon = actionIcon[r.action];
        return (
          <li
            key={`${r.createdAt}-${idx}`}
            className="flex gap-3 rounded-lg border bg-card p-3"
          >
            <Icon className={`mt-0.5 size-4 shrink-0 ${actionTone[r.action]}`} aria-hidden />
            <div className="flex-1 space-y-1">
              <div className="flex flex-wrap items-baseline justify-between gap-2 text-sm">
                <span className="font-medium">
                  {t(`detail.actions.${r.action}` as 'detail.actions.approve')}
                </span>
                <span className="text-xs text-muted-foreground">
                  {format(new Date(r.createdAt), 'PP p', { locale })}
                </span>
              </div>
              {r.remark.trim().length > 0 && (
                <p className="text-sm text-muted-foreground">{r.remark}</p>
              )}
              <p className="text-xs text-muted-foreground">
                {r.adminId ?? t('detail.anonymousAdmin')}
              </p>
            </div>
          </li>
        );
      })}

      <li className="flex gap-3 rounded-lg border bg-muted/30 p-3">
        <FileSearch className="mt-0.5 size-4 shrink-0 text-muted-foreground" aria-hidden />
        <div className="flex-1 space-y-1">
          <div className="flex flex-wrap items-baseline justify-between gap-2 text-sm">
            <span className="font-medium">{t('detail.auditSubmitted')}</span>
            <span className="text-xs text-muted-foreground">
              {format(new Date(submittedAt), 'PP p', { locale })}
            </span>
          </div>
          <p className="text-xs text-muted-foreground">
            {t('detail.submittedAnonymously')}
          </p>
        </div>
      </li>
    </ol>
  );
}
