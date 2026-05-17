// Orchestrates the export endpoints. Both functions return a Web `Response`
// suitable for direct return from an Elysia handler.
//
// CSV  = single materialised text file streamed back as text/csv.
// XLSX = ExcelJS-built buffer with 8 sheets (meta, summary, reports,
//        moderation_actions, evidence_summary, check_logs, ai_eval_summary,
//        scam_types_reference).
// ZIP  = the same 8 sheets as individual CSV files in a single ZIP.

import type {
  ExportReportsFiltersQuery,
  ExportBundleQuery,
} from '@my-product/shared';
import { resolveFilters, type ResolvedExportFilters } from './filters';
import {
  buildReportsWhere,
  iterateReports,
  iterateModerationActions,
  iterateEvidenceSummary,
  fetchCheckLogsDaily,
  fetchScamTypes,
  type ReportRow,
  type ModerationActionRow,
  type EvidenceSummaryRow,
  type CheckLogDailyRow,
  type ScamTypeRow,
} from './admin-exports.repo';
import { REPORTS_EXPORT_COLUMNS, adminIdSaltVersion } from './privacy';
import { csvFromAsyncIterable, csvFromArray } from './csv';
import { buildXlsxBuffer, type Sheet } from './xlsx';
import { buildZip } from './zip';
import { getPlatformSummary } from '../admin-platform-summary/admin-platform-summary.service';

// ----- timestamps & filenames ------------------------------------------------

function utcTimestamp(now: Date = new Date()): string {
  const y = now.getUTCFullYear();
  const m = String(now.getUTCMonth() + 1).padStart(2, '0');
  const d = String(now.getUTCDate()).padStart(2, '0');
  const hh = String(now.getUTCHours()).padStart(2, '0');
  const mm = String(now.getUTCMinutes()).padStart(2, '0');
  const ss = String(now.getUTCSeconds()).padStart(2, '0');
  return `${y}${m}${d}-${hh}${mm}${ss}`;
}

// ----- Quick CSV -------------------------------------------------------------

export async function buildReportsCsvResponse(
  query: ExportReportsFiltersQuery,
): Promise<Response> {
  const filters = resolveFilters(query, 'csv');
  const where = buildReportsWhere(filters);
  const body = await csvFromAsyncIterable(
    REPORTS_EXPORT_COLUMNS,
    iterateReports(where, filters.limit),
  );
  const filename = `scamreport-reports-${utcTimestamp()}.csv`;
  return new Response(body, {
    status: 200,
    headers: {
      'Content-Type': 'text/csv; charset=utf-8',
      'Content-Disposition': `attachment; filename="${filename}"`,
      'Cache-Control': 'no-store',
    },
  });
}

// ----- Analytics bundle ------------------------------------------------------

interface BundleSheetData {
  meta: Array<Record<string, unknown>>;
  summary: Array<Record<string, unknown>>;
  reports: AsyncIterable<ReportRow>;
  moderationActions: AsyncIterable<ModerationActionRow>;
  evidenceSummary: EvidenceSummaryRow[];
  checkLogs: CheckLogDailyRow[];
  aiEvalSummary: Array<Record<string, unknown>>;
  scamTypes: ScamTypeRow[];
}

const META_HEADERS = ['exportedAt', 'exportType', 'confidentiality', 'filtersJson', 'rowLimit', 'adminIdSaltVersion'] as const;
const SUMMARY_HEADERS = [
  'metric',
  'value',
  'scope',
] as const;
const MODERATION_HEADERS = [
  'reportId',
  'reportCreatedAt',
  'adminIdHash',
  'action',
  'remark',
  'createdAt',
  'timeToActionSeconds',
] as const;
const EVIDENCE_HEADERS = ['reportId', 'kind', 'fileCount', 'totalSizeBytes'] as const;
const CHECK_LOG_HEADERS = ['day', 'verdict', 'calls', 'p95LatencyMs'] as const;
const AI_EVAL_HEADERS = ['note', 'generatedAt'] as const;
const SCAM_TYPE_HEADERS = ['code', 'labelEn', 'labelTh'] as const;

