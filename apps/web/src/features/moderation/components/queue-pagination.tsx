import { ChevronLeft, ChevronRight } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';

interface Props {
  page: number;
  pageSize: number;
  total: number;
  onChange: (updates: { page?: number; page_size?: number }) => void;
}

// Build a page list with ellipsis: always first + last, current ± 1, gaps
// rendered as null. Pure function — small enough not to need a unit test.
function buildPageList(current: number, totalPages: number): (number | null)[] {
  if (totalPages <= 7) {
    return Array.from({ length: totalPages }, (_, i) => i + 1);
  }
  const pages = new Set<number>([
    1,
    totalPages,
    current - 1,
    current,
    current + 1,
  ]);
  const sorted = [...pages].filter((p) => p >= 1 && p <= totalPages).sort((a, b) => a - b);
  const out: (number | null)[] = [];
  let prev = 0;
  for (const p of sorted) {
    if (p - prev > 1) out.push(null);
    out.push(p);
    prev = p;
  }
  return out;
}

export function QueuePagination({ page, pageSize, total, onChange }: Props) {
  const { t } = useTranslation('moderation');
  const totalPages = Math.max(1, Math.ceil(total / pageSize));
  const from = total === 0 ? 0 : (page - 1) * pageSize + 1;
  const to = Math.min(page * pageSize, total);
  const pages = buildPageList(page, totalPages);

  return (
    <div className="flex flex-wrap items-center justify-between gap-3 rounded-lg border bg-card px-3 py-2 text-sm">
      <div className="text-muted-foreground">
        {t('pagination.showing')} {from}–{to} {t('pagination.of')} {total}
      </div>

      <div className="flex items-center gap-1">
        <Button
          variant="outline"
          size="sm"
          className="h-8 gap-1 px-2"
          disabled={page <= 1}
          onClick={() => onChange({ page: page - 1 })}
        >
          <ChevronLeft className="size-4" aria-hidden />
          <span className="sr-only sm:not-sr-only">{t('pagination.prev')}</span>
        </Button>

        {pages.map((p, i) =>
          p === null ? (
            <span
              key={`gap-${i}`}
              className="px-1 text-muted-foreground"
              aria-hidden
            >
              …
            </span>
          ) : (
            <Button
              key={p}
              variant={p === page ? 'default' : 'ghost'}
              size="sm"
              className="h-8 min-w-8 px-2"
              onClick={() => onChange({ page: p })}
              aria-current={p === page ? 'page' : undefined}
            >
              {p}
            </Button>
          ),
        )}

        <Button
          variant="outline"
          size="sm"
          className="h-8 gap-1 px-2"
          disabled={page >= totalPages}
          onClick={() => onChange({ page: page + 1 })}
        >
          <span className="sr-only sm:not-sr-only">{t('pagination.next')}</span>
          <ChevronRight className="size-4" aria-hidden />
        </Button>
      </div>

      <div className="flex items-center gap-2">
        <Label htmlFor="page-size" className="text-xs text-muted-foreground">
          {t('pagination.pageSize')}
        </Label>
        <Select
          value={String(pageSize)}
          onValueChange={(v) => onChange({ page_size: parseInt(v, 10) })}
        >
          <SelectTrigger id="page-size" className="h-8 w-[72px]">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="25">25</SelectItem>
            <SelectItem value="50">50</SelectItem>
            <SelectItem value="100">100</SelectItem>
          </SelectContent>
        </Select>
      </div>
    </div>
  );
}
