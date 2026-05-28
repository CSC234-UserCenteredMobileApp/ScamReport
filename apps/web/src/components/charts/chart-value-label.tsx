/**
 * SVG text with a halo (dual-stroke) so labels remain legible against any fill.
 */
export function ValueLabel({
  x,
  y,
  children,
  anchor = 'middle',
  weight = 600,
  size = 11,
}: {
  x: number;
  y: number;
  children: string;
  anchor?: 'start' | 'middle' | 'end';
  weight?: number;
  size?: number;
}) {
  return (
    <text
      x={x}
      y={y}
      textAnchor={anchor}
      fill="hsl(var(--foreground))"
      stroke="hsl(var(--background))"
      strokeWidth={3}
      paintOrder="stroke"
      fontSize={size}
      fontWeight={weight}
      fontFamily="inherit"
      className="tabular-nums"
    >
      {children}
    </text>
  );
}
