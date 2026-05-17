-- Adds crawler-import columns to `reports` and `scammers`, plus a `fake_job`
-- ScamType. Crawler-imported records (from apps/api/scripts/import-crawler.ts)
-- populate these columns. User-submitted reports leave them NULL.

ALTER TABLE reports
  ADD COLUMN source_url     TEXT,
  ADD COLUMN source_site    TEXT,
  ADD COLUMN scraped_at     TIMESTAMPTZ,
  ADD COLUMN article_title  TEXT,
  ADD COLUMN money_lost_thb BIGINT,
  ADD COLUMN num_victims    INTEGER;

CREATE INDEX reports_source_site_idx ON reports (source_site);
CREATE INDEX reports_scraped_at_idx  ON reports (scraped_at DESC);

ALTER TABLE scammers
  ADD COLUMN province      TEXT,
  ADD COLUMN nationality   TEXT,
  ADD COLUMN arrest_status TEXT;

-- New ScamType code for the crawler's `fake_job` value. Existing seed rows
-- are id 1..7; id 8 is reserved here.
INSERT INTO scam_types (id, code, label_en, label_th, display_order)
VALUES (8, 'fake_job', 'Fake job', 'หลอกสมัครงาน', 8)
ON CONFLICT (id) DO NOTHING;
