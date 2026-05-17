// /admin/exports/* — bulk exports for offline analysis.
//
//   GET /admin/exports/reports.csv  — one row per report, current filters,
//                                     no date bound by default (scope='csv').
//   GET /admin/exports/bundle       — multi-sheet XLSX (default) or ZIP of
//                                     CSVs (?format=zip), last 30 days by
//                                     default (scope='bundle').
//
// Both gated by requireRole('admin'). Reporter identity is never serialised
// (see ./privacy.ts allow-list).

import { Elysia } from 'elysia';
import {
  ExportReportsFiltersQuery,
  ExportBundleQuery,
} from '@my-product/shared';
import { requireRole } from '../../core/middleware/require_role';
import {
  buildReportsCsvResponse,
  buildBundleResponse,
} from './admin-exports.service';

export const adminExportsRoute = new Elysia({ prefix: '/admin/exports' })
  .use(requireRole('admin'))
  .get('/reports.csv', async ({ query }) => buildReportsCsvResponse(query), {
    query: ExportReportsFiltersQuery,
  })
  .get('/bundle', async ({ query }) => buildBundleResponse(query), {
    query: ExportBundleQuery,
  });
