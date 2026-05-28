import { type ReactNode } from 'react';
import { Tooltip } from '@/components/ui/tooltip';
import { cn } from '@/lib/utils';

/**
 * Absolutely-positioned, keyboard-focusable hit target sitting above an SVG
 * chart. Wraps shadcn Tooltip so hover OR focus reveals the value.
 */
export function ChartHoverTarget({
  leftPct,
  tooltip,
  ariaLabel,
  width = 20,
  className,
}: {
  leftPct: number;
  tooltip: ReactNode;
  ariaLabel: string;
  width?: number;
  className?: string;
}) {
  return (
    <Tooltip content={tooltip}>
      <button
        type="button"
        aria-label={ariaLabel}
        className={cn(
          'absolute inset-y-0 -translate-x-1/2 cursor-default rounded-sm bg-transparent outline-none focus-visible:ring-2 focus-visible:ring-ring',
          className,
        )}
        style={{ left: `${leftPct}%`, width: `${width}px` }}
      />
    </Tooltip>
  );
}
