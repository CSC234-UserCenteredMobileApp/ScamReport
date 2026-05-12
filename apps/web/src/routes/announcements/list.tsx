import { useTranslation } from 'react-i18next';
import { PageHeader } from '@/components/page-header';
import { Card, CardContent } from '@/components/ui/card';

export default function AnnouncementsListPage() {
  const { t } = useTranslation('announcements');
  return (
    <div className="space-y-6">
      <PageHeader title={t('listTitle')} subtitle={t('comingSoonBody')} />
      <Card>
        <CardContent className="p-8 text-center text-muted-foreground">
          {t('comingSoonBody')}
        </CardContent>
      </Card>
    </div>
  );
}
