// Translates the wire-shape ExportReportsFiltersQuery into a structured
// filter the repo + service layers can use. Per-mode defaults (Quick CSV vs
// Analytics bundle) are applied here so handlers stay terse.
//
// `status` arrives as comma-separated text (e.g. "pending,flagged") because
// Elysia query params are strings. Per-mode default:
//   - 'csv'    → ['pending', 'flagged'] (mirrors the queue page)
//   - 'bundle' → undefined (no filter — bundle is for platform-quality analysis)
//
// `from`/`to` per-mode default:
//   - 'csv'    → unbounded
//   - 'bundle' → last 30 days (matches admin-platform-summary.service.ts)

import {
  type ExportReportsFiltersQuery,
  type ExportStatusValue,
  type ExportConfidenceValue,
  EXPORT_ROW_LIMIT_DEFAULT,
  EXPORT_ROW_LIMIT_MAX,
} from '@my-product/shared';

export type ExportScope = 'csv' | 'bundle';

export interface ResolvedExportFilters {
  status?: ExportStatusValue[];
  scamType?: string;
  priorityOnly: boolean;
  confidence?: ExportConfidenceValue;
  from: Date | undefined;
  to: Date | undefined;
  limit: number;
}

const VALID_STATUSES: ReadonlySet<ExportStatusValue> = new Set([
  'pending',
  'verified',
  'rejected',
  'flagged',
  'withdrawn',
]);

function parseStatusList(
  raw: string | undefined,
  scope: ExportScope,
): ExportStatusValue[] | undefined {
  if (raw === undefined || raw === '') {
    return scope === 'csv' ? ['pending', 'flagged'] : undefined;
  }
  const parts = raw
    .split(',')
    .map((s) => s.trim().toLowerCase())
    .filter((s) => s.length > 0);
  const valid = parts.filter((s): s is ExportStatusValue =>
    VALID_STATUSES.has(s as ExportStatusValue),
  );
  return valid.length > 0 ? valid : undefined;
}

function parseDateRange(
  fromIso: string | undefined,
  toIso: string | undefined,
  scope: ExportScope,
): { from: Date | undefined; to: Date | undefined } {
  const to = toIso ? new Date(toIso) : undefined;
  const from = fromIso ? new Date(fromIso) : undefined;

  if (scope === 'csv') {
    return { from, to };
  }
  // Bundle: default to last 30 days when caller omits either side.
  const resolvedTo = to ?? new Date();
  const resolvedFrom =
    from ?? new Date(resolvedTo.getTime() - 30 * 24 * 60 * 60 * 1000);
  return { from: resolvedFrom, to: resolvedTo };
}

export function resolveFilters(
  query: ExportReportsFiltersQuery,
  scope: ExportScope,
): ResolvedExportFilters {
  const { from, to } = parseDateRange(query.from, query.to, scope);
  const parsedLimit = query.limit ? Number.parseInt(query.limit, 10) : NaN;
  const limit =
    Number.isFinite(parsedLimit) && parsedLimit > 0
      ? Math.min(parsedLimit, EXPORT_ROW_LIMIT_MAX)
      : EXPORT_ROW_LIMIT_DEFAULT;

  return {
    status: parseStatusList(query.status, scope),
    scamType: query.scamType,
    priorityOnly: query.priority === 'true',
    confidence: query.confidence,
    from,
    to,
    limit,
  };
}
