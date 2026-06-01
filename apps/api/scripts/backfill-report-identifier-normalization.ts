// One-off backfill: re-normalise `reports.target_identifier_normalized` from
// the RAW `target_identifier` using the canonical `normalizePhone` /
// `normalizeUrl`. Fixes rows written before the write path was unified with
// the /check read path (phones stored as `0XXXXXXXXX` instead of `+66…`, and
// URLs via `.host` instead of `.hostname`), which made verified reports
// invisible to POST /check and the opportunistic scammer auto-link.
//
// Re-derives from the raw column (single source of truth) — does NOT hand-roll
// a SQL re-encode. Default is DRY-RUN: it prints what would change and writes
// nothing. Pass `--apply` to commit.
//
// Usage (from repo root):
//
//   bun run --filter @my-product/api tsx scripts/backfill-report-identifier-normalization.ts          # dry-run
//   bun run --filter @my-product/api tsx scripts/backfill-report-identifier-normalization.ts --apply   # commit
//
// (or `bun apps/api/scripts/backfill-report-identifier-normalization.ts [--apply]`)
//
// Safe to re-run: only rows whose recomputed value differs are touched. There
// is no unique index on `target_identifier_normalized`, so collisions are fine.

import 'dotenv/config';
import { getPrisma } from '../src/core/db/client';
import {
  normalizePhone,
  normalizeUrl,
} from '../src/core/lib/identifier-extractor';

function recompute(
  raw: string | null,
  kind: string | null,
): string | null {
  if (!raw) return null;
  const trimmed = raw.trim();
  if (!trimmed) return null;
  if (kind === 'phone') return normalizePhone(trimmed);
  if (kind === 'url') return normalizeUrl(trimmed);
  return trimmed.toLowerCase();
}

async function main(): Promise<void> {
  const apply = process.argv.includes('--apply');
  const prisma = getPrisma();

  const rows = await prisma.report.findMany({
    where: { targetIdentifierKind: { in: ['phone', 'url', 'other'] } },
    select: {
      id: true,
      targetIdentifier: true,
      targetIdentifierKind: true,
      targetIdentifierNormalized: true,
    },
  });

  let changed = 0;
  for (const r of rows) {
    const next = recompute(r.targetIdentifier, r.targetIdentifierKind);
    if (next === r.targetIdentifierNormalized) continue;
    changed++;
    // eslint-disable-next-line no-console
    console.log(
      `${apply ? 'UPDATE' : 'WOULD UPDATE'} ${r.id} [${r.targetIdentifierKind}] ` +
        `${JSON.stringify(r.targetIdentifierNormalized)} -> ${JSON.stringify(next)}`,
    );
    if (apply) {
      await prisma.report.update({
        where: { id: r.id },
        data: { targetIdentifierNormalized: next },
      });
    }
  }

  // eslint-disable-next-line no-console
  console.log(
    `\n${apply ? 'Applied' : 'Dry-run'}: ${changed} of ${rows.length} rows ` +
      `${apply ? 'updated' : 'would change'}.` +
      (apply ? '' : '  Re-run with --apply to commit.'),
  );
}

main()
  .then(() => process.exit(0))
  .catch((e) => {
    // eslint-disable-next-line no-console
    console.error(e);
    process.exit(1);
  });
