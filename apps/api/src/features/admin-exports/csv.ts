// Streaming CSV writer. Zero deps. RFC-4180 quoting + UTF-8 BOM so Excel
// auto-detects encoding for Thai labels.
//
// The writer consumes an AsyncIterable<row> with `headers` declared up front;
// each row is converted via the order of `headers`. Null/undefined become
// empty cells. Anything that isn't a string is JSON.stringified — keeps
// numbers + booleans + dates readable while still being safe for objects.

const UTF8_BOM = '﻿';
const CRLF = '\r\n';

function needsQuoting(s: string): boolean {
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i);
    if (c === 0x2c /* , */ || c === 0x22 /* " */ || c === 0x0a /* \n */ || c === 0x0d /* \r */) {
      return true;
    }
  }
  return false;
}

function cellToString(v: unknown): string {
  if (v === null || v === undefined) return '';
  if (v instanceof Date) return v.toISOString();
  if (typeof v === 'string') return v;
  if (typeof v === 'number' || typeof v === 'boolean' || typeof v === 'bigint') {
    return String(v);
  }
  return JSON.stringify(v);
}

function quote(s: string): string {
  if (!needsQuoting(s)) return s;
  return '"' + s.replace(/"/g, '""') + '"';
}

// Row lookup is by header name, so writers accept any object shape; concrete
// row interfaces (ReportRow, ModerationActionRow, ...) need not carry an
// index signature.
type AnyRow = { [k: string]: unknown };

export function buildCsvRow(headers: readonly string[], row: object): string {
  const r = row as AnyRow;
  const out: string[] = [];
  for (const h of headers) {
    out.push(quote(cellToString(r[h])));
  }
  return out.join(',') + CRLF;
}

export function buildCsvHeader(headers: readonly string[]): string {
  return UTF8_BOM + headers.map((h) => quote(h)).join(',') + CRLF;
}

// Materialises the CSV to a string. For our use (capped at 50k rows) this is
// fine memory-wise and avoids the complexity of constructing a Web ReadableStream.
// If we ever want true streaming we can swap this back to ReadableStream.
export async function csvFromAsyncIterable(
  headers: readonly string[],
  rows: AsyncIterable<object>,
): Promise<string> {
  let out = buildCsvHeader(headers);
  for await (const row of rows) {
    out += buildCsvRow(headers, row);
  }
  return out;
}

// Convenience for one-shot arrays (used by sheets we materialise into the
// bundle's ZIP variant).
export function csvFromArray(
  headers: readonly string[],
  rows: ReadonlyArray<object>,
): string {
  let out = buildCsvHeader(headers);
  for (const row of rows) {
    out += buildCsvRow(headers, row);
  }
  return out;
}
