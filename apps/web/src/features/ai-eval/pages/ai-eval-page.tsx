import { RefreshCw, ExternalLink } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { useAiEvalHistory, useAiEvalLatest } from '../api/ai-eval';

const VERDICTS = ['scam', 'suspicious', 'safe', 'unknown'] as const;
type Verdict = (typeof VERDICTS)[number];
const TYPES = ['phone', 'url', 'text'] as const;

function pct(n: number): string {
  return (n * 100).toFixed(1) + '%';
}

function shortSha(sha: string | null): string {
  return sha ? sha.slice(0, 7) : '—';
}

function relativeTime(iso: string): string {
  const ms = Date.now() - new Date(iso).getTime();
  const h = Math.floor(ms / 3_600_000);
  if (h < 1) return 'just now';
  if (h < 24) return `${h}h ago`;
  const d = Math.floor(h / 24);
  return `${d}d ago`;
}

export default function AiEvalPage() {
  const { t } = useTranslation();
  const latestQ = useAiEvalLatest();
  const historyQ = useAiEvalHistory(30);

  const refresh = () => {
    latestQ.refetch();
    historyQ.refetch();
  };

  if (latestQ.isLoading || historyQ.isLoading) {
    return (
      <div className="p-8 text-sm text-muted-foreground">
        {t('common.loading')}
      </div>
    );
  }

  if (latestQ.isError || historyQ.isError) {
    return (
      <div className="p-8 text-sm text-destructive">
        Could not load AI eval data.{' '}
        <Button variant="link" size="sm" onClick={refresh}>
          {t('common.retry')}
        </Button>
      </div>
    );
  }

  const summary = latestQ.data?.summary ?? null;
  const history = historyQ.data?.entries ?? [];

  return (
    <div className="mx-auto max-w-6xl px-6 py-8">
      <div className="mb-6 flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">AI accuracy</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            Nightly headless eval against {summary?.totalCases ?? '—'} labelled
            cases. Drives the cron drift alarm.
          </p>
        </div>
        <Button variant="outline" size="sm" onClick={refresh}>
          <RefreshCw className="mr-2 size-4" />
          Refresh
        </Button>
      </div>

      {!summary ? <EmptyState /> : <Overview summary={summary} />}

      {history.length > 0 && <TrendCard history={history} />}

      {summary && (
        <>
          <PerTypeCard summary={summary} />
          <ConfusionCard summary={summary} />
          <FailingCases summary={summary} />
        </>
      )}
    </div>
  );
}

function EmptyState() {
  return (
    <Card className="mb-6">
      <CardContent className="p-8 text-center text-sm text-muted-foreground">
        <p className="mb-3 font-medium text-foreground">
          No eval results yet.
        </p>
        <p className="mb-4">
          The nightly cron runs at 02:00 UTC and writes results to{' '}
          <code className="rounded bg-muted px-1.5 py-0.5 text-xs">
            apps/api/eval/latest.json
          </code>
          .
        </p>
        <a
          href="https://github.com/CSC234-UserCenteredMobileApp/ScamReport/actions/workflows/ai-eval.yml"
          target="_blank"
          rel="noreferrer"
          className="inline-flex items-center gap-1 text-primary hover:underline"
        >
          Trigger workflow on GitHub
          <ExternalLink className="size-3" />
        </a>
      </CardContent>
    </Card>
  );
}

type Summary = NonNullable<
  ReturnType<typeof useAiEvalLatest>['data']
>['summary'];

function Overview({ summary }: { summary: NonNullable<Summary> }) {
  return (
    <Card className="mb-6">
      <CardContent className="grid grid-cols-2 gap-6 p-6 md:grid-cols-5">
        <Metric label="Verdict accuracy" value={pct(summary.verdictAccuracy)}>
          <Badge variant={summary.passed ? 'default' : 'destructive'}>
            {summary.passed ? 'PASS' : 'FAIL'}
          </Badge>
        </Metric>
        <Metric label="Recall @ 1" value={pct(summary.scammerRecallAt1)} />
        <Metric label="MRR" value={summary.mrr.toFixed(3)} />
        <Metric label="p95 latency" value={`${summary.p95LatencyMs} ms`} />
        <Metric
          label="Last run"
          value={relativeTime(summary.runAt)}
          sub={`${shortSha(summary.gitSha)} · threshold ${pct(summary.threshold)}`}
        />
      </CardContent>
    </Card>
  );
}

function Metric({
  label,
  value,
  sub,
  children,
}: {
  label: string;
  value: string;
  sub?: string;
  children?: React.ReactNode;
}) {
  return (
    <div className="flex flex-col gap-1">
      <div className="text-xs uppercase tracking-wide text-muted-foreground">
        {label}
      </div>
      <div className="text-2xl font-semibold tabular-nums">{value}</div>
      {sub && <div className="text-xs text-muted-foreground">{sub}</div>}
      {children}
    </div>
  );
}

