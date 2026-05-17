export type BarListRow = {
  key: string;
  primaryLabel: string;
  secondaryLabel?: string;
  count: number;
};

export function BarList({
  rows,
  emptyLabel,
}: {
  rows: BarListRow[];
  emptyLabel: string;
}) {
  if (rows.length === 0) {
    return <p className="text-sm text-muted-foreground">{emptyLabel}</p>;
  }
  const max = Math.max(1, ...rows.map((r) => r.count));
  return (
    <ul className="space-y-2">
      {rows.map((row) => {
        const pct = (row.count / max) * 100;
        return (
          <li key={row.key} className="flex items-center gap-3 text-sm">
            <div className="w-40 shrink-0">
              <div className="truncate font-medium" title={row.primaryLabel}>
                {row.primaryLabel}
              </div>
              {row.secondaryLabel && row.secondaryLabel !== row.primaryLabel && (
                <div
                  className="truncate text-xs text-muted-foreground"
                  title={row.secondaryLabel}
                >
                  {row.secondaryLabel}
                </div>
              )}
            </div>
            <div className="h-2 flex-1 overflow-hidden rounded bg-muted">
              <div
                className="h-full bg-primary"
                style={{ width: `${pct}%` }}
              />
            </div>
            <span className="w-12 shrink-0 text-right tabular-nums text-muted-foreground">
              {row.count}
            </span>
          </li>
        );
      })}
    </ul>
  );
}
