// Query schemas for the admin export endpoints under /admin/exports/*.
//
// The endpoints return binary streams (CSV, XLSX, or ZIP) so there is no
// response schema. The query shape is shared between the API (Elysia
// validator) and the admin web (URLSearchParams builder).
//
// Privacy posture (enforced server-side in apps/api/src/features/admin-exports/
// privacy.ts and admin-exports.repo.ts):
//   - Reporter identity is never serialised (no reporter_id, no email, no
//     firebase uid).
//   - Admin identity in the moderation audit sheet is hashed (12-char salted
//     SHA-256) — spreadsheets routinely leave the building.
//   - Evidence storage paths and signed URLs are categorically omitted; only
//     count + total size per (report_id, kind) are exposed.

import { Type, type Static } from '@sinclair/typebox';

export const ExportStatusValue = Type.Union([
  Type.Literal('pending'),
  Type.Literal('verified'),
  Type.Literal('rejected'),
  Type.Literal('flagged'),
  Type.Literal('withdrawn'),
]);
export type ExportStatusValue = Static<typeof ExportStatusValue>;

export const ExportConfidenceValue = Type.Union([
  Type.Literal('high'),
  Type.Literal('medium'),
  Type.Literal('low'),
  Type.Literal('unknown'),
]);
export type ExportConfidenceValue = Static<typeof ExportConfidenceValue>;

// Common filter shape consumed by both CSV and bundle endpoints. All fields
// are optional; per-mode defaults are applied server-side (see plan §A
// scope-of-data table).
//
//   status     — comma-separated list of ExportStatusValue. CSV scope default
//                = 'pending,flagged' (mirrors the queue page). Bundle scope
//                default = unset (all statuses).
//   scamType   — ScamType.code (e.g. 'phone_imp'); matches the queue filter.
//   priority   — 'true' to require priority_flag = true.
//   confidence — single ExportConfidenceValue tier.
//   from / to  — ISO 8601 date-time bounds for reports.createdAt. CSV
//                default = no bound. Bundle default = last 30 days (matches
//                admin-platform-summary.service.ts).
//   limit      — hard cap on streamed rows; server applies a smaller cap if
//                this is omitted. TypeBox-enforced max prevents abuse.
//
// All values arrive as strings on the wire — Elysia/TypeBox parses query
// params from URLSearchParams.
export const ExportReportsFiltersQuery = Type.Object({
  status: Type.Optional(Type.String()),
  scamType: Type.Optional(Type.String()),
  priority: Type.Optional(Type.String()),
  confidence: Type.Optional(ExportConfidenceValue),
  from: Type.Optional(Type.String({ format: 'date-time' })),
  to: Type.Optional(Type.String({ format: 'date-time' })),
  limit: Type.Optional(
    Type.String({ pattern: '^[0-9]+$' }),
  ),
});
export type ExportReportsFiltersQuery = Static<typeof ExportReportsFiltersQuery>;

// Bundle endpoint = filters + an explicit `format` knob for one-file XLSX vs
// multi-CSV ZIP. The dialog defaults `format=xlsx`; ZIP is the safe fallback
// when XLSX streaming hits a Bun stream-compat issue.
export const ExportBundleQuery = Type.Composite([
  ExportReportsFiltersQuery,
  Type.Object({
    format: Type.Optional(
      Type.Union([Type.Literal('xlsx'), Type.Literal('zip')]),
    ),
  }),
]);
export type ExportBundleQuery = Static<typeof ExportBundleQuery>;

// Hard upper bound for `limit`. Enforced at the route handler — TypeBox parses
// the string then the handler clamps. 50k rows ≈ 5–10 MB XLSX which is still
// browser-blob-downloadable. Beyond that we'd need a different UX.
export const EXPORT_ROW_LIMIT_MAX = 50000;
export const EXPORT_ROW_LIMIT_DEFAULT = 50000;