function TrendCard({
  history,
}: {
  history: NonNullable<
    ReturnType<typeof useAiEvalHistory>['data']
  >['entries'];
}) {
  const w = 600;
  const h = 80;
  const padX = 8;
  const padY = 8;
  const xs = history.map(
    (_, i) =>
      padX + (i / Math.max(1, history.length - 1)) * (w - 2 * padX),
  );
  const ys = history.map(
    (e) => h - padY - e.verdictAccuracy * (h - 2 * padY),
  );
  const path = xs.map((x, i) => `${i === 0 ? 'M' : 'L'} ${x} ${ys[i]}`).join(' ');
  const min = Math.min(...history.map((e) => e.verdictAccuracy));
  const max = Math.max(...history.map((e) => e.verdictAccuracy));
  const last = history[history.length - 1]!;

  return (
    <Card className="mb-6">
      <CardHeader>
        <CardTitle className="text-base">Accuracy trend (last {history.length} runs)</CardTitle>
      </CardHeader>
      <CardContent>
        <svg
          viewBox={`0 0 ${w} ${h}`}
          className="h-20 w-full"
          role="img"
          aria-label="Verdict accuracy trend over recent runs"
        >
          <path
            d={path}
            fill="none"
            stroke="hsl(var(--primary))"
            strokeWidth={1.5}
          />
          {xs.map((x, i) => (
            <circle
              key={i}
              cx={x}
              cy={ys[i]}
              r={2}
              fill={
                history[i]!.passed
                  ? 'hsl(var(--primary))'
                  : 'hsl(var(--destructive))'
              }
            />
          ))}
        </svg>
        <div className="mt-2 flex justify-between text-xs text-muted-foreground tabular-nums">
          <span>min {pct(min)}</span>
          <span>
            latest {pct(last.verdictAccuracy)} ·{' '}
            {new Date(last.runAt).toLocaleDateString()}
          </span>
          <span>max {pct(max)}</span>
        </div>
      </CardContent>
    </Card>
  );
}

function PerTypeCard({ summary }: { summary: NonNullable<Summary> }) {
  return (
    <Card className="mb-6">
      <CardHeader>
        <CardTitle className="text-base">Per-type accuracy</CardTitle>
      </CardHeader>
      <CardContent className="p-0">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Type</TableHead>
              <TableHead className="text-right">n</TableHead>
              <TableHead className="text-right">Verdict</TableHead>
              <TableHead className="text-right">Recall @ 1</TableHead>
              <TableHead className="text-right">MRR</TableHead>
              <TableHead className="text-right">p95 ms</TableHead>
              <TableHead className="w-48">Bar</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {TYPES.map((tt) => {
              const m = summary.byType[tt];
              return (
                <TableRow key={tt}>
                  <TableCell className="font-medium">{tt}</TableCell>
                  <TableCell className="text-right tabular-nums">
                    {m.n}
                  </TableCell>
                  <TableCell className="text-right tabular-nums">
                    {pct(m.verdictAccuracy)}
                  </TableCell>
                  <TableCell className="text-right tabular-nums">
                    {pct(m.scammerRecallAt1)}
                  </TableCell>
                  <TableCell className="text-right tabular-nums">
                    {m.mrr.toFixed(3)}
                  </TableCell>
                  <TableCell className="text-right tabular-nums">
                    {m.p95LatencyMs}
                  </TableCell>
                  <TableCell>
                    <div className="h-2 w-40 overflow-hidden rounded bg-muted">
                      <div
                        className="h-full bg-primary"
                        style={{ width: `${m.verdictAccuracy * 100}%` }}
                      />
                    </div>
                  </TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  );
}

function ConfusionCard({ summary }: { summary: NonNullable<Summary> }) {
  const m = summary.confusionMatrix;
  const max = Math.max(
    1,
    ...VERDICTS.flatMap((exp) => VERDICTS.map((act) => m[exp][act])),
  );
  return (
    <Card className="mb-6">
      <CardHeader>
        <CardTitle className="text-base">
          Confusion matrix
        </CardTitle>
        <p className="text-xs text-muted-foreground">
          Rows = expected, columns = actual. Diagonal = correct.
        </p>
      </CardHeader>
      <CardContent>
        <div className="overflow-x-auto">
          <table className="w-full text-sm tabular-nums">
            <thead>
              <tr className="text-muted-foreground">
                <th className="px-2 py-1 text-left font-normal"></th>
                {VERDICTS.map((act) => (
                  <th key={act} className="px-2 py-1 text-right font-medium">
                    {act}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {VERDICTS.map((exp) => (
                <tr key={exp} className="border-t">
                  <td className="px-2 py-1 font-medium">{exp}</td>
                  {VERDICTS.map((act) => {
                    const n = m[exp as Verdict][act as Verdict];
                    const diag = exp === act;
                    const intensity = n === 0 ? 0 : Math.min(1, n / max);
                    return (
                      <td
                        key={act}
                        className="px-2 py-1 text-right"
                        style={{
                          backgroundColor:
                            n === 0
                              ? undefined
                              : diag
                                ? `hsl(var(--primary) / ${0.05 + intensity * 0.25})`
                                : `hsl(var(--destructive) / ${0.05 + intensity * 0.25})`,
                        }}
                      >
                        {n}
                      </td>
                    );
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </CardContent>
    </Card>
  );
}

function FailingCases({ summary }: { summary: NonNullable<Summary> }) {
  const fails = summary.results.filter((r) => !r.verdictHit);
  return (
    <Card className="mb-6">
      <CardHeader>
        <CardTitle className="text-base">
          Failing cases ({fails.length})
        </CardTitle>
      </CardHeader>
      <CardContent className="p-0">
        {fails.length === 0 ? (
          <div className="p-6 text-sm text-muted-foreground">
            All cases passed.
          </div>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Label</TableHead>
                <TableHead>Type</TableHead>
                <TableHead>Expected</TableHead>
                <TableHead>Actual</TableHead>
                <TableHead>Tags</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {fails.map((r) => (
                <TableRow key={r.label}>
                  <TableCell className="font-medium">{r.label}</TableCell>
                  <TableCell>{r.inputType}</TableCell>
                  <TableCell>
                    <Badge variant={r.expectedVerdict as Verdict}>
                      {r.expectedVerdict}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <Badge variant={r.actualVerdict as Verdict}>
                      {r.actualVerdict}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-xs text-muted-foreground">
                    {r.tags.join(', ') || '—'}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </CardContent>
    </Card>
  );
}
