-- Ensures that the application user has all the necessary synonyms set up
-- so that it can seamlessly access the tables and sequences from the dbadmin
-- account.
--
-- Will need to modify the script slightly if the owner of the database
-- objects is named something other than "dbadmin".

CREATE OR REPLACE PROCEDURE create_synonyms
AUTHID CURRENT_USER IS
   CURSOR ut_cur IS SELECT table_name FROM all_tables WHERE owner = 'DBADMIN';
   ut_rec ut_cur%ROWTYPE;
   CURSOR us_cur IS SELECT sequence_name FROM all_sequences WHERE sequence_owner = 'DBADMIN';
   us_rec us_cur%ROWTYPE;
BEGIN
   -- Create synonyms for tables
   FOR ut_rec IN ut_cur
   LOOP
      EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM ' || ut_rec.table_name || ' FOR dbadmin.' || ut_rec.table_name;
   END LOOP;

   -- Create synonyms for sequences
   FOR us_rec IN us_cur
   LOOP
      EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM ' || us_rec.sequence_name || ' FOR dbadmin.' || us_rec.sequence_name;
   END LOOP;
END;
/
