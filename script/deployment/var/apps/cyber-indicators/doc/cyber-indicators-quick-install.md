## Script Install

```bash
export PATH_TO_CYBER_INDICATORS_RPM=
export PATH_TO_TOMCAT7_RPM=

export JAVA_HOME=

export TNS_ADMIN=
ORACLE_HOME=
LD_LIBRARY_PATH=

export DATABASE=DATABASE_NAME_IN_TNSNAMES_ORA
export DBADMIN_USERNAME=
export DBADMIN_PASSWORD=
export APPUSER_USERNAME=
export APPUSER_PASSWORD=
export APP_ROLE=


#application
yum -y install $PATH_TO_TOMCAT7_RPM $PATH_TO_CYBER_INDICATORS_RPM
/var/apps/cyber-indicators/bin/link-tomcat7
/var/apps/cyber-indicators/bin/initialize-application-webserver
/var/apps/cyber-indicators/bin/initialize-sysconfig

#database
chown root:tomcat $TNS_ADMIN/tnsnames.ora
chmod 0750 $TNS_ADMIN/tnsnames.ora
/var/apps/cyber-indicators/bin/initialize-database-configuration
/var/apps/cyber-indicators/bin/initialize-grant-privileges-stored-procedure
/var/apps/cyber-indicators/bin/install-grant-privileges-stored-procedure
/var/apps/cyber-indicators/bin/initialize-create-synonyms-stored-procedure
/var/apps/cyber-indicators/bin/install-create-synonyms-stored-procedure
RAILS_ENV=dbadmin /var/apps/cyber-indicators/bin/rake db:migrate
RAILS_ENV=dbadmin /var/apps/cyber-indicators/bin/rake db:grant
RAILS_ENV=production /var/apps/cyber-indicators/bin/rake db:synonyms
/var/apps/cyber-indicators/bin/rake app:bootstrap

#ssl
mkdir -p $JAVA_HOME/jre/lib/security/
$JAVA_HOME/bin/keytool -genkey -alias cyber-indicators -keyalg RSA -keystore $JAVA_HOME/jre/lib/security/cacerts


```


## Script Upgrade

Replace the PATH_TO_RPM, and [TNS_ADMIN] then paste this in your console:

```bash
export TNS_ADMIN=[TNS_ADMIN]
export PATH_TO_RPM=[PATH_TO_RPM]
yum -y update $RPM_FILE_NAME
/var/apps/cyber-indicators/bin/initialize-sysconfig
RAILS_ENV=dbadmin /var/apps/cyber-indicators/bin/rake db:migrate
RAILS_ENV=dbadmin /var/apps/cyber-indicators/bin/rake db:grant
RAILS_ENV=production /var/apps/cyber-indicators/bin/rake db:synonyms
/var/apps/cyber-indicators/bin/enforce-application-permissions
service cyber-indicators restart
```
