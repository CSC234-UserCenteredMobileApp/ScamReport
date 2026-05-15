import { Link } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { usePlatformSummary } from '../api/summary';

// Platform-wide summary — print-friendly digest for hand-off to authority /
// internal review. Default window = last 30 days; the API derives the
// timestamps when from/to are omitted.
export default function PlatformSummaryPage() {
  const { data, isLoading, isError } = usePlatformSummary();

  if (isLoading) return <div className="p-8 text-sm text-muted-foreground">Loading…</div>;
  if (isError || !data) return <div className="p-8 text-sm text-destructive">Could not load summary.</div>;

  const rangeLabel = `${new Date(data.range.from).toLocaleDateString()} – ${new Date(data.range.to).toLocaleDateString()}`;

  return (
    <div className="mx-auto max-w-5xl px-6 py-8 print:px-0 print:py-0">
      <div className="mb-6 flex items-center justify-between print:hidden">
        <h1 className="text-2xl font-semibold">Platform Summary</h1>
        <Button onClick={() => window.print()} variant="outline">
          Print / Export PDF
        </Button>
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

        <div>
          <h3 className="font-semibold">AI score distribution</h3>
          <ul className="mt-2 text-sm">
            <li>High confidence: <strong>{data.aiScoreDistribution.high}</strong></li>
            <li>Medium: <strong>{data.aiScoreDistribution.medium}</strong></li>
            <li>Low: <strong>{data.aiScoreDistribution.low}</strong></li>
            <li>Unknown / pending: <strong>{data.aiScoreDistribution.unknown}</strong></li>
          </ul>
        </div>

        <div>
          <h3 className="font-semibold">Latest AI eval</h3>
          {data.latestEval ? (
            <ul className="mt-2 text-sm">
              <li>Run at: <strong>{new Date(data.latestEval.runAt).toLocaleString()}</strong></li>
              <li>Verdict accuracy: <strong>{(data.latestEval.verdictAccuracy * 100).toFixed(1)}%</strong></li>
              <li>Scammer recall@1: <strong>{(data.latestEval.scammerRecallAt1 * 100).toFixed(1)}%</strong></li>
              <li>Scammer MRR: <strong>{data.latestEval.scammerMrr.toFixed(2)}</strong></li>
              <li>Missing-facts F1: <strong>{data.latestEval.missingFactsF1.toFixed(2)}</strong></li>
              <li>p95 latency: <strong>{data.latestEval.p95LatencyMs} ms</strong></li>
            </ul>
          ) : (
            <p className="mt-2 text-sm text-muted-foreground">
              No evaluation run yet. <Link to="/ai-eval" className="text-primary underline">Run now →</Link>
            </p>
          )}
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
