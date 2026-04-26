-- ============================================================================
-- Scam Report Platform — initial schema
-- See DATABASE_DESIGN.md (repo root) for the canonical design rationale.
-- This migration is hand-written rather than `prisma migrate dev` output
-- because it includes pgvector, citext, custom triggers, and seed data that
-- Prisma's schema language can't model.
--
-- NOT included in this migration (deliberate, see DATABASE_DESIGN.md §7 + §10):
--   - Row-Level Security policies + the current_firebase_uid() helper. These
--     are meaningful only after a non-superuser app role is configured on the
--     database; we'll add them in a follow-up migration.
--   - Outbound-notification outbox table (DESIGN §9: "not at MVP").
--   - Materialised views for aggregate stats (DESIGN §9).
-- ============================================================================

-- 1. Extensions ---------------------------------------------------------------

CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "citext";     -- case-insensitive text
CREATE EXTENSION IF NOT EXISTS "vector";     -- pgvector for RAG semantic search

-- 2. Helper functions ---------------------------------------------------------

-- Generic updated_at trigger fn — attached to every table that has updated_at.
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Enums --------------------------------------------------------------------

CREATE TYPE "user_role"         AS ENUM ('user', 'admin');
CREATE TYPE "preferred_lang"    AS ENUM ('th', 'en');
CREATE TYPE "report_status"     AS ENUM ('pending', 'verified', 'rejected', 'flagged', 'withdrawn');
CREATE TYPE "identifier_kind"   AS ENUM ('phone', 'url', 'other');
CREATE TYPE "evidence_kind"     AS ENUM ('image', 'pdf');
CREATE TYPE "moderation_action" AS ENUM ('approve', 'reject', 'flag', 'unflag');
CREATE TYPE "verdict_label"     AS ENUM ('scam', 'suspicious', 'safe', 'unknown');
CREATE TYPE "check_input_kind"  AS ENUM ('phone', 'url', 'text');
CREATE TYPE "announcement_cat"  AS ENUM ('fraud_alert', 'tips', 'platform_update');
CREATE TYPE "announcement_stat" AS ENUM ('draft', 'published', 'unpublished');
CREATE TYPE "consent_kind"      AS ENUM ('registration', 'first_report_submission', 'privacy_policy', 'terms_of_service');

-- 4. Tables -------------------------------------------------------------------

-- 4.1 users
CREATE TABLE "users" (
    "id"                 UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    "firebase_uid"       TEXT            NOT NULL UNIQUE,
    "email"              CITEXT          UNIQUE,
    "display_name"       TEXT,
    "role"               "user_role"     NOT NULL DEFAULT 'user',
    "preferred_language" "preferred_lang" NOT NULL DEFAULT 'th',
    "created_at"         TIMESTAMPTZ     NOT NULL DEFAULT now(),
    "updated_at"         TIMESTAMPTZ     NOT NULL DEFAULT now(),
    "deleted_at"         TIMESTAMPTZ
);

CREATE INDEX "users_role_idx"      ON "users" ("role");
CREATE INDEX "users_admin_idx"     ON "users" ("role") WHERE "role" = 'admin';

CREATE TRIGGER "users_set_updated_at"
BEFORE UPDATE ON "users"
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 4.2 consent_records (append-only, per PDPA §6.3)
CREATE TABLE "consent_records" (
    "id"             UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id"        UUID          REFERENCES "users"("id") ON DELETE SET NULL,
    "consent_type"   "consent_kind" NOT NULL,
    "policy_version" TEXT          NOT NULL,
    "accepted_at"    TIMESTAMPTZ   NOT NULL DEFAULT now(),
    "ip_address"     INET,
    "user_agent"     TEXT
);

-- 4.3 scam_types (taxonomy)
CREATE TABLE "scam_types" (
    "id"            SMALLINT PRIMARY KEY,
    "code"          TEXT     NOT NULL UNIQUE,
    "label_en"      TEXT     NOT NULL,
    "label_th"      TEXT     NOT NULL,
    "is_active"     BOOLEAN  NOT NULL DEFAULT true,
    "display_order" SMALLINT NOT NULL DEFAULT 0
);

-- 4.4 reports
CREATE TABLE "reports" (
    "id"                            UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
    "reporter_id"                   UUID             REFERENCES "users"("id") ON DELETE SET NULL,
    "title"                         TEXT             NOT NULL,
    "description"                   TEXT             NOT NULL,
    "scam_type_id"                  SMALLINT         NOT NULL REFERENCES "scam_types"("id"),
    "target_identifier"             TEXT,
    "target_identifier_kind"        "identifier_kind",
    "target_identifier_normalized"  CITEXT,
    "status"                        "report_status"  NOT NULL DEFAULT 'pending',
    "priority_flag"                 BOOLEAN          NOT NULL DEFAULT false,
    "rejection_remark"              TEXT,
    "created_at"                    TIMESTAMPTZ      NOT NULL DEFAULT now(),
    "updated_at"                    TIMESTAMPTZ      NOT NULL DEFAULT now(),
    "verified_at"                   TIMESTAMPTZ,

    CONSTRAINT "reports_title_length"       CHECK (char_length("title") BETWEEN 3 AND 200),
    CONSTRAINT "reports_description_length" CHECK (char_length("description") >= 10)
);

