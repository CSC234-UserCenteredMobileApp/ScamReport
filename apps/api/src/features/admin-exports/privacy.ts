// Privacy controls for the export endpoints. Designed so a reviewer can
// verify "no reporter PII can leak" by reading just this file.
//
//   - REPORTS_EXPORT_COLUMNS is the allow-list for the reports sheet. Repo
//     layer selects exactly these columns; no other field can reach output.
//   - hashAdminId() converts admin UUIDs to a 12-char salted SHA-256 digest
//     for the moderation_actions sheet. Salt rotation deliberately breaks
//     cross-export correlation (security-positive). In production the salt
//     MUST be configured — boot-time check throws to fail loud.
//   - adminIdSaltVersion() returns a short non-reversible identifier for the
//     active salt, recorded in the export's _meta sheet so analysts can tell
//     when correlations across files are no longer valid.

import { createHash } from 'node:crypto';

const SALT = process.env.EXPORT_ADMIN_ID_SALT ?? '';

// SHA256(SALT) -> '' has zero protection against rainbow tables over the small
// admin UUID space, so production refuses to mount when the env is missing.
// In dev / test the empty fallback is acceptable and silent.
const IS_PROD =
  process.env.NODE_ENV === 'production' || process.env.BUN_ENV === 'production';
if (IS_PROD && SALT === '') {
  throw new Error(
    'EXPORT_ADMIN_ID_SALT must be set in production (admin-exports privacy).',
  );
}

export function hashAdminId(adminId: string | null | undefined): string {
  if (!adminId) return 'system';
  return createHash('sha256').update(SALT + adminId).digest('hex').slice(0, 12);
}

// Short, non-reversible tag for the current salt. Embedded in the _meta sheet
// so analysts can detect "this export came from a different salt era and
// admin_id_hash values are no longer comparable to earlier exports."
export function adminIdSaltVersion(): string {
  if (SALT === '') return 'unsalted';
  return createHash('sha256').update(SALT).digest('hex').slice(0, 8);
}

// Allow-list of columns that may appear in the `reports` export sheet.
// admin-exports.repo.ts uses this as the source of truth for its Prisma
// `select`. Anything not on this list cannot reach the export.
export const REPORTS_EXPORT_COLUMNS = [
  'id',
  'title',
  'description',
  'scamTypeCode',
  'scamTypeLabelEn',
  'scamTypeLabelTh',
  'targetIdentifierKind',
  'targetIdentifierNormalized',
  'status',
  'priorityFlag',
  'rejectionRemark',
  'aiScore',
  'aiConfidence',
  'suspectedNameAtSubmit',
  'scammerId',
  'createdAt',
  'updatedAt',
  'verifiedAt',
] as const;

export type ReportExportColumn = (typeof REPORTS_EXPORT_COLUMNS)[number];
