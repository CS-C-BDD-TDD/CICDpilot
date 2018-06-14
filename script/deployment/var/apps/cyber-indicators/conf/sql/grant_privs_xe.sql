-- Ensures that the application user has all the necessary privileges to
-- run SQL statements on the tables in the schema.

CREATE OR REPLACE PROCEDURE grant_privs
IS
   CURSOR ut_cur IS SELECT table_name FROM user_tables;
   ut_rec ut_cur%ROWTYPE;
   CURSOR us_cur IS SELECT sequence_name FROM user_sequences;
   us_rec us_cur%ROWTYPE;
BEGIN
   -- Create synonyms for tables
   FOR ut_rec IN ut_cur
   LOOP
      EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE  ON ' || ut_rec.table_name || ' TO appuser';
      EXECUTE IMMEDIATE 'CREATE OR REPLACE PUBLIC SYNONYM ' || ut_rec.table_name || ' FOR ' || ut_rec.table_name;
   END LOOP;

   -- Create synonyms for sequences
   FOR us_rec IN us_cur
   LOOP
      EXECUTE IMMEDIATE 'GRANT SELECT, ALTER ON ' || us_rec.sequence_name || ' TO appuser';
      EXECUTE IMMEDIATE 'CREATE OR REPLACE PUBLIC SYNONYM ' || us_rec.sequence_name || ' FOR ' || us_rec.sequence_name;
   END LOOP;
END;
/
