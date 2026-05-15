import { useEvalRuns, useRunEvaluation } from '../api/runs';
import { Button } from '@/components/ui/button';

export default function AiEvalPage() {
  const { data, isLoading, isError } = useEvalRuns();
  const runMutation = useRunEvaluation();

  return (
    <div className="mx-auto max-w-5xl px-6 py-8">
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold">AI Accuracy Evaluation</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            Runs every labelled case through /check + Ask AI and reports
            verdict accuracy, scammer recall, and missing-facts F1.
          </p>
        </div>
        <Button
          onClick={() => runMutation.mutate()}
          disabled={runMutation.isPending}
        >
          {runMutation.isPending ? 'Running…' : 'Run evaluation now'}
        </Button>
      </div>

      {runMutation.isError && (
        <div className="mb-4 rounded-md border border-destructive bg-destructive/10 p-3 text-sm">
          Evaluation failed. Check server logs for details.
        </div>
      )}

      {isLoading ? (
        <div className="text-sm text-muted-foreground">Loading…</div>
      ) : isError ? (
        <div className="text-sm text-destructive">Could not load runs.</div>
      ) : data && data.items.length === 0 ? (
        <div className="rounded-md border bg-muted p-6 text-sm text-muted-foreground">
          No evaluation runs yet. Click <strong>Run evaluation now</strong> to start.
        </div>
      ) : (
        <table className="w-full text-sm">
          <thead className="text-left text-muted-foreground">
            <tr className="border-b">
              <th className="py-2">Run at</th>
              <th className="py-2 text-right">Cases</th>
              <th className="py-2 text-right">Verdict acc.</th>
              <th className="py-2 text-right">Scammer R@1</th>
              <th className="py-2 text-right">MRR</th>
              <th className="py-2 text-right">F1</th>
              <th className="py-2 text-right">p95 ms</th>
            </tr>
          </thead>
          <tbody>
            {data?.items.map((r) => (
              <tr key={r.id} className="border-b">
                <td className="py-2">{new Date(r.runAt).toLocaleString()}</td>
                <td className="py-2 text-right tabular-nums">{r.totalCases}</td>
                <td className="py-2 text-right tabular-nums">
                  {(r.verdictAccuracy * 100).toFixed(1)}%
                </td>
                <td className="py-2 text-right tabular-nums">
                  {(r.scammerRecallAt1 * 100).toFixed(1)}%
                </td>
                <td className="py-2 text-right tabular-nums">{r.scammerMrr.toFixed(2)}</td>
                <td className="py-2 text-right tabular-nums">{r.missingFactsF1.toFixed(2)}</td>
                <td className="py-2 text-right tabular-nums">{r.p95LatencyMs}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
