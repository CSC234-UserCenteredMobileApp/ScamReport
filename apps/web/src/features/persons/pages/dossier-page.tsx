import { Link, useParams } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { downloadPdf } from '@/lib/api/download-pdf';
import { usePersonDossier } from '../api/dossier';

// Per-Person dossier — aggregates every scammer campaign attributed to one
// human offender. Printable for authority handoff.
export default function PersonDossierPage() {
  const params = useParams<{ id: string }>();
  const id = params.id ?? '';
  const { data, isLoading, isError } = usePersonDossier(id);

  if (isLoading) {
    return <div className="p-8 text-sm text-muted-foreground">Loading dossier…</div>;
  }
  if (isError || !data) {
    return <div className="p-8 text-sm text-destructive">Could not load dossier.</div>;
  }

  return (
    <div className="mx-auto max-w-4xl px-6 py-8 print:px-0 print:py-0">
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-semibold">Person Dossier</h1>
        <Button
          onClick={() =>
            downloadPdf(
              `/admin/persons/${id}/pdf`,
              `scamreport-person-${id.replace(/-/g, '').slice(0, 8)}.pdf`,
            )
          }
          variant="outline"
        >
          Export PDF
        </Button>
      </div>

      <header className="border-b pb-4">
        <h2 className="text-xl font-bold">{data.person.fullName}</h2>
        <div className="mt-1 text-sm text-muted-foreground">
          Risk: <strong className="text-foreground">{data.person.riskLevel}</strong> ·
          {' '}Campaigns: <strong className="text-foreground">{data.person.campaignCount}</strong> ·
          {' '}Cases: <strong className="text-foreground">{data.person.reportCount}</strong> ·
          {' '}Generated: {new Date(data.generatedAt).toLocaleString()}
        </div>
        {data.person.aliases.length > 0 && (
          <div className="mt-1 text-sm">
            <span className="text-muted-foreground">Aliases:</span>{' '}
            {data.person.aliases.join(', ')}
          </div>
        )}
        {data.person.notes && (
          <p className="mt-3 text-sm">{data.person.notes}</p>
        )}
      </header>

      <section className="mt-6">
        <h3 className="font-semibold">Campaigns attributed to this person</h3>
        {data.campaigns.length === 0 ? (
          <p className="mt-2 text-sm text-muted-foreground">No campaigns linked.</p>
        ) : (
          <table className="mt-2 w-full text-sm">
            <thead className="text-left text-muted-foreground">
              <tr>
                <th className="py-1">Campaign</th>
                <th className="py-1">Risk</th>
                <th className="py-1">Top scam types</th>
                <th className="py-1 text-right">Cases</th>
              </tr>
            </thead>
            <tbody>
              {data.campaigns.map((c) => (
                <tr key={c.id} className="border-t align-top">
                  <td className="py-1">
                    <Link
                      to={`/scammers/${c.id}/dossier`}
                      className="text-primary underline"
                    >
                      {c.displayName}
                    </Link>
                    {c.suspectedName && (
                      <div className="text-xs text-muted-foreground">
                        Alleged: {c.suspectedName}
                      </div>
                    )}
                  </td>
                  <td className="py-1 capitalize">{c.riskLevel}</td>
                  <td className="py-1">{c.topScamTypeCodes.join(', ') || '—'}</td>
                  <td className="py-1 text-right">{c.reportCount}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section className="mt-6 text-xs text-muted-foreground print:mt-12">
        <p>
          Person dossier compiled by ScamReport on{' '}
          {new Date(data.generatedAt).toLocaleString()} for authority handoff.
          Information based on user-submitted reports and AI matching; treat
          all attributions as alleged until corroborated.
        </p>
      </section>
    </div>
  );
}
