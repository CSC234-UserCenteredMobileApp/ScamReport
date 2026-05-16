import { Link, useParams } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { useScammerDossier } from '../api/dossier';

// Per-scammer dossier — printable authority handoff. The page is intentionally
// long-form and prose-friendly so `window.print()` produces something useful
// without server-side PDF generation.
export default function ScammerDossierPage() {
  const params = useParams<{ id: string }>();
  const id = params.id ?? '';
  const { data, isLoading, isError } = useScammerDossier(id);

  if (isLoading) {
    return <div className="p-8 text-sm text-muted-foreground">Loading dossier…</div>;
  }
  if (isError || !data) {
    return <div className="p-8 text-sm text-destructive">Could not load dossier.</div>;
  }

  return (
    <div className="mx-auto max-w-4xl px-6 py-8 print:px-0 print:py-0">
      <div className="mb-6 flex items-center justify-between print:hidden">
        <h1 className="text-2xl font-semibold">Scammer Dossier</h1>
        <Button onClick={() => window.print()} variant="outline">
          Print / Export PDF
        </Button>
      </div>

      <header className="border-b pb-4">
        <h2 className="text-xl font-bold">{data.scammer.displayName}</h2>
        {data.scammer.suspectedName && (
          <div className="mt-1 text-sm">
            <span className="text-muted-foreground">Alleged name:</span>{' '}
            <strong className="text-foreground">{data.scammer.suspectedName}</strong>
          </div>
        )}
        {data.scammer.person && (
          <div className="mt-1 text-sm">
            <span className="text-muted-foreground">Person:</span>{' '}
            <Link
              to={`/persons/${data.scammer.person.id}/dossier`}
              className="text-primary underline"
            >
              {data.scammer.person.fullName}
            </Link>
            <span className="text-muted-foreground">
              {' '}({data.scammer.person.campaignCount} campaigns)
            </span>
          </div>
        )}
        <div className="mt-1 text-sm text-muted-foreground">
          Risk: <strong className="text-foreground">{data.scammer.riskLevel}</strong> ·
          {' '}Cases: <strong className="text-foreground">{data.scammer.reportCount}</strong> ·
          {' '}Generated: {new Date(data.generatedAt).toLocaleString()}
        </div>
        {data.scammer.aliases.length > 0 && (
          <div className="mt-1 text-sm">
            <span className="text-muted-foreground">Aliases:</span>{' '}
            {data.scammer.aliases.join(', ')}
          </div>
        )}
        {data.scammer.notes && (
          <p className="mt-3 text-sm">{data.scammer.notes}</p>
        )}
      </header>

      <section className="mt-6">
        <h3 className="font-semibold">Identifiers</h3>
        <table className="mt-2 w-full text-sm">
          <thead className="text-left text-muted-foreground">
            <tr>
              <th className="py-1">Kind</th>
              <th className="py-1">Value</th>
              <th className="py-1">Normalised</th>
            </tr>
          </thead>
          <tbody>
            {data.scammer.identifiers.map((id) => (
              <tr key={id.id} className="border-t">
                <td className="py-1 capitalize">{id.kind.replace('_', ' ')}</td>
                <td className="py-1">{id.valueRaw}</td>
                <td className="py-1 font-mono text-xs">{id.valueNormalized}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section className="mt-6">
        <h3 className="font-semibold">Aggregate</h3>
        <ul className="mt-2 grid grid-cols-2 gap-2 text-sm sm:grid-cols-4">
          <li>Total cases: <strong>{data.aggregates.totalCases}</strong></li>
          <li>Verified: <strong>{data.aggregates.verifiedCases}</strong></li>
          <li>Pending: <strong>{data.aggregates.pendingCases}</strong></li>
          <li>Rejected: <strong>{data.aggregates.rejectedCases}</strong></li>
          <li>Distinct reporters: <strong>{data.aggregates.distinctReporters}</strong></li>
          <li>Avg AI score: <strong>{data.aiStats.avgAiScore ?? '—'}</strong></li>
          <li>High-conf cases: <strong>{data.aiStats.highCount}</strong></li>
          <li>Last AI score: <strong>{data.aiStats.lastAiScore ?? '—'}</strong></li>
        </ul>
      </section>

      <section className="mt-6">
        <h3 className="font-semibold">Linked cases ({data.cases.length})</h3>
        {data.cases.length === 0 ? (
          <p className="mt-2 text-sm text-muted-foreground">No linked cases yet.</p>
        ) : (
          <ul className="mt-2 space-y-4">
            {data.cases.map((c) => (
              <li key={c.id} className="rounded-md border p-3">
                <div className="flex items-baseline justify-between gap-2">
                  <strong>{c.title}</strong>
                  <span className="text-xs text-muted-foreground capitalize">{c.status}</span>
                </div>
                <div className="mt-1 text-xs text-muted-foreground">
                  {c.scamTypeLabelEn} · target: {c.targetIdentifier ?? '—'} ·
                  {' '}AI: {c.aiScore ?? '—'} ({c.aiConfidence ?? '—'})
                </div>
                <p className="mt-2 text-sm">{c.description}</p>
                {c.evidenceFiles.length > 0 && (
                  <ul className="mt-2 flex flex-wrap gap-2">
                    {c.evidenceFiles.map((f) => (
                      <li
                        key={f.id}
                        className="rounded border bg-muted px-2 py-1 text-xs"
                      >
                        {f.kind} · {f.mimeType}
                        {f.signedUrl && (
                          <a
                            href={f.signedUrl}
                            target="_blank"
                            rel="noreferrer"
                            className="ml-2 underline"
                          >
                            view
                          </a>
                        )}
                      </li>
                    ))}
                  </ul>
                )}
              </li>
            ))}
          </ul>
        )}
      </section>

      <section className="mt-6">
        <h3 className="font-semibold">Recent /check hits (last 30 days)</h3>
        {data.recentCheckHits.length === 0 ? (
          <p className="mt-2 text-sm text-muted-foreground">No recent verdict checks.</p>
        ) : (
          <table className="mt-2 w-full text-sm">
            <thead className="text-left text-muted-foreground">
              <tr>
                <th>When</th>
                <th>Input</th>
                <th>Verdict</th>
                <th>Matches</th>
              </tr>
            </thead>
            <tbody>
              {data.recentCheckHits.map((h, i) => (
                <tr key={i} className="border-t">
                  <td className="py-1">{new Date(h.createdAt).toLocaleString()}</td>
                  <td className="py-1 font-mono text-xs">{h.inputNormalized}</td>
                  <td className="py-1 capitalize">{h.verdict}</td>
                  <td className="py-1">{h.matchCount}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </div>
  );
}