async function gatherBundleData(filters: ResolvedExportFilters): Promise<BundleSheetData> {
  const where = buildReportsWhere(filters);
  const fromIso = filters.from ? filters.from.toISOString() : undefined;
  const toIso = filters.to ? filters.to.toISOString() : undefined;

  const summary = await getPlatformSummary(fromIso, toIso);
  const evidence = await iterateEvidenceSummary(where);
  const checkLogs = await fetchCheckLogsDaily(filters.from, filters.to);
  const scamTypes = await fetchScamTypes();

  const meta: BundleSheetData['meta'] = [
    {
      exportedAt: new Date().toISOString(),
      exportType: 'analytics_bundle',
      confidentiality: 'admin-only-do-not-redistribute',
      filtersJson: JSON.stringify({
        status: filters.status ?? null,
        scamType: filters.scamType ?? null,
        priorityOnly: filters.priorityOnly,
        confidence: filters.confidence ?? null,
        from: fromIso ?? null,
        to: toIso ?? null,
      }),
      rowLimit: filters.limit,
      adminIdSaltVersion: adminIdSaltVersion(),
    },
  ];

  const summaryRows: BundleSheetData['summary'] = [
    { metric: 'reports.total', value: summary.reports.total, scope: 'date_range' },
    { metric: 'reports.verified', value: summary.reports.verified, scope: 'date_range' },
    { metric: 'reports.pending', value: summary.reports.pending, scope: 'date_range' },
    { metric: 'reports.rejected', value: summary.reports.rejected, scope: 'date_range' },
    { metric: 'reports.flagged', value: summary.reports.flagged, scope: 'date_range' },
    { metric: 'checkLogs.total', value: summary.checkLogs.total, scope: 'date_range' },
    { metric: 'checkLogs.verdict.scam', value: summary.checkLogs.verdictMix.scam, scope: 'date_range' },
    { metric: 'checkLogs.verdict.suspicious', value: summary.checkLogs.verdictMix.suspicious, scope: 'date_range' },
    { metric: 'checkLogs.verdict.safe', value: summary.checkLogs.verdictMix.safe, scope: 'date_range' },
    { metric: 'checkLogs.verdict.unknown', value: summary.checkLogs.verdictMix.unknown, scope: 'date_range' },
    ...summary.scamTypeBreakdown.map((b) => ({
      metric: `scamType.${b.scamTypeCode}`,
      value: b.count,
      scope: 'date_range',
    })),
    ...summary.topScammers.map((s) => ({
      metric: `topScammer.${s.id}`,
      value: s.reportCount,
      scope: `displayName=${s.displayName}; risk=${s.riskLevel}`,
    })),
  ];

  const aiEvalSummary: BundleSheetData['aiEvalSummary'] = [
    {
      note:
        'Not yet wired — see DATABASE_DESIGN.md §4.15 (ai_eval_cases / ai_eval_runs / ai_eval_results). Replace this row when /admin/ai-eval/run lands.',
      generatedAt: new Date().toISOString(),
    },
  ];

  return {
    meta,
    summary: summaryRows,
    reports: iterateReports(where, filters.limit),
    moderationActions: iterateModerationActions(where, filters.limit),
    evidenceSummary: evidence,
    checkLogs,
    aiEvalSummary,
    scamTypes,
  };
}

export async function buildBundleResponse(
  query: ExportBundleQuery,
): Promise<Response> {
  const format = query.format === 'zip' ? 'zip' : 'xlsx';
  const filters = resolveFilters(query, 'bundle');
  const data = await gatherBundleData(filters);
  const ts = utcTimestamp();

  if (format === 'zip') {
    const reportsCsv = await csvFromAsyncIterable(REPORTS_EXPORT_COLUMNS, data.reports);
    const moderationCsv = await csvFromAsyncIterable(MODERATION_HEADERS, data.moderationActions);
    const body = buildZip([
      { filename: '_meta.csv', content: csvFromArray(META_HEADERS, data.meta) },
      { filename: 'summary.csv', content: csvFromArray(SUMMARY_HEADERS, data.summary) },
      { filename: 'reports.csv', content: reportsCsv },
      { filename: 'moderation_actions.csv', content: moderationCsv },
      { filename: 'evidence_summary.csv', content: csvFromArray(EVIDENCE_HEADERS, data.evidenceSummary) },
      { filename: 'check_logs.csv', content: csvFromArray(CHECK_LOG_HEADERS, data.checkLogs) },
      { filename: 'ai_eval_summary.csv', content: csvFromArray(AI_EVAL_HEADERS, data.aiEvalSummary) },
      { filename: 'scam_types_reference.csv', content: csvFromArray(SCAM_TYPE_HEADERS, data.scamTypes) },
    ]);
    const filename = `scamreport-bundle-${ts}.zip`;
    return new Response(body as BodyInit, {
      status: 200,
      headers: {
        'Content-Type': 'application/zip',
        'Content-Disposition': `attachment; filename="${filename}"`,
        'Cache-Control': 'no-store',
      },
    });
  }

  // XLSX
  const sheets: Sheet[] = [
    { name: '_meta', headers: META_HEADERS, rows: data.meta },
    { name: 'summary', headers: SUMMARY_HEADERS, rows: data.summary },
    { name: 'reports', headers: REPORTS_EXPORT_COLUMNS, rows: data.reports },
    { name: 'moderation_actions', headers: MODERATION_HEADERS, rows: data.moderationActions },
    { name: 'evidence_summary', headers: EVIDENCE_HEADERS, rows: data.evidenceSummary },
    { name: 'check_logs', headers: CHECK_LOG_HEADERS, rows: data.checkLogs },
    { name: 'ai_eval_summary', headers: AI_EVAL_HEADERS, rows: data.aiEvalSummary },
    { name: 'scam_types_reference', headers: SCAM_TYPE_HEADERS, rows: data.scamTypes },
  ];
  const buf = await buildXlsxBuffer(sheets);
  const filename = `scamreport-bundle-${ts}.xlsx`;
  return new Response(buf as BodyInit, {
    status: 200,
    headers: {
      'Content-Type':
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'Content-Disposition': `attachment; filename="${filename}"`,
      'Cache-Control': 'no-store',
    },
  });
}
