import { cva, type VariantProps } from 'class-variance-authority';
import type { HTMLAttributes } from 'react';
import { cn } from '@/lib/utils';

const badgeVariants = cva(
  'inline-flex items-center rounded-xl border px-2.5 py-0.5 text-xs font-semibold transition-colors',
  {
    variants: {
      variant: {
        default: 'border-transparent bg-primary text-primary-foreground',
        secondary: 'border-transparent bg-secondary text-secondary-foreground',
        destructive:
          'border-transparent bg-destructive text-destructive-foreground',
        outline: 'text-foreground',
        scam: 'border-transparent bg-verdict-scam-bg text-verdict-scam-fg',
        suspicious:
          'border-transparent bg-verdict-suspicious-bg text-verdict-suspicious-fg',
        safe: 'border-transparent bg-verdict-safe-bg text-verdict-safe-fg',
        unknown:
          'border-transparent bg-verdict-unknown-bg text-verdict-unknown-fg',
      },
    },
    defaultVariants: { variant: 'default' },
  },
);

export interface BadgeProps
  extends HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}

export function Badge({ className, variant, ...props }: BadgeProps) {
  return <div className={cn(badgeVariants({ variant }), className)} {...props} />;
}

export { badgeVariants };
