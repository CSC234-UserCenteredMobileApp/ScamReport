import { subDays, format as fnsFormat } from 'date-fns';
import { RefreshCw } from 'lucide-react';
import { useState } from 'react';
import { Link } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { downloadPdf } from '@/lib/api/download-pdf';
import { usePlatformSummary } from '../api/summary';

const toDateStr = (d: Date) => fnsFormat(d, 'yyyy-MM-dd');
const defaultFrom = toDateStr(subDays(new Date(), 30));
const defaultTo = toDateStr(new Date());

// Platform-wide summary — print-friendly digest for hand-off to authority /
// internal review. Default window = last 30 days.
export default function PlatformSummaryPage() {
  const [from, setFrom] = useState(defaultFrom);
  const [to, setTo] = useState(defaultTo);
  const [applied, setApplied] = useState<{ from: string; to: string }>({
    from: defaultFrom,
    to: defaultTo,
  });

  const { data, isLoading, isError, refetch } = usePlatformSummary(
    applied.from ? `${applied.from}T00:00:00Z` : undefined,
    applied.to ? `${applied.to}T23:59:59Z` : undefined,
  );

  if (isLoading) return <div className="p-8 text-sm text-muted-foreground">Loading…</div>;
  if (isError || !data) return <div className="p-8 text-sm text-destructive">Could not load summary.</div>;

  const rangeLabel = `${new Date(data.range.from).toLocaleDateString()} – ${new Date(data.range.to).toLocaleDateString()}`;

  return (
    <div className="mx-auto max-w-5xl px-6 py-8">
      <div className="mb-6 flex flex-wrap items-center justify-between gap-4">
        <h1 className="text-2xl font-semibold">Platform Summary</h1>
        <div className="flex flex-wrap items-end gap-3">
          <div className="flex flex-col gap-1">
            <Label htmlFor="summary-from" className="text-xs text-muted-foreground">From</Label>
            <Input
              id="summary-from"
              type="date"
              value={from}
              max={to}
              onChange={(e) => setFrom(e.target.value)}
              className="h-8 w-38 text-sm"
            />
          </div>
          <div className="flex flex-col gap-1">
            <Label htmlFor="summary-to" className="text-xs text-muted-foreground">To</Label>
            <Input
              id="summary-to"
              type="date"
              value={to}
              min={from}
              max={toDateStr(new Date())}
              onChange={(e) => setTo(e.target.value)}
              className="h-8 w-38 text-sm"
            />
          </div>
          <Button
            size="sm"
            variant="secondary"
            onClick={() => setApplied({ from, to })}
            disabled={!from || !to}
          >
            Apply
          </Button>
          <Button
            size="icon"
            variant="ghost"
            className="size-8"
            aria-label="Refresh"
            onClick={() => void refetch()}
          >
            <RefreshCw className="size-4" />
          </Button>
          <Button
            onClick={() =>
              downloadPdf(
                '/admin/reports/platform-summary/pdf',
                'scamreport-platform-summary.pdf',
              )
            }
            variant="outline"
            size="sm"
          >
            Export PDF
          </Button>
        </div>
      </div>

      <header className="border-b pb-3 text-sm text-muted-foreground">
        Window: <strong className="text-foreground">{rangeLabel}</strong> ·
        {' '}Generated {new Date(data.generatedAt).toLocaleString()}
      </header>

      <section className="mt-6 grid grid-cols-2 gap-4 sm:grid-cols-5">
        <Stat label="Total reports" value={data.reports.total} />
        <Stat label="Verified" value={data.reports.verified} />
        <Stat label="Pending" value={data.reports.pending} />
        <Stat label="Rejected" value={data.reports.rejected} />
        <Stat label="Flagged" value={data.reports.flagged} />
      </section>

      <section className="mt-8 grid gap-6 lg:grid-cols-2">
        <div>
          <h3 className="font-semibold">Scam type breakdown</h3>
          {data.scamTypeBreakdown.length === 0 ? (
            <p className="mt-2 text-sm text-muted-foreground">No data.</p>
          ) : (
            <table className="mt-2 w-full text-sm">
              <thead className="text-left text-muted-foreground">
                <tr>
                  <th>Type</th>
                  <th className="text-right">Count</th>
                </tr>
              </thead>
              <tbody>
                {data.scamTypeBreakdown.map((s) => (
                  <tr key={s.scamTypeCode} className="border-t">
                    <td className="py-1">{s.labelEn}</td>
                    <td className="py-1 text-right">{s.count}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        <div>
          <h3 className="font-semibold">Top scammers</h3>
          {data.topScammers.length === 0 ? (
            <p className="mt-2 text-sm text-muted-foreground">No data.</p>
          ) : (
            <table className="mt-2 w-full text-sm">
              <thead className="text-left text-muted-foreground">
                <tr>
                  <th>Name</th>
                  <th>Risk</th>
                  <th className="text-right">Reports</th>
                </tr>
              </thead>
              <tbody>
                {data.topScammers.map((s) => (
                  <tr key={s.id} className="border-t">
                    <td className="py-1">
                      <Link
                        to={`/scammers/${s.id}/dossier`}
                        className="text-primary underline"
                      >
                        {s.displayName}
                      </Link>
                      {s.suspectedName && (
                        <div className="text-xs text-muted-foreground">
                          Alleged: {s.suspectedName}
                        </div>
                      )}
                    </td>
                    <td className="py-1 capitalize">{s.riskLevel}</td>
                    <td className="py-1 text-right">{s.reportCount}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        <div>
          <h3 className="font-semibold">Top identifiers</h3>
          {data.topIdentifiers.length === 0 ? (
            <p className="mt-2 text-sm text-muted-foreground">No data.</p>
          ) : (
            <table className="mt-2 w-full text-sm">
              <thead className="text-left text-muted-foreground">
                <tr>
                  <th>Kind</th>
                  <th>Value</th>
                  <th className="text-right">Reports</th>
                </tr>
              </thead>
              <tbody>
                {data.topIdentifiers.map((id, i) => (
                  <tr key={i} className="border-t">
                    <td className="py-1 capitalize">{id.kind}</td>
                    <td className="py-1 font-mono text-xs">{id.valueNormalized}</td>
                    <td className="py-1 text-right">{id.reportCount}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        <div>
          <h3 className="font-semibold">/check verdict mix</h3>
          <div className="mt-2 text-sm">
            <p>Total calls: <strong>{data.checkLogs.total}</strong></p>
            <ul className="mt-1">
              <li>Scam: <strong>{data.checkLogs.verdictMix.scam}</strong></li>
              <li>Suspicious: <strong>{data.checkLogs.verdictMix.suspicious}</strong></li>
              <li>Safe: <strong>{data.checkLogs.verdictMix.safe}</strong></li>
              <li>Unknown: <strong>{data.checkLogs.verdictMix.unknown}</strong></li>
            </ul>
          </div>
        </div>
      </section>
    </div>
  );
}

function Stat({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-md border p-3">
      <div className="text-xs text-muted-foreground">{label}</div>
      <div className="mt-1 text-2xl font-bold tabular-nums">{value}</div>
    </div>
  );
}
