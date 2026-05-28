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
  ChartContainer,
  ChartHoverTarget,
  ReferenceLine,
  XAxisLabels,
  YAxis,
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

const TREND_VB_W = 600;
const TREND_VB_H = 160;
const TREND_PAD_TOP = 12;
const TREND_PAD_BOTTOM = 24;
const TREND_PAD_LEFT = 4;
const TREND_PAD_RIGHT = 44;

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

  const usableW = TREND_VB_W - TREND_PAD_LEFT - TREND_PAD_RIGHT;
  const usableH = TREND_VB_H - TREND_PAD_TOP - TREND_PAD_BOTTOM;
  const yMin = 0.7;
  const yMax = 1.0;
  const yScale = (v: number) =>
    TREND_VB_H -
    TREND_PAD_BOTTOM -
    ((Math.min(yMax, Math.max(yMin, v)) - yMin) / (yMax - yMin)) * usableH;
  const stepX = history.length > 1 ? usableW / (history.length - 1) : 0;

  const points = history.map((e, i) => ({
    entry: e,
    x: TREND_PAD_LEFT + i * stepX,
    y: yScale(e.verdictAccuracy),
    leftPct:
      history.length > 1
        ? ((TREND_PAD_LEFT + i * stepX) / TREND_VB_W) * 100
        : ((TREND_PAD_LEFT + usableW / 2) / TREND_VB_W) * 100,
  }));
  const line = points.map((p, i) => `${i === 0 ? 'M' : 'L'} ${p.x} ${p.y}`).join(' ');

  const accs = history.map((e) => e.verdictAccuracy);
  const min = Math.min(...accs);
  const max = Math.max(...accs);
  const last = history[history.length - 1]!;

  const yTicks = [
    { value: 0, label: fmt.percent(yMin, { digits: 0 }) },
    { value: (0.8 - yMin) / (yMax - yMin), label: fmt.percent(0.8, { digits: 0 }) },
    { value: (0.9 - yMin) / (yMax - yMin), label: fmt.percent(0.9, { digits: 0 }) },
    { value: 1, label: fmt.percent(yMax, { digits: 0 }) },
  ];

  const xTicks =
    history.length >= 3
      ? [
          { x: points[0]!.x, label: fmt.dateShort(points[0]!.entry.runAt) },
          {
            x: points[Math.floor((history.length - 1) / 2)]!.x,
            label: fmt.dateShort(
              points[Math.floor((history.length - 1) / 2)]!.entry.runAt,
            ),
          },
          {
            x: points[points.length - 1]!.x,
            label: fmt.dateShort(points[points.length - 1]!.entry.runAt),
          },
        ]
      : points.map((p) => ({ x: p.x, label: fmt.dateShort(p.entry.runAt) }));

  const thresholdNorm = (threshold - yMin) / (yMax - yMin);

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
          <div className="relative">
            <svg
              viewBox={`0 0 ${TREND_VB_W} ${TREND_VB_H}`}
              className="h-40 w-full"
              preserveAspectRatio="none"
              role="img"
              aria-label={t('aiEval.trendTitle', { count: history.length })}
            >
              <YAxis
                ticks={yTicks}
                height={TREND_VB_H}
                width={TREND_VB_W - TREND_PAD_RIGHT}
                padTop={TREND_PAD_TOP}
                padBottom={TREND_PAD_BOTTOM}
              />
              <ReferenceLine
                value={thresholdNorm}
                height={TREND_VB_H}
                width={TREND_VB_W - TREND_PAD_RIGHT}
                padTop={TREND_PAD_TOP}
                padBottom={TREND_PAD_BOTTOM}
                padLeft={TREND_PAD_LEFT}
                label={t('charts.threshold', { value: fmt.percent(threshold, { digits: 0 }) })}
              />
              <path
                d={line}
                fill="none"
                stroke="hsl(var(--primary))"
                strokeWidth={1.5}
              />
              {points.map((p, i) =>
                p.entry.passed ? (
                  <circle
                    key={i}
                    cx={p.x}
                    cy={p.y}
                    r={3}
                    fill="hsl(var(--primary))"
                  />
                ) : (
                  <rect
                    key={i}
                    x={p.x - 3.5}
                    y={p.y - 3.5}
                    width={7}
                    height={7}
                    fill="hsl(var(--background))"
                    stroke="hsl(var(--destructive))"
                    strokeWidth={1.5}
                  />
                ),
              )}
              <XAxisLabels ticks={xTicks} y={TREND_VB_H - 6} />
            </svg>

            {points.map((p, i) => (
              <ChartHoverTarget
                key={i}
                leftPct={p.leftPct}
                ariaLabel={`${fmt.dateShort(p.entry.runAt)} ${fmt.percent(p.entry.verdictAccuracy)}`}
                tooltip={
                  <div className="space-y-0.5">
                    <div className="font-medium">
                      {fmt.dateTime(p.entry.runAt)}
                    </div>
                    <div className="tabular-nums">
                      {fmt.percent(p.entry.verdictAccuracy)} ·{' '}
                      {p.entry.passed ? t('charts.pass') : t('charts.fail')}
                    </div>
                    {p.entry.gitSha ? (
                      <div className="text-[10px] opacity-80">
                        {shortSha(p.entry.gitSha)}
                      </div>
                    ) : null}
                  </div>
                }
              />
            ))}
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
