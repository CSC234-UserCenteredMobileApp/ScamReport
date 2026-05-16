-- Add nullable suspected_name to scammers. NULL = anonymous campaign;
-- non-null = name the caller gave / handle the offender is alleged to use.
ALTER TABLE scammers ADD COLUMN suspected_name TEXT;
