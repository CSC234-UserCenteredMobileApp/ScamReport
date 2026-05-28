import { useTranslation } from 'react-i18next';

function pickLocale(lang: string): string {
  return lang.startsWith('th') ? 'th-TH' : 'en-US';
}

export function formatPercent(
  n: number,
  lang: string,
  opts: { digits?: number } = {},
): string {
  const digits = opts.digits ?? 1;
  return new Intl.NumberFormat(pickLocale(lang), {
    style: 'percent',
    minimumFractionDigits: digits,
    maximumFractionDigits: digits,
  }).format(n);
}

export function formatNumber(n: number, lang: string): string {
  return new Intl.NumberFormat(pickLocale(lang)).format(n);
}

export function formatDateShort(
  value: string | number | Date,
  lang: string,
): string {
  const d = value instanceof Date ? value : new Date(value);
  return new Intl.DateTimeFormat(pickLocale(lang), {
    day: '2-digit',
    month: 'short',
  }).format(d);
}

export function formatDateTime(
  value: string | number | Date,
  lang: string,
): string {
  const d = value instanceof Date ? value : new Date(value);
  return new Intl.DateTimeFormat(pickLocale(lang), {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(d);
}

const RELATIVE_UNITS: Array<[Intl.RelativeTimeFormatUnit, number]> = [
  ['year', 365 * 24 * 3600 * 1000],
  ['month', 30 * 24 * 3600 * 1000],
  ['day', 24 * 3600 * 1000],
  ['hour', 3600 * 1000],
  ['minute', 60 * 1000],
];

export function formatRelative(
  value: string | number | Date,
  lang: string,
): string {
  const d = value instanceof Date ? value : new Date(value);
  const diffMs = d.getTime() - Date.now();
  const rtf = new Intl.RelativeTimeFormat(pickLocale(lang), { numeric: 'auto' });
  for (const [unit, ms] of RELATIVE_UNITS) {
    if (Math.abs(diffMs) >= ms) return rtf.format(Math.round(diffMs / ms), unit);
  }
  return rtf.format(0, 'second');
}

export function useFormat() {
  const { i18n } = useTranslation();
  const lang = i18n.language;
  return {
    lang,
    percent: (n: number, opts?: { digits?: number }) =>
      formatPercent(n, lang, opts),
    number: (n: number) => formatNumber(n, lang),
    dateShort: (v: string | number | Date) => formatDateShort(v, lang),
    dateTime: (v: string | number | Date) => formatDateTime(v, lang),
    relative: (v: string | number | Date) => formatRelative(v, lang),
  };
}
