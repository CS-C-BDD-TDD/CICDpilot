-- Ensures that the application user has all the necessary privileges to
-- run SQL statements on the tables in the schema. This is the PRODUCTION
-- version of this script.

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
      EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON ' || ut_rec.table_name || ' TO APP_ROLE';
   END LOOP;

   -- Create synonyms for sequences
   FOR us_rec IN us_cur
   LOOP
      EXECUTE IMMEDIATE 'GRANT SELECT ON ' || us_rec.sequence_name || ' TO APP_ROLE';
   END LOOP;
END;
/
