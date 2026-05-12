-- Persist AI similarity score + confidence on reports.
--
-- Both nullable: legacy rows submitted before this migration stay null and
-- the UI hides the AI score widget; future submissions compute and persist
-- the values inside the submit handler (apps/api/src/features/reports).
--
-- See apps/api/src/core/ai-score for the scoring helper + thresholds.

ALTER TABLE "reports"
  ADD COLUMN "ai_score" INTEGER,
  ADD COLUMN "ai_confidence" TEXT;

-- Constrain score range. Enum on confidence is intentionally kept loose
-- (TEXT) because the union lives in the shared TypeBox schema; adding a
-- Postgres enum here would couple two sources of truth.
ALTER TABLE "reports"
  ADD CONSTRAINT "reports_ai_score_range_chk"
  CHECK ("ai_score" IS NULL OR ("ai_score" >= 0 AND "ai_score" <= 100));
