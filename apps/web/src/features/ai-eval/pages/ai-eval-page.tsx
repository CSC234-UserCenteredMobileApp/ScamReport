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
import {
  Area,
  CartesianGrid,
  ComposedChart,
  Legend,
  Line,
  ReferenceLine,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import {
  ChartContainer,
  type ChartColumn,
} from '@/components/charts';
import { useFormat } from '@/lib/format';
import { cn } from '@/lib/utils';
import { useAiEvalHistory, useAiEvalLatest } from '../api/ai-eval';

const VERDICTS = ['scam', 'suspicious', 'safe', 'unknown'] as const;
type Verdict = (typeof VERDICTS)[number];
const TYPES = ['phone', 'url', 'text'] as const;

function shortSha(sha: string | null): string {
  return sha ? sha.slice(0, 7) : '—';
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
          <RefreshCw className="mr-2 size-4" aria-hidden="true" />
          Refresh
        </Button>
      </div>

      {!summary ? <EmptyState /> : <Overview summary={summary} />}

      {history.length > 0 && (
        <TrendCard
          history={history}
          threshold={summary?.threshold ?? 0.9}
        />
      )}

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
          <ExternalLink className="size-3" aria-hidden="true" />
        </a>
      </CardContent>
    </Card>
  );
}

type Summary = NonNullable<
  ReturnType<typeof useAiEvalLatest>['data']
>['summary'];

