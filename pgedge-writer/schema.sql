-- This file is run during the Docker image build. 
-- Add all of your table definitions here along with
-- setting LOG_OLD_VALUE=true on numerical columns

CREATE SEQUENCE public.test_table_id_seq AS bigint;

CREATE TABLE IF NOT EXISTS public.test_table 
(
  id bigint DEFAULT nextval('test_table_id_seq'::regclass) NOT NULL,
  val text
);

ALTER TABLE public.test_table ALTER COLUMN id SET (LOG_OLD_VALUE=true);
ALTER TABLE public.test_table ADD CONSTRAINT test_table_pkey PRIMARY KEY(id);

-- After a record is inserted, manually sync the sequence
CREATE FUNCTION flush_test_table_sequence() RETURNS trigger
  LANGUAGE plpgsql
  AS $_$
BEGIN
  PERFORM * FROM spock.sync_seq('test_table_id_seq');
  RETURN NEW;
END;
$_$;

-- Before a record is inserted, wait for our subscription to catch up
CREATE FUNCTION wait_test_table_sequence() RETURNS trigger
  LANGUAGE plpgsql
  AS $_$
BEGIN
  PERFORM * from spock.wait_slot_confirm_lsn(NULL, NULL);
  RETURN NEW;
END;
$_$;
  

CREATE TRIGGER after_test_table_insert 
  AFTER INSERT on public.test_table 
-- This gets really, really slow 
   FOR EACH ROW
-- Very low overhead, but still causes conflicts
--  FOR EACH STATEMENT
  EXECUTE FUNCTION flush_test_table_sequence();

CREATE TRIGGER before_test_table_insert
  BEFORE INSERT on public.test_table
  FOR EACH ROW
  EXECUTE FUNCTION wait_test_table_sequence();

