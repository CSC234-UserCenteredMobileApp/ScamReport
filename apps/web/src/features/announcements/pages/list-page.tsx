import { Megaphone, Plus } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import { PageHeader } from '@/components/page-header';
import { AnnouncementsTable } from '@/features/announcements/components/announcements-table';
import { useAnnouncements } from '@/features/announcements/api/list';

export function AnnouncementsListPage() {
  const { t } = useTranslation('announcements');
  const navigate = useNavigate();
  const { data, isLoading, isError, refetch } = useAnnouncements();

  return (
    <div className="space-y-6">
      <PageHeader
        title={t('list.title')}
        subtitle={t('list.subtitle')}
        actions={
          <Button onClick={() => navigate('/announcements/new')}>
            <Plus className="mr-2 size-4" aria-hidden />
            {t('list.newCta')}
          </Button>
        }
      />

      {isLoading && (
        <div className="space-y-4">
          <Skeleton className="h-12" />
          <Skeleton className="h-72" />
        </div>
      )}

      {isError && (
        <Alert variant="destructive">
          <AlertTitle>{t('error')}</AlertTitle>
          <AlertDescription className="flex items-center justify-between gap-4">
            <span>{t('error')}</span>
            <Button variant="outline" size="sm" onClick={() => void refetch()}>
              {t('retry')}
            </Button>
          </AlertDescription>
        </Alert>
      )}

      {data && data.items.length === 0 && (
        <div className="flex flex-col items-center gap-2 rounded-lg border bg-card py-16 text-center text-muted-foreground">
          <Megaphone className="size-8" aria-hidden />
          <p className="text-sm font-medium">{t('list.empty')}</p>
        </div>
      )}

      {data && data.items.length > 0 && <AnnouncementsTable items={data.items} />}
    </div>
  );
}
