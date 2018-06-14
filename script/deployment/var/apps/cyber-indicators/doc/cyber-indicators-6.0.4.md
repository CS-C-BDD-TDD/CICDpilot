# Post-Upgrade Notes

After executing the standard "Upgrade the Application" procedure, and starting the application, please take the following actions.

* Record the current system GUID *

```bash
grep SYSTEM_GUID /etc/cyber-indicators/config/settings.yml
```

!Example! Recording the current system GUID

```bash
grep SYSTEM_GUID /etc/cyber-indicators/config/settings.yml
  SYSTEM_GUID: CIAP:ce0a290d-be5f-4378-81f0-f0b2cc1c2589
```

Record the string beginning with CIAP.

* Reinitialize the application system settings with the system GUID *

```bash
SYSTEM_GUID=<RECORDED_SYSTEM_GUID> /var/apps/cyber-indicators/bin/initialize-system-settings
```

!Example! Initializing the system settings with the recorded GUID

```bash
SYSTEM_GUID=CIAP:ce0a290d-be5f-4378-81f0-f0b2cc1c2589 /var/apps/cyber-indicators/bin/initialize-system-settings
```

* Restart the application *

```bash
service cyber-indicators restart
```

## Known Issues

# Cannot save an indiator with a linked system tag.

Symptom:  Indicator will not save, deleting the system tag and clicking save allows the indicator to save.

Signature:  "D, [2015-07-21T00:32:07.751000 #11499] DEBUG -- : exception: RSolr::Error::Http - 400 Bad Request
Error: {'responseHeader'=>{'status'=>400,'QTime'=>35},'error'=>{'msg'=>'ERROR: [doc=Indicator 10219] unknown field \'system_tags_exactm\'','code'=>400}}" appears in the exceptions log.

Root Cause:  The SOLR schema.xml file is missing the exactm definition.

Fix: 

*Edit the SOLR schema.*

```bash
vim /var/apps/solr/production/conf/schema.xml
```

*Add the definition to the configuration.*

```bash
    <dynamicField name="*_exactm" stored="false" type="etext" multiValued="true" indexed="true"/>
```

!Note! Add this to the end of the file, before the "</schema>" line.

*Save the file*

*Restart the application server.*

```bash
service cyber-indicators restart
```

# Application appears to stop functioning

Symptom: "Server could not establish a connection to the database server within 5 seconds." within the /usr/share/tomcat7/logs/localhost-<date>.log

Root Cause:  Replication is causing several connections to the database.  Sometimes these connections are open for extended periods of time.

Fix 0: Regenerate the database configuration.

*Regenerate the database configuration.*

DATABASE=[DATABASE] \
DBADMIN_USERNAME=[DBADMIN_USERNAME] \
DBADMIN_PASSWORD=[DBADMIN_PASSWORD] \
APPUSER_USERNAME=[APPUSER_USERNAME] \
APPUSER_PASSWORD=[APPUSER_PASSWORD] \
/var/apps/cyber-indicators/bin/initialize-database-configuration


!Note! As of this version, this command generates a new /etc/cyber-indicators/config/database.yml file with a database pooling parameter.

*Restart the application server.*

```bash
service cyber-indicators restart
```

Fix 1: Manually edit the database configuration.

*Edit /etc/cyber-indicators/config/database.yml*

This file should look similar to the example.

!Example!  /etc/cyber-indicators/config/database.yml:

```yaml
production:
  adapter: oracle_enhanced
  database: example_database_name
  username: example_appuser_username
  password: example_appuser_password
dbadmin:
  adapter: oracle_enhanced
  database: example_database_name
  username: example_dbadmin_username
  password: example_dbadmin_password
```

*Add the pooling parameter.*

!Example!  /etc/cyber-indicators/config/database.yml:

```yaml
production:
  adapter: oracle_enhanced
  database: example_database_name
  username: example_appuser_username
  password: example_appuser_password
  pool: 20
dbadmin:
  adapter: oracle_enhanced
  database: example_database_name
  username: example_dbadmin_username
  password: example_dbadmin_password
```

*Save the file.*

*Restart the application server.*

```bash
service cyber-indicators restart
```


