import { useTranslation } from 'react-i18next';
import { Badge } from '@/components/ui/badge';

type AnnouncementStatus = 'draft' | 'published' | 'unpublished';

const variantMap: Record<AnnouncementStatus, 'safe' | 'unknown' | 'suspicious'> = {
  draft: 'unknown',
  published: 'safe',
  unpublished: 'suspicious',
};

export function AnnouncementStatusBadge({ status }: { status: AnnouncementStatus }) {
  const { t } = useTranslation('announcements');
  return <Badge variant={variantMap[status]}>{t(`status.${status}`)}</Badge>;
}
