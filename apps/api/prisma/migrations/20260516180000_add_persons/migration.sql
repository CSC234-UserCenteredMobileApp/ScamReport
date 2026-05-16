-- Persons = real human offenders. Many Scammers (campaigns / surfaces) can
-- point at the same Person. NULL person_id = anonymous campaign with no
-- attributed human.

CREATE TABLE persons (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name            TEXT NOT NULL,
  aliases              TEXT[] NOT NULL DEFAULT '{}',
  risk_level           "scammer_risk_level" NOT NULL DEFAULT 'unknown',
  notes                TEXT,
  report_count_cache   INTEGER NOT NULL DEFAULT 0,
  campaign_count_cache INTEGER NOT NULL DEFAULT 0,
  first_seen_at        TIMESTAMPTZ,
  last_seen_at         TIMESTAMPTZ,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX persons_full_name_idx ON persons (full_name);

ALTER TABLE scammers
  ADD COLUMN person_id UUID REFERENCES persons(id) ON DELETE SET NULL;

CREATE INDEX scammers_person_id_idx ON scammers (person_id);

-- Backfill: every scammer with a non-null suspected_name gets a Person row
-- with that name; duplicates by full_name collapse to one Person.
INSERT INTO persons (full_name, risk_level, report_count_cache, first_seen_at, last_seen_at)
SELECT
  s.suspected_name,
  MAX(s.risk_level::text)::"scammer_risk_level",
  COALESCE(SUM(s.report_count_cache), 0)::INT,
  MIN(s.first_seen_at),
  MAX(s.last_seen_at)
FROM scammers s
WHERE s.suspected_name IS NOT NULL
GROUP BY s.suspected_name;

UPDATE scammers s
SET person_id = p.id
FROM persons p
WHERE s.suspected_name IS NOT NULL
  AND s.suspected_name = p.full_name;

-- Recompute campaign_count_cache on each freshly-inserted Person.
UPDATE persons p
SET campaign_count_cache = (
  SELECT COUNT(*)::INT FROM scammers s WHERE s.person_id = p.id
);
