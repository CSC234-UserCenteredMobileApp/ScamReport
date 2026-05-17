import { Search, SlidersHorizontal, X } from 'lucide-react';
import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import type { ScamTypeItem } from '@my-product/shared';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover';
import { useDebouncedValue } from '@/lib/hooks/use-debounced-value';
import type { QueueSearch } from '@/features/moderation/pages/queue-page';
import { QueueFiltersPopover } from './queue-filters-popover';

interface Props {
  search: QueueSearch;
  scamTypes: ScamTypeItem[];
  onChange: (updates: Partial<QueueSearch>, opts?: { replace?: boolean }) => void;
}

export function QueueToolbar({ search, scamTypes, onChange }: Props) {
  const { t, i18n } = useTranslation('moderation');
  const [text, setText] = useState(search.q ?? '');
  const debounced = useDebouncedValue(text, 300);

  // Commit debounced search to URL. `replace: true` keeps history clean
  // — one entry per typing burst, not one per keystroke.
  useEffect(() => {
    const current = search.q ?? '';
    if (debounced === current) return;
    onChange({ q: debounced || undefined }, { replace: true });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [debounced]);

  // Sync external clears (Clear all button) back into local input state.
  useEffect(() => {
    if ((search.q ?? '') === '' && text !== '') setText('');
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search.q]);

  const activeCount =
    (search.status && search.status !== 'all' ? 1 : 0) +
    (search.priority === 'true' ? 1 : 0) +
    (search.confidence && search.confidence !== 'all' ? 1 : 0) +
    (search.scam_type ? 1 : 0);

  const chips: Array<{ key: keyof QueueSearch; label: string }> = [];
  if (search.status && search.status !== 'all') {
    chips.push({
      key: 'status',
      label: `${t('filter.statusLabel')}: ${t(`status.${search.status}`)}`,
    });
  }
  if (search.priority === 'true') {
    chips.push({ key: 'priority', label: t('filter.priorityOnly') });
  }
  if (search.confidence && search.confidence !== 'all') {
    const conf = t(
      `filter.confidence${search.confidence.charAt(0).toUpperCase()}${search.confidence.slice(1)}`,
    );
    chips.push({
      key: 'confidence',
      label: `${t('filter.confidenceLabel')}: ${conf}`,
    });
  }
  if (search.scam_type) {
    const st = scamTypes.find((s) => s.code === search.scam_type);
    const label = st
      ? i18n.language === 'th'
        ? st.labelTh
        : st.labelEn
      : search.scam_type;
    chips.push({
      key: 'scam_type',
      label: `${t('filter.typeLabel')}: ${label}`,
    });
  }

  const hasAny = chips.length > 0 || text.length > 0 || (search.q ?? '') !== '';

  return (
    <div className="space-y-2">
      <div className="flex flex-wrap items-center gap-2">
        <div className="relative min-w-[240px] flex-1">
          <Search
            className="pointer-events-none absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
            aria-hidden
          />
          <Input
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder={t('filter.searchPlaceholder')}
            className="pl-8"
          />
        </div>

        <Popover>
          <PopoverTrigger asChild>
            <Button variant="outline" size="sm" className="gap-2">
              <SlidersHorizontal className="size-4" aria-hidden />
              {t('filter.button')}
              {activeCount > 0 && (
                <Badge
                  variant="secondary"
                  className="ml-1 h-5 px-1.5 text-xs"
                >
                  {activeCount}
                </Badge>
              )}
            </Button>
          </PopoverTrigger>
          <PopoverContent align="end" className="w-72">
            <QueueFiltersPopover
              search={search}
              scamTypes={scamTypes}
              onChange={(u) => onChange(u)}
            />
          </PopoverContent>
        </Popover>
      </div>

      {(chips.length > 0 || hasAny) && (
        <div className="flex flex-wrap items-center gap-1.5">
          {chips.map((c) => (
            <Badge
              key={c.key}
              variant="secondary"
              className="gap-1 pr-1 text-xs font-normal"
            >
              {c.label}
              <button
                type="button"
                aria-label={`Remove ${c.label}`}
                onClick={() => onChange({ [c.key]: undefined })}
                className="rounded-sm p-0.5 hover:bg-muted-foreground/10"
              >
                <X className="size-3" aria-hidden />
              </button>
            </Badge>
          ))}
          {(chips.length > 0 || (search.q ?? '') !== '') && (
            <Button
              variant="ghost"
              size="sm"
              className="h-7 px-2 text-xs text-muted-foreground"
              onClick={() => {
                setText('');
                onChange({
                  q: undefined,
                  status: undefined,
                  priority: undefined,
                  confidence: undefined,
                  scam_type: undefined,
                });
              }}
            >
              {t('filter.clearAll')}
            </Button>
          )}
        </div>
      )}
    </div>
  );
}
