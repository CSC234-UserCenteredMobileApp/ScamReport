export type YTick = { value: number; label: string };
export type XTick = { x: number; label: string };

/**
 * Horizontal gridlines + Y-axis tick labels. Renders inside the parent SVG.
 * `value` is normalised to [0, 1]; the component maps it to the chart's Y space.
 */
export function YAxis({
  ticks,
  height,
  width,
  padTop = 8,
  padBottom = 16,
  labelOffset = 4,
}: {
  ticks: ReadonlyArray<YTick>;
  height: number;
  width: number;
  padTop?: number;
  padBottom?: number;
  labelOffset?: number;
}) {
  const usableH = height - padTop - padBottom;
  return (
    <g aria-hidden="true">
      {ticks.map((t) => {
        const y = height - padBottom - t.value * usableH;
        return (
          <g key={t.value}>
            <line
              x1={0}
              y1={y}
              x2={width}
              y2={y}
              stroke="hsl(var(--border))"
              strokeDasharray="2 4"
              strokeWidth={1}
            />
            <text
              x={width - labelOffset}
              y={y - 3}
              textAnchor="end"
              fill="hsl(var(--muted-foreground))"
              fontSize={10}
              fontFamily="inherit"
            >
              {t.label}
            </text>
          </g>
        );
      })}
    </g>
  );
}

export function XAxisLabels({
  ticks,
  y,
}: {
  ticks: ReadonlyArray<XTick>;
  y: number;
}) {
  return (
    <g aria-hidden="true">
      {ticks.map((t, i) => (
        <text
          key={i}
          x={t.x}
          y={y}
          textAnchor={i === 0 ? 'start' : i === ticks.length - 1 ? 'end' : 'middle'}
          fill="hsl(var(--muted-foreground))"
          fontSize={10}
          fontFamily="inherit"
        >
          {t.label}
        </text>
      ))}
    </g>
  );
}

/**
 * Reference line (e.g. accuracy threshold) drawn across the plot area.
 */
export function ReferenceLine({
  value,
  height,
  width,
  padTop = 8,
  padBottom = 16,
  padLeft = 0,
  label,
  dashed = true,
}: {
  value: number; // normalised [0, 1]
  height: number;
  width: number;
  padTop?: number;
  padBottom?: number;
  padLeft?: number;
  label?: string;
  dashed?: boolean;
}) {
  const usableH = height - padTop - padBottom;
  const y = height - padBottom - value * usableH;
  return (
    <g aria-hidden="true">
      <line
        x1={padLeft}
        y1={y}
        x2={width}
        y2={y}
        stroke="hsl(var(--muted-foreground))"
        strokeDasharray={dashed ? '4 4' : undefined}
        strokeWidth={1}
        opacity={0.7}
      />
      {label ? (
        <text
          x={width - 4}
          y={y - 4}
          textAnchor="end"
          fill="hsl(var(--muted-foreground))"
          fontSize={10}
          fontFamily="inherit"
        >
          {label}
        </text>
      ) : null}
    </g>
  );
}
