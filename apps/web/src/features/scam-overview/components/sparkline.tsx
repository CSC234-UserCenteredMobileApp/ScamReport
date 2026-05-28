import { useTranslation } from 'react-i18next';
import type { ScamOverviewDailyBucket } from '@my-product/shared';
import {
  ChartContainer,
  ChartHoverTarget,
  ValueLabel,
  XAxisLabels,
  type ChartColumn,
} from '@/components/charts';
import { useFormat } from '@/lib/format';

const VB_W = 600;
const VB_H = 120;
const PAD_TOP = 12;
const PAD_BOTTOM = 22;
const PAD_LEFT = 4;
const PAD_RIGHT = 44;

function isWeekend(iso: string): boolean {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return false;
  const day = d.getUTCDay();
  return day === 0 || day === 6;
}

export function Sparkline({
  daily,
  title,
}: {
  daily: ScamOverviewDailyBucket[];
  title: string;
}) {
  const { t } = useTranslation();
  const fmt = useFormat();

  if (daily.length === 0) return null;

  const max = Math.max(1, ...daily.map((d) => d.count));
  const usableW = VB_W - PAD_LEFT - PAD_RIGHT;
  const usableH = VB_H - PAD_TOP - PAD_BOTTOM;
  const stepX = daily.length > 1 ? usableW / (daily.length - 1) : 0;

  const points = daily.map((d, i) => ({
    bucket: d,
    x: PAD_LEFT + i * stepX,
    y: VB_H - PAD_BOTTOM - (d.count / max) * usableH,
    leftPct:
      daily.length > 1
        ? ((PAD_LEFT + i * stepX) / VB_W) * 100
        : ((PAD_LEFT + usableW / 2) / VB_W) * 100,
    weekend: isWeekend(d.date),
  }));

  const line = points
    .map((p, i) => `${i === 0 ? 'M' : 'L'} ${p.x} ${p.y}`)
    .join(' ');
  const area =
    points.length > 1
      ? `${line} L ${points[points.length - 1]!.x} ${VB_H - PAD_BOTTOM} L ${points[0]!.x} ${VB_H - PAD_BOTTOM} Z`
      : '';

  const baselineY = VB_H - PAD_BOTTOM;
  const topY = PAD_TOP;

  const peakIdx = points.reduce(
    (best, p, i) => (p.bucket.count > points[best]!.bucket.count ? i : best),
    0,
  );
  const peakPoint = points[peakIdx]!;

  const xTicks =
    daily.length >= 3
      ? [
          { x: points[0]!.x, label: fmt.dateShort(points[0]!.bucket.date) },
          {
            x: points[Math.floor((daily.length - 1) / 2)]!.x,
            label: fmt.dateShort(
              points[Math.floor((daily.length - 1) / 2)]!.bucket.date,
            ),
          },
          {
            x: points[points.length - 1]!.x,
            label: fmt.dateShort(points[points.length - 1]!.bucket.date),
          },
        ]
      : points.map((p) => ({ x: p.x, label: fmt.dateShort(p.bucket.date) }));

  const columns: ReadonlyArray<ChartColumn<ScamOverviewDailyBucket>> = [
    { key: 'date', label: t('charts.date') },
    {
      key: 'count',
      label: t('charts.reports'),
      format: (r) => fmt.number(r.count),
    },
  ];

  return (
    <ChartContainer
      title={title}
      description={t('charts.peakPerDay', { count: max })}
      data={daily}
      columns={columns}
    >
      <div className="relative">
        <svg
          viewBox={`0 0 ${VB_W} ${VB_H}`}
          className="h-28 w-full"
          preserveAspectRatio="none"
          role="img"
          aria-label={title}
        >
          <line
            x1={PAD_LEFT}
            y1={baselineY}
            x2={VB_W - PAD_RIGHT}
            y2={baselineY}
            stroke="hsl(var(--border))"
            strokeWidth={1}
          />
          <line
            x1={PAD_LEFT}
            y1={topY}
            x2={VB_W - PAD_RIGHT}
            y2={topY}
            stroke="hsl(var(--border))"
            strokeDasharray="2 4"
            strokeWidth={1}
          />
          <text
            x={VB_W - PAD_RIGHT + 4}
            y={topY + 4}
            fill="hsl(var(--muted-foreground))"
            fontSize={10}
            fontFamily="inherit"
          >
            {t('charts.peakSuffix', { count: max })}
          </text>
          <text
            x={VB_W - PAD_RIGHT + 4}
            y={baselineY}
            fill="hsl(var(--muted-foreground))"
            fontSize={10}
            fontFamily="inherit"
          >
            0
          </text>

          {area ? <path d={area} fill="hsl(var(--primary) / 0.12)" /> : null}
          <path
            d={line}
            fill="none"
            stroke="hsl(var(--primary))"
            strokeWidth={1.5}
          />

          {points.map((p, i) => (
            <circle
              key={i}
              cx={p.x}
              cy={p.y}
              r={i === peakIdx ? 3.5 : 2.5}
              fill={
                i === peakIdx
                  ? 'hsl(var(--primary))'
                  : p.weekend
                    ? 'hsl(var(--background))'
                    : 'hsl(var(--primary))'
              }
              stroke="hsl(var(--primary))"
              strokeWidth={p.weekend && i !== peakIdx ? 1.25 : 0}
            />
          ))}

          <ValueLabel
            x={peakPoint.x}
            y={Math.max(peakPoint.y - 6, topY - 2)}
            anchor={peakIdx === 0 ? 'start' : peakIdx === points.length - 1 ? 'end' : 'middle'}
          >
            {fmt.number(peakPoint.bucket.count)}
          </ValueLabel>

          <XAxisLabels ticks={xTicks} y={VB_H - 4} />
        </svg>

        {points.map((p, i) => (
          <ChartHoverTarget
            key={i}
            leftPct={p.leftPct}
            ariaLabel={`${fmt.dateShort(p.bucket.date)}: ${fmt.number(p.bucket.count)}`}
            tooltip={
              <div className="space-y-0.5">
                <div className="font-medium">{fmt.dateShort(p.bucket.date)}</div>
                <div className="tabular-nums">
                  {fmt.number(p.bucket.count)} {t('charts.reports').toLowerCase()}
                </div>
                {p.weekend ? (
                  <div className="text-[10px] opacity-80">
                    {t('charts.weekend')}
                  </div>
                ) : null}
              </div>
            }
          />
        ))}
      </div>
    </ChartContainer>
  );
}