function Overview({ summary }: { summary: NonNullable<Summary> }) {
  const fmt = useFormat();
  return (
    <Card className="mb-6">
      <CardContent className="grid grid-cols-2 gap-6 p-6 md:grid-cols-5">
        <Metric label="Verdict accuracy" value={fmt.percent(summary.verdictAccuracy)}>
          <Badge variant={summary.passed ? 'default' : 'destructive'}>
            {summary.passed ? 'PASS' : 'FAIL'}
          </Badge>
        </Metric>
        <Metric label="Recall @ 1" value={fmt.percent(summary.scammerRecallAt1)} />
        <Metric label="MRR" value={summary.mrr.toFixed(3)} />
        <Metric label="p95 latency" value={`${fmt.number(summary.p95LatencyMs)} ms`} />
        <Metric
          label="Last run"
          value={fmt.relative(summary.runAt)}
          sub={`${shortSha(summary.gitSha)} · threshold ${fmt.percent(summary.threshold)}`}
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
  threshold,
}: {
  history: NonNullable<
    ReturnType<typeof useAiEvalHistory>['data']
  >['entries'];
  threshold: number;
}) {
  const { t } = useTranslation();
  const fmt = useFormat();

  const chartData = history.map((e) => ({
    runAt: e.runAt,
    verdictAccuracy: e.verdictAccuracy,
    phone: e.byType.phone,
    url: e.byType.url,
    text: e.byType.text,
    passed: e.passed,
    gitSha: e.gitSha,
  }));

  const accs = history.map((e) => e.verdictAccuracy);
  const min = Math.min(...accs);
  const max = Math.max(...accs);
  const last = history[history.length - 1]!;

  const columns: ReadonlyArray<ChartColumn<(typeof history)[number]>> = [
    { key: 'runAt', label: t('charts.date'), format: (r) => fmt.dateTime(r.runAt) },
    {
      key: 'verdictAccuracy',
      label: t('aiEval.verdictAccuracy'),
      format: (r) => fmt.percent(r.verdictAccuracy),
    },
    {
      key: 'passed',
      label: t('charts.passFail'),
      format: (r) => (r.passed ? t('charts.pass') : t('charts.fail')),
    },
  ];

  return (
    <Card className="mb-6">
      <CardHeader>
        <CardTitle className="text-base">
          {t('aiEval.trendTitle', { count: history.length })}
        </CardTitle>
        <p className="text-xs text-muted-foreground">
          {t('aiEval.trendNote')}
        </p>
      </CardHeader>
      <CardContent>
        <ChartContainer
          title={t('aiEval.trendTitle', { count: history.length })}
          description={t('aiEval.trendNote')}
          data={history}
          columns={columns}
        >
          <div className="h-64 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <ComposedChart
                data={chartData}
                margin={{ top: 16, right: 24, bottom: 8, left: 0 }}
              >
                <defs>
                  <linearGradient id="trend-grad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="hsl(var(--primary))" stopOpacity={0.35} />
                    <stop offset="100%" stopColor="hsl(var(--primary))" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid
                  strokeDasharray="3 3"
                  stroke="hsl(var(--border))"
                  vertical={false}
                />
                <XAxis
                  dataKey="runAt"
                  tickFormatter={(v: string) => fmt.dateShort(v)}
                  stroke="hsl(var(--muted-foreground))"
                  fontSize={11}
                  minTickGap={24}
                />
                <YAxis
                  domain={[0.7, 1]}
                  ticks={[0.7, 0.8, 0.9, 1.0]}
                  tickFormatter={(v: number) => fmt.percent(v, { digits: 0 })}
                  stroke="hsl(var(--muted-foreground))"
                  fontSize={11}
                  width={40}
                />
                <Tooltip
                  content={(props) => (
                    <TrendTooltip {...props} fmt={fmt} t={t} />
                  )}
                />
                <Legend
                  iconSize={10}
                  wrapperStyle={{ fontSize: 11, paddingTop: 4 }}
                />
                <ReferenceLine
                  y={threshold}
                  stroke="hsl(var(--destructive))"
                  strokeDasharray="4 4"
                  label={{
                    value: t('charts.threshold', {
                      value: fmt.percent(threshold, { digits: 0 }),
                    }),
                    fill: 'hsl(var(--destructive))',
                    fontSize: 10,
                    position: 'insideTopRight',
                  }}
                />
                <Area
                  type="monotone"
                  dataKey="verdictAccuracy"
                  name={t('aiEval.verdictAccuracy')}
                  stroke="hsl(var(--primary))"
                  strokeWidth={2}
                  fill="url(#trend-grad)"
                  dot={<PassFailDot />}
                  activeDot={{ r: 5 }}
                />
                <Line
                  type="monotone"
                  dataKey="phone"
                  name="phone"
                  stroke="hsl(var(--verdict-safe-fg))"
                  strokeWidth={1.5}
                  dot={false}
                />
                <Line
                  type="monotone"
                  dataKey="url"
                  name="url"
                  stroke="hsl(var(--verdict-suspicious-fg))"
                  strokeWidth={1.5}
                  dot={false}
                />
                <Line
                  type="monotone"
                  dataKey="text"
                  name="text"
                  stroke="hsl(var(--verdict-scam-fg))"
                  strokeWidth={1.5}
                  dot={false}
                />
              </ComposedChart>
            </ResponsiveContainer>
          </div>
        </ChartContainer>

        <div className="mt-3 flex flex-wrap justify-between gap-3 text-xs text-muted-foreground tabular-nums">
          <span>
            min <span className="font-medium text-foreground">{fmt.percent(min)}</span>
          </span>
          <span>
            latest{' '}
            <span className="font-medium text-foreground">
              {fmt.percent(last.verdictAccuracy)}
            </span>{' '}
            · {fmt.dateShort(last.runAt)}
          </span>
          <span>
            max <span className="font-medium text-foreground">{fmt.percent(max)}</span>
          </span>
        </div>
      </CardContent>
    </Card>
  );
}

function PassFailDot(props: {
  cx?: number;
  cy?: number;
  payload?: { passed?: boolean };
}) {
  const { cx, cy, payload } = props;
  if (cx === undefined || cy === undefined) return null;
  if (payload?.passed) {
    return (
      <circle cx={cx} cy={cy} r={3.5} fill="hsl(var(--primary))" />
    );
  }
  return (
    <rect
      x={cx - 4}
      y={cy - 4}
      width={8}
      height={8}
      fill="hsl(var(--background))"
      stroke="hsl(var(--destructive))"
      strokeWidth={1.5}
    />
  );
}

type TrendTooltipPayload = {
  runAt: string;
  verdictAccuracy: number;
  phone: number;
  url: number;
  text: number;
  passed: boolean;
  gitSha: string | null;
};

