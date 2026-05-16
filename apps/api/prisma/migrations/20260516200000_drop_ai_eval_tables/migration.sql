-- AI Eval feature retired. Drop the three tables + their FKs. The
-- scammer FK columns were ON DELETE SET NULL so dropping is non-cascading
-- on the parent side; we order children before parents.

DROP TABLE IF EXISTS "ai_eval_results";
DROP TABLE IF EXISTS "ai_eval_runs";
DROP TABLE IF EXISTS "ai_eval_cases";
