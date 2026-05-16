import { Search } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import { Badge } from '@/components/ui/badge';
import { useReportSearch } from '@/features/moderation/api/search';
import { cn } from '@/lib/utils';

export function GlobalSearch() {
  const { t, i18n } = useTranslation('moderation');
  const navigate = useNavigate();
  const [q, setQ] = useState('');
  const [focused, setFocused] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const { data, isFetching } = useReportSearch(q);
  const showDropdown = focused && q.trim().length >= 2;

  useEffect(() => {
    function onKey(e: KeyboardEvent) {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        inputRef.current?.focus();
      }
      if (e.key === 'Escape') {
        inputRef.current?.blur();
        setQ('');
      }
    }
    document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, []);

  useEffect(() => {
    function onClickOutside(e: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setFocused(false);
      }
    }
    document.addEventListener('mousedown', onClickOutside);
    return () => document.removeEventListener('mousedown', onClickOutside);
  }, []);

  const handleSelect = (id: string) => {
    setFocused(false);
    setQ('');
    navigate(`/moderation/${id}`);
  };

  const statusColor: Record<string, string> = {
    pending: 'secondary',
    flagged: 'suspicious',
    verified: 'safe',
    rejected: 'destructive',
  };

  return (
    <div ref={containerRef} className="relative">
      <div
        className={cn(
          'flex h-9 w-56 items-center gap-2 rounded-lg border bg-muted/50 px-3 transition-all',
          'focus-within:w-72 focus-within:bg-background focus-within:shadow-sm focus-within:ring-2 focus-within:ring-primary/40',
          'sm:w-64 sm:focus-within:w-80',
        )}
      >
        <Search className="size-3.5 shrink-0 text-muted-foreground" aria-hidden />
        <input
          ref={inputRef}
          type="search"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          onFocus={() => setFocused(true)}
          placeholder={t('search.placeholder')}
          className="h-full flex-1 bg-transparent text-sm outline-none placeholder:text-muted-foreground"
          aria-label={t('search.placeholder')}
          aria-autocomplete="list"
          aria-expanded={showDropdown}
        />
        <kbd className="hidden shrink-0 rounded border border-border bg-background px-1.5 py-0.5 font-mono text-[10px] text-muted-foreground opacity-70 sm:inline">
          ⌘K
        </kbd>
      </div>

      {showDropdown && (
        <div className="absolute right-0 top-full z-50 mt-1 w-[28rem] rounded-lg border bg-card shadow-lg">
          {isFetching ? (
            <p className="px-4 py-3 text-sm text-muted-foreground">{t('search.searching')}</p>
          ) : !data || data.items.length === 0 ? (
            <p className="px-4 py-3 text-sm text-muted-foreground">{t('search.noResults')}</p>
          ) : (
            <>
              <ul className="divide-y max-h-96 overflow-y-auto">
                {data.items.map((item) => (
                  <li key={item.id}>
                    <button
                      type="button"
                      className="flex w-full items-start gap-3 px-4 py-3 text-left hover:bg-muted/60 focus:bg-muted/60 focus:outline-none"
                      onClick={() => handleSelect(item.id)}
                    >
                      <div className="flex-1 min-w-0">
                        <p className="truncate text-sm font-medium">{item.title}</p>
                        {item.targetIdentifier && (
                          <p className="truncate font-mono text-xs text-muted-foreground">
                            {item.targetIdentifier}
                          </p>
                        )}
                      </div>
                      <div className="flex shrink-0 flex-col items-end gap-1">
                        <Badge
                          variant={(statusColor[item.status] as 'secondary') ?? 'outline'}
                          className="capitalize text-xs"
                        >
                          {item.status}
                        </Badge>
                        <span className="text-xs text-muted-foreground">
                          {i18n.language === 'th' ? item.scamTypeLabelTh : item.scamTypeLabelEn}
                        </span>
                      </div>
                    </button>
                  </li>
                ))}
              </ul>
              {data.total > data.items.length && (
                <p className="border-t px-4 py-2 text-xs text-muted-foreground">
                  {t('search.moreResults', { total: data.total, shown: data.items.length })}
                </p>
              )}
            </>
          )}
        </div>
      )}
    </div>
  );
}
