import type { ScamOverviewDailyBucket } from '@my-product/shared';

export function Sparkline({ daily }: { daily: ScamOverviewDailyBucket[] }) {
  if (daily.length === 0) return null;
  const w = 600;
  const h = 80;
  const padX = 8;
  const padY = 8;
  const max = Math.max(1, ...daily.map((d) => d.count));
  const xs = daily.map(
    (_, i) =>
      padX + (i / Math.max(1, daily.length - 1)) * (w - 2 * padX),
  );
  const ys = daily.map((d) => h - padY - (d.count / max) * (h - 2 * padY));
  const path = xs
    .map((x, i) => `${i === 0 ? 'M' : 'L'} ${x} ${ys[i]}`)
    .join(' ');
  const first = daily[0]!;
  const last = daily[daily.length - 1]!;
  return (
    <>
      <svg
        viewBox={`0 0 ${w} ${h}`}
        className="h-20 w-full"
        role="img"
        aria-label="Records crawled per day"
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
            fill="hsl(var(--primary))"
          />
        ))}
      </svg>
      <div className="mt-2 flex justify-between text-xs text-muted-foreground tabular-nums">
        <span>{first.date}</span>
        <span>peak {max}/day</span>
        <span>{last.date}</span>
      </div>
    </>
  );
}
