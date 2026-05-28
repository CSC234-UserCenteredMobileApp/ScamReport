import { useTranslation } from 'react-i18next';
import { Tooltip } from '@/components/ui/tooltip';
import { useFormat } from '@/lib/format';

export type BarListRow = {
  key: string;
  primaryLabel: string;
  secondaryLabel?: string;
  count: number;
};

const GRID_PCTS = [25, 50, 75] as const;

export function BarList({
  rows,
  emptyLabel,
  ariaLabel,
}: {
  rows: BarListRow[];
  emptyLabel: string;
  ariaLabel: string;
}) {
  const { t } = useTranslation();
  const fmt = useFormat();

  if (rows.length === 0) {
    return <p className="text-sm text-muted-foreground">{emptyLabel}</p>;
  }

  const max = Math.max(1, ...rows.map((r) => r.count));

  return (
    <ol role="list" aria-label={ariaLabel} className="space-y-2">
      {rows.map((row) => {
        const pct = (row.count / max) * 100;
        const hasSecondary =
          row.secondaryLabel && row.secondaryLabel !== row.primaryLabel;
        const tooltipBody = (
          <div className="space-y-0.5">
            <div className="font-medium">{row.primaryLabel}</div>
            {hasSecondary ? (
              <div className="opacity-80">{row.secondaryLabel}</div>
            ) : null}
            <div className="tabular-nums">
              {fmt.number(row.count)} · {fmt.percent(row.count / max)}{' '}
              {t('charts.ofMax')}
            </div>
          </div>
        );
        return (
          <li key={row.key} className="flex items-center gap-3 text-sm">
            <Tooltip content={tooltipBody}>
              <button
                type="button"
                className="w-32 shrink-0 cursor-default rounded-sm text-left outline-none focus-visible:ring-2 focus-visible:ring-ring md:w-48 lg:w-64"
              >
                <div className="truncate font-medium">{row.primaryLabel}</div>
                {hasSecondary ? (
                  <div className="truncate text-xs text-muted-foreground">
                    {row.secondaryLabel}
                  </div>
                ) : null}
              </button>
            </Tooltip>

            <div className="relative h-2.5 flex-1">
              <svg
                className="absolute inset-0 h-full w-full"
                preserveAspectRatio="none"
                aria-hidden="true"
              >
                {GRID_PCTS.map((g) => (
                  <line
                    key={g}
                    x1={`${g}%`}
                    y1={0}
                    x2={`${g}%`}
                    y2="100%"
                    stroke="hsl(var(--border))"
                    strokeDasharray="2 3"
                    strokeWidth={1}
                  />
                ))}
              </svg>
              <div className="absolute inset-0 overflow-hidden rounded-full bg-muted">
                <div
                  className="h-full rounded-full bg-primary"
                  style={{ width: `${pct}%` }}
                />
              </div>
            </div>

            <span className="shrink-0 text-right text-xs tabular-nums text-muted-foreground">
              <span className="font-medium text-foreground">
                {fmt.number(row.count)}
              </span>{' '}
              · {fmt.percent(row.count / max, { digits: 0 })}
            </span>
          </li>
        );
      })}
    </ol>
  );
}
