-- This file is run during the Docker image build. 
-- Add all of your table definitions here along with
-- setting LOG_OLD_VALUE=true on numerical columns

CREATE TABLE IF NOT EXISTS public.test_table 
(
  id BIGSERIAL PRIMARY KEY, 
  val text
);

ALTER TABLE public.test_table ALTER COLUMN id SET (LOG_OLD_VALUE=true);
