import { useTranslation } from 'react-i18next';
import type { AnnouncementCategory } from '@my-product/shared';
import { Badge } from '@/components/ui/badge';

// Per docs/design/screens/announcement-editor.md: fraud_alert reuses the scam
// palette (warning red), tips uses the safe palette (green), platform_update
// uses primary coral. No new theme tokens introduced.
const variantMap: Record<AnnouncementCategory, 'scam' | 'safe' | 'default'> = {
  fraud_alert: 'scam',
  tips: 'safe',
  platform_update: 'default',
};

export function CategoryBadge({ category }: { category: AnnouncementCategory }) {
  const { t } = useTranslation('announcements');
  return <Badge variant={variantMap[category]}>{t(`category.${category}`)}</Badge>;
}