CREATE INDEX "reports_status_created_idx"  ON "reports" ("status", "created_at" DESC);
CREATE INDEX "reports_reporter_created_idx" ON "reports" ("reporter_id", "created_at" DESC);
CREATE INDEX "reports_scam_type_idx"       ON "reports" ("scam_type_id");
CREATE INDEX "reports_verified_feed_idx"   ON "reports" ("verified_at" DESC) WHERE "status" = 'verified';
CREATE INDEX "reports_target_lookup_idx"   ON "reports" ("target_identifier_normalized") WHERE "status" = 'verified';
CREATE INDEX "reports_scam_type_feed_idx"  ON "reports" ("scam_type_id", "verified_at" DESC) WHERE "status" = 'verified';

CREATE TRIGGER "reports_set_updated_at"
BEFORE UPDATE ON "reports"
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 4.5 evidence_files (≤5 per report enforced by trigger below)
CREATE TABLE "evidence_files" (
    "id"           UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    "report_id"    UUID            NOT NULL REFERENCES "reports"("id") ON DELETE CASCADE,
    "storage_path" TEXT            NOT NULL UNIQUE,
    "kind"         "evidence_kind" NOT NULL,
    "mime_type"    TEXT            NOT NULL,
    "size_bytes"   BIGINT          NOT NULL,
    "uploaded_at"  TIMESTAMPTZ     NOT NULL DEFAULT now(),

    CONSTRAINT "evidence_files_size_positive" CHECK ("size_bytes" > 0)
);

CREATE OR REPLACE FUNCTION enforce_evidence_files_limit()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(*) FROM "evidence_files" WHERE "report_id" = NEW.report_id) >= 5 THEN
        RAISE EXCEPTION 'A report may have at most 5 evidence files'
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "evidence_files_max_5"
BEFORE INSERT ON "evidence_files"
FOR EACH ROW EXECUTE FUNCTION enforce_evidence_files_limit();

-- 4.6 moderation_actions (immutable audit log)
CREATE TABLE "moderation_actions" (
    "id"         UUID                  PRIMARY KEY DEFAULT gen_random_uuid(),
    "report_id"  UUID                  NOT NULL REFERENCES "reports"("id") ON DELETE RESTRICT,
    "admin_id"   UUID                  REFERENCES "users"("id") ON DELETE SET NULL,
    "action"     "moderation_action"   NOT NULL,
    "remark"     TEXT                  NOT NULL,
    "created_at" TIMESTAMPTZ           NOT NULL DEFAULT now()
);

CREATE INDEX "moderation_actions_report_idx" ON "moderation_actions" ("report_id", "created_at" DESC);

-- Status sync: when a moderation action is recorded, mirror its effect onto
-- reports.status (and rejection_remark / verified_at where applicable).
-- Approve/reject also enqueue the FCM notification at the application layer
-- when this row is inserted; that's the application's concern, not Postgres'.
CREATE OR REPLACE FUNCTION sync_report_status_from_moderation()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.action = 'approve' THEN
        UPDATE "reports"
           SET "status"           = 'verified',
               "verified_at"      = now(),
               "rejection_remark" = NULL
         WHERE "id" = NEW.report_id;
    ELSIF NEW.action = 'reject' THEN
        UPDATE "reports"
           SET "status"           = 'rejected',
               "rejection_remark" = NEW.remark
         WHERE "id" = NEW.report_id;
    ELSIF NEW.action = 'flag' THEN
        UPDATE "reports"
           SET "status" = 'flagged'
         WHERE "id" = NEW.report_id;
    ELSIF NEW.action = 'unflag' THEN
        UPDATE "reports"
           SET "status" = 'pending'
         WHERE "id" = NEW.report_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "moderation_actions_sync_status"
AFTER INSERT ON "moderation_actions"
FOR EACH ROW EXECUTE FUNCTION sync_report_status_from_moderation();

-- Reject UPDATE / DELETE on the audit log — append-only by policy.
CREATE OR REPLACE FUNCTION reject_audit_mutation()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'moderation_actions is append-only — no UPDATE or DELETE allowed';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "moderation_actions_no_update"
BEFORE UPDATE ON "moderation_actions"
FOR EACH ROW EXECUTE FUNCTION reject_audit_mutation();

CREATE TRIGGER "moderation_actions_no_delete"
BEFORE DELETE ON "moderation_actions"
FOR EACH ROW EXECUTE FUNCTION reject_audit_mutation();

