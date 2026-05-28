import { differenceInHours } from 'date-fns';
import { ClipboardList, Flag, ShieldCheck } from 'lucide-react';
import { useMemo } from 'react';
import { Link } from 'react-router-dom';
import { PageHeader } from '@/components/page-header';
import { KpiTile } from '@/components/kpi-tile';
import { useQueue } from '@/features/moderation/api/queue';
import { ScamOverviewSection } from '@/features/scam-overview/components/scam-overview-section';

export function DashboardPage() {
  const { data: queueData } = useQueue({ page: 1, page_size: 25 });

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
      <PageHeader title="Dashboard" subtitle="Platform at a glance." />

      <section>
        <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-muted-foreground">
          Moderation
        </h2>
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-3">
          <KpiTile
            icon={ClipboardList}
            label="Pending"
            value={queueData?.pendingCount ?? '—'}
            to="/moderation"
            tone="warn"
          />
          <KpiTile
            icon={Flag}
            label="Flagged"
            value={queueData?.flaggedCount ?? '—'}
            to="/moderation"
            tone="alert"
          />
          <KpiTile
            icon={ShieldCheck}
            label="Avg age (h)"
            value={avgAgeHours !== null ? avgAgeHours : '—'}
            to="/moderation"
            tone="info"
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
                    <span className="line-clamp-1 flex-1 font-medium">
                      {item.title}
                    </span>
                    <span className="shrink-0 text-xs text-muted-foreground">
                      {differenceInHours(new Date(), new Date(item.submittedAt))}h
                      ago
                    </span>
                  </Link>
                </li>
              ))}
          </ul>
        </section>
      )}

      <ScamOverviewSection />
    </div>
  );
}
