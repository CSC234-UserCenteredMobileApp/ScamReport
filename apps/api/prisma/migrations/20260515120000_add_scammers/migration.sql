-- ============================================================================
-- Scammer entity — separate offender profile from incident facts.
-- See plan: separate scammer info from cases so AI can aggregate by offender,
-- improving verdict accuracy, Ask AI follow-ups, and authority handoff.
--
-- Adds:
--   - scammers              (offender profile: aliases, risk_level, counts)
--   - scammer_identifiers   (phone/url/bank/email/etc. for an offender)
--   - reports.scammer_id    (nullable FK; existing target_identifier* columns
--                            remain as denormalised cache).
-- ============================================================================

-- CreateEnum
CREATE TYPE "scammer_risk_level" AS ENUM ('low', 'medium', 'high', 'unknown');

-- CreateEnum
CREATE TYPE "scammer_identifier_kind" AS ENUM (
    'phone', 'url', 'email', 'bank_account', 'line_id', 'social_handle', 'other'
);

-- CreateTable
CREATE TABLE "scammers" (
    "id"                  UUID                NOT NULL DEFAULT gen_random_uuid(),
    "display_name"        TEXT                NOT NULL,
    "aliases"             TEXT[]              NOT NULL DEFAULT ARRAY[]::TEXT[],
    "risk_level"          "scammer_risk_level" NOT NULL DEFAULT 'unknown',
    "notes"               TEXT,
    "report_count_cache"  INTEGER             NOT NULL DEFAULT 0,
    "first_seen_at"       TIMESTAMPTZ,
    "last_seen_at"        TIMESTAMPTZ,
    "created_at"          TIMESTAMPTZ         NOT NULL DEFAULT now(),
    "updated_at"          TIMESTAMPTZ         NOT NULL DEFAULT now(),

    CONSTRAINT "scammers_pkey" PRIMARY KEY ("id")
);

CREATE TRIGGER "scammers_set_updated_at"
BEFORE UPDATE ON "scammers"
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- CreateTable
CREATE TABLE "scammer_identifiers" (
    "id"               UUID                       NOT NULL DEFAULT gen_random_uuid(),
    "scammer_id"       UUID                       NOT NULL,
    "kind"             "scammer_identifier_kind" NOT NULL,
    "value_raw"        TEXT                       NOT NULL,
    "value_normalized" CITEXT                     NOT NULL,
    "created_at"       TIMESTAMPTZ                NOT NULL DEFAULT now(),

    CONSTRAINT "scammer_identifiers_pkey" PRIMARY KEY ("id")
);

-- Unique on (kind, value_normalized) — one phone or URL maps to one scammer.
CREATE UNIQUE INDEX "scammer_identifiers_kind_value_normalized_key"
    ON "scammer_identifiers" ("kind", "value_normalized");

CREATE INDEX "scammer_identifiers_scammer_id_idx"
    ON "scammer_identifiers" ("scammer_id");

-- AddForeignKey
ALTER TABLE "scammer_identifiers"
    ADD CONSTRAINT "scammer_identifiers_scammer_id_fkey"
    FOREIGN KEY ("scammer_id") REFERENCES "scammers"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- AlterTable: reports.scammer_id
ALTER TABLE "reports" ADD COLUMN "scammer_id" UUID;

ALTER TABLE "reports"
    ADD CONSTRAINT "reports_scammer_id_fkey"
    FOREIGN KEY ("scammer_id") REFERENCES "scammers"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;

CREATE INDEX "reports_scammer_id_idx" ON "reports" ("scammer_id");
