import { type ReactNode, useId } from 'react';
import { cn } from '@/lib/utils';

export type ChartColumn<T> = {
  key: keyof T & string;
  label: string;
  format?: (row: T) => string;
};

export function ChartContainer<T extends Record<string, unknown>>({
  title,
  description,
  data,
  columns,
  className,
  children,
}: {
  title: string;
  description?: string;
  data?: ReadonlyArray<T>;
  columns?: ReadonlyArray<ChartColumn<T>>;
  className?: string;
  children: ReactNode;
}) {
  const captionId = useId();
  const descId = useId();
  return (
    <figure
      aria-labelledby={captionId}
      aria-describedby={description ? descId : undefined}
      className={cn('relative', className)}
    >
      <figcaption id={captionId} className="sr-only">
        {title}
      </figcaption>
      {description ? (
        <p id={descId} className="sr-only">
          {description}
        </p>
      ) : null}
      {children}
      {data && columns ? (
        <table className="sr-only">
          <caption>{title}</caption>
          <thead>
            <tr>
              {columns.map((c) => (
                <th key={c.key} scope="col">
                  {c.label}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {data.map((row, i) => (
              <tr key={i}>
                {columns.map((c) => (
                  <td key={c.key}>
                    {c.format ? c.format(row) : String(row[c.key] ?? '')}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      ) : null}
    </figure>
  );
}
