import { formatDistanceToNowStrict } from 'date-fns';
import { enUS, th } from 'date-fns/locale';
import { ArrowLeft } from 'lucide-react';
import { useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate, useParams } from 'react-router-dom';
import { toast } from 'sonner';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { PageHeader } from '@/components/page-header';
import { ApiError } from '@/lib/api/client';
import { useReportDetail } from '@/features/moderation/api/detail';
import { AuditTrail } from '@/features/moderation/components/audit-trail';
import { DetailActionBar } from '@/features/moderation/components/detail-action-bar';
import { EvidenceGallery } from '@/features/moderation/components/evidence-gallery';

export function DetailPage() {
  const { id } = useParams<{ id: string }>();
  const { t, i18n } = useTranslation('moderation');
  const navigate = useNavigate();
  const locale = i18n.language === 'th' ? th : enUS;

  const { data, isLoading, error, refetch } = useReportDetail(id ?? '');

  // 404 → toast and bounce back to the queue. Bouncing as an effect (not
  // during render) keeps React from complaining about a navigate-in-render.
  useEffect(() => {
    if (error instanceof ApiError && error.status === 404) {
      toast.error(t('detail.notFound'));
      navigate('/moderation', { replace: true });
    }
  }, [error, navigate, t]);

  return (
    <div className="space-y-6 pb-6">
      <Button
        variant="ghost"
        size="sm"
        onClick={() => navigate(-1)}
        className="-ml-2 gap-2"
      >
        <ArrowLeft className="size-4" aria-hidden />
        {t('detail.back')}
      </Button>

      {isLoading && (
        <div className="space-y-4">
          <Skeleton className="h-10 w-1/2" />
          <Skeleton className="h-48" />
          <Skeleton className="h-32" />
        </div>
      )}

      {error && !(error instanceof ApiError && error.status === 404) && (
        <Alert variant="destructive">
          <AlertTitle>{t('detail.error')}</AlertTitle>
          <AlertDescription className="flex items-center justify-between gap-4">
            <span>{t('detail.error')}</span>
            <Button variant="outline" size="sm" onClick={() => void refetch()}>
              {t('action.review')}
            </Button>
          </AlertDescription>
        </Alert>
      )}

      {data && (
        <>
          <PageHeader
            title={t('detail.title')}
            subtitle={`${t(`status.${data.report.status as 'pending' | 'flagged'}` as 'status.pending')} • ${formatDistanceToNowStrict(
              new Date(data.report.submittedAt),
              { locale, addSuffix: true },
            )}`}
          />

          <Card>
            <CardContent className="space-y-4 p-5">
              <div className="flex flex-wrap items-center gap-2">
                <Badge variant="secondary">
                  {i18n.language === 'th'
                    ? data.report.scamTypeLabelTh
                    : data.report.scamTypeLabelEn}
                </Badge>
                {data.report.aiScore !== null && (
                  <Badge variant="outline">
                    {t('detail.ai.label')}: {data.report.aiScore}
                  </Badge>
                )}
                {data.report.priorityFlag && (
                  <Badge variant="suspicious">{t('status.flagged')}</Badge>
                )}
              </div>
              <h2 className="text-xl font-semibold">{data.report.title}</h2>
              <p className="text-sm text-muted-foreground">
                {t('detail.submittedAnonymously')}
              </p>
            </CardContent>
          </Card>

          <section className="space-y-2">
            <h3 className="text-sm font-semibold uppercase tracking-wide text-muted-foreground">
              {t('detail.description')}
            </h3>
            <p className="whitespace-pre-wrap rounded-lg border bg-card p-4 text-sm">
              {data.report.description}
            </p>
          </section>

          {data.report.targetIdentifier && (
            <section className="space-y-2">
              <h3 className="text-sm font-semibold uppercase tracking-wide text-muted-foreground">
                {t('detail.targetIdentifier')}
              </h3>
              <code className="inline-block rounded border bg-muted px-3 py-1 text-sm">
                {data.report.targetIdentifier}
              </code>
            </section>
          )}

          <section className="space-y-2">
            <div className="flex items-baseline justify-between gap-2">
              <h3 className="text-sm font-semibold uppercase tracking-wide text-muted-foreground">
                {t('detail.evidence')}
              </h3>
              <span className="text-xs text-muted-foreground">
                {t('detail.evidenceCount', { count: data.report.evidenceFiles.length })}
              </span>
            </div>
            <EvidenceGallery
              reportId={data.report.id}
              files={data.report.evidenceFiles}
            />
          </section>

          <section className="space-y-2">
            <h3 className="text-sm font-semibold uppercase tracking-wide text-muted-foreground">
              {t('detail.auditTrail')}
            </h3>
            <AuditTrail
              records={data.report.auditTrail}
              submittedAt={data.report.submittedAt}
            />
          </section>

          <DetailActionBar report={data.report} />
        </>
      )}
    </div>
  );
}