function TrendTooltip({
  active,
  payload,
  fmt,
  t,
}: {
  active?: boolean;
  payload?: ReadonlyArray<{ payload?: TrendTooltipPayload }>;
  fmt: ReturnType<typeof useFormat>;
  t: ReturnType<typeof useTranslation>['t'];
}) {
  if (!active || !payload || payload.length === 0) return null;
  const e = payload[0]?.payload;
  if (!e) return null;
  return (
    <div className="rounded-md border border-border bg-popover px-3 py-2 text-xs shadow-md">
      <div className="font-medium text-foreground">{fmt.dateTime(e.runAt)}</div>
      <div className="mt-1 tabular-nums text-foreground">
        {fmt.percent(e.verdictAccuracy)} ·{' '}
        <span
          className={cn(
            'font-medium',
            e.passed ? 'text-primary' : 'text-destructive',
          )}
        >
          {e.passed ? t('charts.pass') : t('charts.fail')}
        </span>
      </div>
      <div className="mt-1 grid grid-cols-3 gap-x-3 text-[10px] tabular-nums text-muted-foreground">
        <span>phone {fmt.percent(e.phone, { digits: 0 })}</span>
        <span>url {fmt.percent(e.url, { digits: 0 })}</span>
        <span>text {fmt.percent(e.text, { digits: 0 })}</span>
      </div>
      {e.gitSha ? (
        <div className="mt-1 text-[10px] text-muted-foreground">
          {shortSha(e.gitSha)}
        </div>
      ) : null}
    </div>
  );
}

const PERTYPE_TICK_PCTS = [0, 50, 100] as const;

