import { type ComponentType } from 'react';
import { Link } from 'react-router-dom';
import { Card, CardContent } from '@/components/ui/card';
import { cn } from '@/lib/utils';

export type KpiTone = 'primary' | 'warn' | 'alert' | 'info';

/**
 * Tone classes. Dark-mode text shades are kept at 300/200 (rather than 400) so
 * every combination clears WCAG AA 4.5:1 against the muted-background-on-card
 * surface.
 */
const TONE: Record<KpiTone, string> = {
  primary: 'bg-primary/10 text-primary',
  warn: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/40 dark:text-yellow-200',
  alert:
    'bg-orange-100 text-orange-700 dark:bg-orange-900/40 dark:text-orange-200',
  info: 'bg-blue-100 text-blue-700 dark:bg-blue-900/40 dark:text-blue-200',
};

export function KpiTile({
  icon: Icon,
  label,
  value,
  tone = 'primary',
  to,
  className,
}: {
  icon: ComponentType<{ className?: string; 'aria-hidden'?: boolean | 'true' | 'false' }>;
  label: string;
  value: number | string;
  tone?: KpiTone;
  to?: string;
  className?: string;
}) {
  const body = (
    <Card
      className={cn(
        to ? 'transition-shadow hover:shadow-md' : undefined,
        className,
      )}
    >
      <CardContent className="flex items-center gap-4 p-5">
        <div className={cn('rounded-lg p-2', TONE[tone])}>
          <Icon aria-hidden="true" className="size-5" />
        </div>
        <div>
          <p className="text-xs uppercase tracking-wide text-muted-foreground">
            {label}
          </p>
          <p className="text-2xl font-bold tabular-nums">{value}</p>
        </div>
      </CardContent>
    </Card>
  );
  return to ? (
    <Link to={to} className="block">
      {body}
    </Link>
  ) : (
    body
  );
}
