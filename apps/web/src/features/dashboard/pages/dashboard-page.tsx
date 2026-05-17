import { differenceInHours } from 'date-fns';
import { ClipboardList, Flag, ShieldCheck } from 'lucide-react';
import { useMemo } from 'react';
import { Link } from 'react-router-dom';
import { Card, CardContent } from '@/components/ui/card';
import { PageHeader } from '@/components/page-header';
import { useQueue } from '@/features/moderation/api/queue';

function StatCard({
  icon: Icon,
  label,
  value,
  to,
  color,
}: {
  icon: React.ComponentType<{ className?: string }>;
  label: string;
  value: number | string;
  to: string;
  color: string;
}) {
  return (
    <Link to={to} className="block">
      <Card className="transition-shadow hover:shadow-md">
        <CardContent className="flex items-center gap-4 p-5">
          <div className={`rounded-lg p-2 ${color}`}>
            <Icon className="size-5" />
          </div>
          <div>
            <p className="text-xs uppercase tracking-wide text-muted-foreground">{label}</p>
            <p className="text-2xl font-bold tabular-nums">{value}</p>
          </div>
        </CardContent>
      </Card>
    </Link>
  );
}

export function DashboardPage() {
  const { data: queueData } = useQueue();

  const avgAgeHours = useMemo(() => {
    if (!queueData || queueData.items.length === 0) return null;
    const total = queueData.items.reduce(
      (sum, it) => sum + differenceInHours(new Date(), new Date(it.submittedAt)),
      0,
    );
    return Math.round(total / queueData.items.length);
  }, [queueData]);

  return (
    <div className="space-y-8">
      <PageHeader
        title="Dashboard"
        subtitle="Platform at a glance."
      />

      <section>
        <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-muted-foreground">
          Moderation
        </h2>
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
          <StatCard
            icon={ClipboardList}
            label="Pending"
            value={queueData?.pendingCount ?? '—'}
            to="/moderation"
            color="bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400"
          />
          <StatCard
            icon={Flag}
            label="Flagged"
            value={queueData?.flaggedCount ?? '—'}
            to="/moderation"
            color="bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400"
          />
          <StatCard
            icon={ShieldCheck}
            label="Avg age (h)"
            value={avgAgeHours !== null ? avgAgeHours : '—'}
            to="/moderation"
            color="bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400"
          />
        </div>
      </section>

      {queueData && queueData.items.length > 0 && (
        <section>
          <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-muted-foreground">
            Oldest pending reports
          </h2>
          <ul className="divide-y rounded-lg border bg-card text-sm">
            {queueData.items
              .filter((it) => it.status === 'pending')
              .slice(0, 5)
              .map((item) => (
                <li key={item.id}>
                  <Link
                    to={`/moderation/${item.id}`}
                    className="flex items-center justify-between gap-4 px-4 py-3 hover:bg-muted/50"
                  >
                    <span className="line-clamp-1 flex-1 font-medium">{item.title}</span>
                    <span className="shrink-0 text-xs text-muted-foreground">
                      {differenceInHours(new Date(), new Date(item.submittedAt))}h ago
                    </span>
                  </Link>
                </li>
              ))}
          </ul>
        </section>
      )}
    </div>
  );
}
