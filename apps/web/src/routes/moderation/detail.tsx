import { useTranslation } from 'react-i18next';
import { PageHeader } from '@/components/page-header';
import { Card, CardContent } from '@/components/ui/card';

export default function ModerationDetailPage() {
  const { t } = useTranslation('moderation');
  return (
    <div className="space-y-6">
      <PageHeader title={t('queueTitle')} subtitle={t('detailComingSoon')} />
      <Card>
        <CardContent className="p-8 text-center text-muted-foreground">
          {t('detailComingSoon')}
        </CardContent>
      </Card>
    </div>
  );
}
