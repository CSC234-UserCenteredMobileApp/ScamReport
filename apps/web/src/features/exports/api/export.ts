// Wraps downloadBlob with URLSearchParams construction for the two export
// endpoints. The server applies per-mode defaults (see admin-exports filters
// table); the client just passes through what the user picked.

import { downloadBlob } from '@/lib/api/download-blob';

export type ExportConfidence = 'high' | 'medium' | 'low' | 'unknown';

export interface ExportFilters {
  status?: string[];           // ['pending','flagged','verified',...] — comma-joined on the wire
  scamType?: string;
  priority?: boolean;
  confidence?: ExportConfidence;
  from?: string;               // ISO 8601 with offset
  to?: string;
}

function buildQuery(filters: ExportFilters, extra: Record<string, string> = {}): string {
  const p = new URLSearchParams();
  if (filters.status && filters.status.length > 0) p.set('status', filters.status.join(','));
  if (filters.scamType) p.set('scamType', filters.scamType);
  if (filters.priority) p.set('priority', 'true');
  if (filters.confidence) p.set('confidence', filters.confidence);
  if (filters.from) p.set('from', filters.from);
  if (filters.to) p.set('to', filters.to);
  for (const [k, v] of Object.entries(extra)) p.set(k, v);
  const s = p.toString();
  return s.length > 0 ? `?${s}` : '';
}

export async function downloadReportsCsv(filters: ExportFilters): Promise<void> {
  await downloadBlob(`/admin/exports/reports.csv${buildQuery(filters)}`, 'scamreport-reports.csv');
}

export async function downloadBundle(
  filters: ExportFilters,
  format: 'xlsx' | 'zip',
): Promise<void> {
  await downloadBlob(
    `/admin/exports/bundle${buildQuery(filters, { format })}`,
    `scamreport-bundle.${format}`,
  );
}
