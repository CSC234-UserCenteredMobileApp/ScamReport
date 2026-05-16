-- Name the reporter (or Ask AI's draft inference) attributed to the caller
-- at submit time. Persisted as a denormalised text column so moderators can
-- read it without depending on the linked scammer/person rows existing yet.

ALTER TABLE reports ADD COLUMN suspected_name_at_submit TEXT;