function PerTypeCard({ summary }: { summary: NonNullable<Summary> }) {
  const { t } = useTranslation();
  const fmt = useFormat();
  const threshold = summary.threshold;

  return (
    <Card className="mb-6">
      <CardHeader>
        <CardTitle className="text-base">{t('aiEval.perTypeTitle')}</CardTitle>
        <p className="text-xs text-muted-foreground">
          {t('aiEval.perTypeNote', { threshold: fmt.percent(threshold, { digits: 0 }) })}
        </p>
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
              <TableHead className="min-w-[12rem]">
                {t('aiEval.accuracyBar')}
              </TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {TYPES.map((tt) => {
              const m = summary.byType[tt];
              const below = m.verdictAccuracy < threshold;
              return (
                <TableRow key={tt}>
                  <TableCell className="font-medium">{tt}</TableCell>
                  <TableCell className="text-right tabular-nums">
                    {fmt.number(m.n)}
                  </TableCell>
                  <TableCell className="text-right tabular-nums">
                    {fmt.percent(m.verdictAccuracy)}
                  </TableCell>
                  <TableCell className="text-right tabular-nums">
                    {fmt.percent(m.scammerRecallAt1)}
                  </TableCell>
                  <TableCell className="text-right tabular-nums">
                    {m.mrr.toFixed(3)}
                  </TableCell>
                  <TableCell className="text-right tabular-nums">
                    {fmt.number(m.p95LatencyMs)}
                  </TableCell>
                  <TableCell>
                    <PerTypeBar
                      value={m.verdictAccuracy}
                      below={below}
                      label={fmt.percent(m.verdictAccuracy)}
                    />
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

function PerTypeBar({
  value,
  below,
  label,
}: {
  value: number;
  below: boolean;
  label: string;
}) {
  const pct = Math.max(0, Math.min(1, value)) * 100;
  return (
    <div className="flex min-w-[10rem] max-w-[16rem] items-center gap-2">
      <div className="relative h-3 flex-1">
        <svg
          className="absolute inset-0 h-full w-full"
          preserveAspectRatio="none"
          aria-hidden="true"
        >
          {PERTYPE_TICK_PCTS.map((p) => (
            <line
              key={p}
              x1={`${p}%`}
              y1={0}
              x2={`${p}%`}
              y2="100%"
              stroke="hsl(var(--border))"
              strokeWidth={1}
            />
          ))}
        </svg>
        <div className="absolute inset-0 overflow-hidden rounded-full bg-muted">
          <div
            className={cn(
              'h-full rounded-full',
              below ? 'bg-destructive' : 'bg-primary',
            )}
            style={{
              width: `${pct}%`,
              backgroundImage: below
                ? 'repeating-linear-gradient(45deg, hsl(var(--destructive)) 0 4px, hsl(var(--destructive-foreground) / 0.35) 4px 8px)'
                : undefined,
            }}
          />
        </div>
      </div>
      <span className="shrink-0 text-xs font-medium tabular-nums">
        {label}
      </span>
    </div>
  );
}

function ConfusionCard({ summary }: { summary: NonNullable<Summary> }) {
  const { t } = useTranslation();
  const fmt = useFormat();
  const m = summary.confusionMatrix;

  const rowTotals = Object.fromEntries(
    VERDICTS.map((exp) => [
      exp,
      VERDICTS.reduce((sum, act) => sum + m[exp][act], 0),
    ]),
  ) as Record<Verdict, number>;

  let worst: { exp: Verdict; act: Verdict; n: number } | null = null;
  for (const exp of VERDICTS) {
    for (const act of VERDICTS) {
      if (exp === act) continue;
      const n = m[exp][act];
      if (n > 0 && (!worst || n > worst.n)) {
        worst = { exp, act, n };
      }
    }
  }

  const max = Math.max(
    1,
    ...VERDICTS.flatMap((exp) => VERDICTS.map((act) => m[exp][act])),
  );

  return (
    <Card className="mb-6">
      <CardHeader>
        <CardTitle className="text-base">
          {t('aiEval.confusionTitle')}
        </CardTitle>
        <p className="text-xs text-muted-foreground">
          {t('aiEval.confusionNote')}
        </p>
      </CardHeader>
      <CardContent>
        <div className="overflow-x-auto">
          <table className="w-full border-separate border-spacing-0 text-sm tabular-nums">
            <caption className="sr-only">
              {t('aiEval.confusionCaption')}
            </caption>
            <thead>
              <tr className="text-muted-foreground">
                <th
                  scope="col"
                  className="px-3 py-2 text-left text-xs font-normal"
                >
                  {t('aiEval.expectedVsActual')}
                </th>
                {VERDICTS.map((act) => (
                  <th
                    key={act}
                    scope="col"
                    className="min-w-[6rem] px-3 py-2 text-right text-xs font-medium"
                  >
                    {act}
                  </th>
                ))}
                <th
                  scope="col"
                  className="px-3 py-2 text-right text-xs font-medium"
                >
                  {t('charts.total')}
                </th>
              </tr>
            </thead>
            <tbody>
              {VERDICTS.map((exp) => {
                const total = rowTotals[exp];
                return (
                  <tr key={exp}>
                    <th
                      scope="row"
                      className="px-3 py-2 text-left font-medium"
                    >
                      {exp}
                    </th>
                    {VERDICTS.map((act) => {
                      const n = m[exp][act];
                      const diag = exp === act;
                      const isWorst =
                        worst != null && worst.exp === exp && worst.act === act;
                      const intensity = n === 0 ? 0 : Math.min(1, n / max);
                      const rowPct = total > 0 ? n / total : 0;
                      const bg =
                        n === 0
                          ? undefined
                          : diag
                            ? `hsl(var(--primary) / ${0.05 + intensity * 0.2})`
                            : `hsl(var(--destructive) / ${0.05 + intensity * 0.2})`;
                      return (
                        <td
                          key={act}
                          className={cn(
                            'p-3 text-right align-middle',
                            diag
                              ? 'font-semibold ring-1 ring-inset ring-primary/40'
                              : '',
                            isWorst ? 'ring-2 ring-inset ring-destructive' : '',
                          )}
                          style={{ backgroundColor: bg }}
                        >
                          {n === 0 ? (
                            <span className="text-muted-foreground">—</span>
                          ) : (
                            <>
                              <div>{fmt.number(n)}</div>
                              <div className="text-[10px] font-normal opacity-70">
                                {fmt.percent(rowPct, { digits: 0 })}
                              </div>
                            </>
                          )}
                        </td>
                      );
                    })}
                    <td className="p-3 text-right text-xs text-muted-foreground">
                      {fmt.number(total)}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
        {worst ? (
          <p className="mt-3 text-xs text-muted-foreground">
            {t('aiEval.mostCommonError', {
              expected: worst.exp,
              actual: worst.act,
              n: fmt.number(worst.n),
            })}
          </p>
        ) : null}
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
