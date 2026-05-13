import { useTranslation } from 'react-i18next';
import type { DeletionRequestStatus } from '@my-product/shared';
import { Badge } from '@/components/ui/badge';

const variantMap: Record<DeletionRequestStatus, 'unknown' | 'safe' | 'scam'> = {
  pending: 'unknown',
  approved: 'scam',
  rejected: 'safe',
};

export function DeletionStatusBadge({ status }: { status: DeletionRequestStatus }) {
  const { t } = useTranslation('announcements');
  return <Badge variant={variantMap[status]}>{t(`deletionRequests.status.${status}`)}</Badge>;
}
