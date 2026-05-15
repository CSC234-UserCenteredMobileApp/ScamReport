-- ============================================================================
-- AI evaluation harness — labelled cases + per-run summary metrics + per-case
-- results so AI accuracy can be measured (verdict acc, scammer recall@1,
-- scammer MRR, missing-facts F1, p95 latency) and compared run-to-run.
-- ============================================================================

-- CreateTable: ai_eval_cases — the labelled dataset.
CREATE TABLE "ai_eval_cases" (
    "id"                       UUID              NOT NULL DEFAULT gen_random_uuid(),
    "label"                    TEXT              NOT NULL,
    "input_type"               "check_input_kind" NOT NULL,
    "input_payload"            TEXT              NOT NULL,
    "expected_verdict"         "verdict_label"   NOT NULL,
    "expected_scammer_id"      UUID,
    "expected_scam_type_code"  TEXT,
    "expected_missing_facts"   JSONB             NOT NULL DEFAULT '[]'::jsonb,
    "notes"                    TEXT,
    "created_at"               TIMESTAMPTZ       NOT NULL DEFAULT now(),

    CONSTRAINT "ai_eval_cases_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "ai_eval_cases"
    ADD CONSTRAINT "ai_eval_cases_expected_scammer_id_fkey"
    FOREIGN KEY ("expected_scammer_id") REFERENCES "scammers"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;

-- CreateTable: ai_eval_runs — one row per evaluation pass with summary metrics.
CREATE TABLE "ai_eval_runs" (
    "id"                   UUID         NOT NULL DEFAULT gen_random_uuid(),
    "run_at"               TIMESTAMPTZ  NOT NULL DEFAULT now(),
    "total_cases"          INTEGER      NOT NULL,
    "verdict_accuracy"     DOUBLE PRECISION NOT NULL,
    "scammer_recall_at_1"  DOUBLE PRECISION NOT NULL,
    "scammer_mrr"          DOUBLE PRECISION NOT NULL,
    "missing_facts_f1"     DOUBLE PRECISION NOT NULL,
    "p95_latency_ms"       INTEGER      NOT NULL,
    "created_at"           TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT "ai_eval_runs_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "ai_eval_runs_run_at_idx" ON "ai_eval_runs" ("run_at" DESC);

-- CreateTable: ai_eval_results — per-case row inside a run.
CREATE TABLE "ai_eval_results" (
    "id"                    UUID            NOT NULL DEFAULT gen_random_uuid(),
    "run_id"                UUID            NOT NULL,
    "case_id"               UUID            NOT NULL,
    "actual_verdict"        "verdict_label" NOT NULL,
    "actual_scammer_id"     UUID,
    "actual_missing_facts"  JSONB           NOT NULL DEFAULT '[]'::jsonb,
    "scammer_matched"       BOOLEAN         NOT NULL,
    "latency_ms"            INTEGER         NOT NULL,
    "created_at"            TIMESTAMPTZ     NOT NULL DEFAULT now(),

    CONSTRAINT "ai_eval_results_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "ai_eval_results_run_id_idx" ON "ai_eval_results" ("run_id");
CREATE INDEX "ai_eval_results_case_id_idx" ON "ai_eval_results" ("case_id");

ALTER TABLE "ai_eval_results"
    ADD CONSTRAINT "ai_eval_results_run_id_fkey"
    FOREIGN KEY ("run_id") REFERENCES "ai_eval_runs"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "ai_eval_results"
    ADD CONSTRAINT "ai_eval_results_case_id_fkey"
    FOREIGN KEY ("case_id") REFERENCES "ai_eval_cases"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "ai_eval_results"
    ADD CONSTRAINT "ai_eval_results_actual_scammer_id_fkey"
    FOREIGN KEY ("actual_scammer_id") REFERENCES "scammers"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