-- 4.7 report_embeddings (one row per report; vector(768) for Gemini text-embedding-004)
CREATE TABLE "report_embeddings" (
    "report_id"     UUID         PRIMARY KEY REFERENCES "reports"("id") ON DELETE CASCADE,
    "embedding"     vector(768)  NOT NULL,
    "content_hash"  TEXT         NOT NULL,
    "model_version" TEXT         NOT NULL,
    "updated_at"    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ivfflat index — start with lists=100, switch to hnsw once dataset > ~10k rows.
CREATE INDEX "report_embeddings_ivfflat_idx"
    ON "report_embeddings"
    USING ivfflat ("embedding" vector_cosine_ops)
    WITH (lists = 100);

CREATE TRIGGER "report_embeddings_set_updated_at"
BEFORE UPDATE ON "report_embeddings"
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 4.8 announcements
CREATE TABLE "announcements" (
    "id"                UUID                  PRIMARY KEY DEFAULT gen_random_uuid(),
    "author_id"         UUID                  REFERENCES "users"("id") ON DELETE SET NULL,
    "slug"              TEXT                  NOT NULL UNIQUE,
    "title"             TEXT                  NOT NULL,
    "body"              TEXT                  NOT NULL,
    "category"          "announcement_cat"    NOT NULL,
    "status"            "announcement_stat"   NOT NULL DEFAULT 'draft',
    "pushed_to_fcm_at"  TIMESTAMPTZ,
    "published_at"      TIMESTAMPTZ,
    "created_at"        TIMESTAMPTZ           NOT NULL DEFAULT now(),
    "updated_at"        TIMESTAMPTZ           NOT NULL DEFAULT now()
);

CREATE INDEX "announcements_published_idx"
    ON "announcements" ("status", "published_at" DESC)
    WHERE "status" = 'published';

CREATE TRIGGER "announcements_set_updated_at"
BEFORE UPDATE ON "announcements"
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 4.9 fcm_devices (Android-only — no platform column per PRD §6.6)
CREATE TABLE "fcm_devices" (
    "id"           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id"      UUID         NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
    "fcm_token"    TEXT         NOT NULL UNIQUE,
    "app_version"  TEXT,
    "last_seen_at" TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX "fcm_devices_user_idx" ON "fcm_devices" ("user_id");

-- 4.10 check_logs
CREATE TABLE "check_logs" (
    "id"               UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id"          UUID                REFERENCES "users"("id") ON DELETE SET NULL,
    "input_kind"       "check_input_kind"  NOT NULL,
    "input_normalized" CITEXT              NOT NULL,
    "input_hash"       TEXT                NOT NULL,
    "verdict"          "verdict_label"     NOT NULL,
    "match_count"      INTEGER             NOT NULL DEFAULT 0,
    "latency_ms"       INTEGER,
    "created_at"       TIMESTAMPTZ         NOT NULL DEFAULT now()
);

CREATE INDEX "check_logs_input_idx" ON "check_logs" ("input_normalized", "created_at" DESC);

-- 4.11 search_queries
CREATE TABLE "search_queries" (
    "id"            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id"       UUID         REFERENCES "users"("id") ON DELETE SET NULL,
    "query_text"    TEXT         NOT NULL,
    "results_count" INTEGER      NOT NULL,
    "top_result_id" UUID         REFERENCES "reports"("id") ON DELETE SET NULL,
    "created_at"    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- 4.12 account_deletion_requests
CREATE TABLE "account_deletion_requests" (
    "id"           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id"      UUID         NOT NULL UNIQUE REFERENCES "users"("id") ON DELETE CASCADE,
    "requested_at" TIMESTAMPTZ  NOT NULL DEFAULT now(),
    "purge_due_at" TIMESTAMPTZ  NOT NULL,
    "purged_at"    TIMESTAMPTZ
);

-- 5. Seed data ----------------------------------------------------------------

INSERT INTO "scam_types" ("id", "code", "label_en", "label_th", "display_order") VALUES
    (1, 'phone_impersonation', 'Phone impersonation', 'แอบอ้างทางโทรศัพท์',     10),
    (2, 'phishing_sms',        'Phishing SMS',        'SMS หลอกลวง',             20),
    (3, 'fake_qr',             'Fake QR code',        'QR Code ปลอม',            30),
    (4, 'ecommerce_fraud',     'E-commerce fraud',    'หลอกลวงการซื้อขายออนไลน์', 40),
    (5, 'other',               'Other',               'อื่น ๆ',                  99);

-- ============================================================================
-- TODO (next migration):
--   - Create non-superuser app role with table-level GRANTs.
--   - CREATE FUNCTION current_firebase_uid() reading current_setting('app.firebase_uid').
--   - ENABLE ROW LEVEL SECURITY on all tables and add policies per
--     DATABASE_DESIGN.md §7.
-- ============================================================================
