import { useTranslation } from 'react-i18next';
import { Badge } from '@/components/ui/badge';

export function StatusBadge({ status }: { status: 'pending' | 'flagged' }) {
  const { t } = useTranslation('moderation');
  const variant = status === 'flagged' ? 'suspicious' : 'unknown';
  return <Badge variant={variant}>{t(`status.${status}`)}</Badge>;
}
