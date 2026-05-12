import { useTranslation } from 'react-i18next';
import { Card, CardContent } from '@/components/ui/card';

interface QueueStatsProps {
  pendingCount: number;
  flaggedCount: number;
  avgAgeHours: number | null;
}

function StatCard({ label, value }: { label: string; value: string }) {
  return (
    <Card>
      <CardContent className="flex flex-col gap-1 p-5">
        <span className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
          {label}
        </span>
        <span className="text-3xl font-bold text-foreground">{value}</span>
      </CardContent>
    </Card>
  );
}

export function QueueStats({ pendingCount, flaggedCount, avgAgeHours }: QueueStatsProps) {
  const { t } = useTranslation('moderation');
  const ageValue =
    avgAgeHours === null
      ? '—'
      : `${Math.round(avgAgeHours)}${t('stats.hoursUnit')}`;
  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
      <StatCard label={t('stats.pending')} value={String(pendingCount)} />
      <StatCard label={t('stats.flagged')} value={String(flaggedCount)} />
      <StatCard label={t('stats.avgAge')} value={ageValue} />
    </div>
  );
}
