# Cyber Indicators System Administration Guide

Execute all commands as root on the application server unless specified.

Conventions in this document:

* !Note!: Information that may help you understand concepts surrounding a task.
* !Important!: Information that must be adhered to.
* !Example!: An example of some configuration file or workflow to assist in your understanding.

You will see command-line arguments as follows:

```bash
ENVIRONMENT_VARIABLE=[SOMETHING_TO_REPLACE] /path/to/some/command
```

You may export the ENVIRONMENT_VARIABLE prior to executing the command.

You will also see backslashes at the end of some lines of very long commands.  We include these backslashes so that you may easily identify which environment variables are required for each command.  As mentioned above, you may choose to export these environment variables, which will shorten the command.

This is convention for splitting long command lines in to multiple, shorter, command lines. For example:

```bash
ENVIRONMENT_VARIABLE=[SOME_LONG_VALUE] \
ENVIRONMENT_VARIABLE=[SOME_LONG_VALUE] \
/path/to/some/command
```

You may include or omit the backslashes when entering the command.  The command will execute either way.

# Training and Knowledge Needed

The following knowledge is required in order to install the Cyber Indicators system.  This guide will not go into detail on the following:

*  Virtual Machine (VM) installation and configuration
*  Oracle database installation and configuration
*  Linux system administration.
*  Windows Active Directory (AD) configuration.
*  Apache Tomcat installation and configuration (except where the configuration must be adjusted for the Cyber Indicators system).
*  Creating and managing new user accounts in AD.
*  DHS policies and procedures for adhering to security standards, account creating and management, and system backup and restore.

# Prerequisites

* Network configuration between application and database server:  The application server must be able to communicate to the database server on the appropriate port.  The port should be chosen at the time of deployment, and won't be specified in this guide
* Security hardening of base OS software
* Creating or installing Secure Socket Layer (SSL) Certificates:  This guide will assume that users have obtained SSL Certificate information from a trusted source, and know where these certificates are placed on the application server.
* Using a text editor:  This guide will not explain how to edit files on your system.  The guide may ask you to use vi or vim, but any text editor may be used.

# Database Connectivity

The Cyber Indicators application is DB agnostic.  The application will run on relational DBs that follow the Structured Query Language (SQL) standard.  However, Oracle is intended for production use.

The Oracle Instant Client SQLPlus is used to verify database connectivity and install stored procedures necessary to manage access between the two, provided, database schemas.

The Oracle DBA must provide the system administrator with the following:

  * The DB service name to connect to.
  * A DB admin username and password ("dbadmin"); this account will own all DB objects.
  * A DB application username and password ("appuser"); this account will be used by the web application to query against database tables. This account will be a member of the APP_USER role.
  * An APP_USER role; this role will receive all required grants from "dbadmin".
  * A configured /etc/tnsnames.ora file on the application server
  * Correctly configured timezone information (e.g. /etc/localtime)

!Note! The tnsnames.ora file is not required to be in the path /etc, however, for the purposes of this guide, we assume that it is.  The location of this configuration file is controlled via the TNS_ADMIN environment variable.  We prefix all commands that use this path with this environment variable, and call-out the necessity for you to supply the correct path information, if it differs from what is documented in this guide.

The DB admin user requires the privileges to drop and create tables within its schema and have permission to grant privileges on these objects to the DB application user.  The application user is the user under which the application connects to the DB.  All privileges [e.g. INSERT, DELETE, UPDATE] shall be granted to the DB application user on an object-by-object basis or as the schema level.  The Oracle DBA must configure the correct environment variables for the Oracle Instant Client Libraries.  The DB should be free of all non-essential tables and user accounts.  In addition, the app user role requires the select privilege on the system plan table, as well as all_tables and all_sequences.

Specifically, the DB admin user, a member of a DB Admin Role requires the following Oracle privileges:

  * select on all_tables
  * select on all_constraints
  * select on all_cons_columns
  * select on all_tab_cols
  * select on all_sequences
  * select on dual
  * select on all_indexes
  * select on all_views
  * select on user_constraints
  * select on user_cons_columns
  * select on user_synonyms
  * select on user_users
  * select on all_ind_columns
  * select on all_ind_expressions
  * select on all_tab_cols
  * create/replace stored procedure

The DB app user, a member of a DB APP_USER Role requires the following Oracle privileges:

  * select on all_tables
  * select on all_sequences
  * create/replace stored procedure
  * create private synonym

These environment variables are:

  * LD_LIBRARY_PATH: Specifies the path to the Oracle Instant Client libraries.
  * TNS_ADMIN: Specifies the path to the Oracle tnsnames.ora file.
  * ORACLE_HOME: Specifies the path to the Oracle Instant Client root path.
  * NLS_LANG: Specifies the encoding to use for information stored within the DB.  This application uses AMERICAN_AMERICA.UTF8.

Test the DB connection independent of the application by using the SQLPlus command:

Before proceeding, execute the following:

  * Connect to the DB as the DB admin user.

```bash
sqlplus [EXAMPLE_DBADMIN_USERNAME]@[EXAMPLE_DATABASE_NAME]
```

  * Connect to the DB as the application user.

```bash
sqlplus [EXAMPLE_APPUSER_USERNAME]@[EXAMPLE_DATABASE_NAME]
```

  * Verify appropriate privileges for each account type.

You will need to work with the Oracle DBA to verify these privilges.

  * Verify that the DB server has the following setting in the init.ora file:

You will need to work with the Oracle DBA to verify this setting.

```bash
REMOTE_LOGIN_PASSWORDFILE = EXCLUSIVE
```

# Application Server

This section outlines the prerequisites, packages and steps required for the application server installation.  Note that some commands require the use of the 'sudo' command.  If this command is non-function, please login to the application server as root so that you can execute the 'sudo' command.

# Prerequisites

Ensure that the following dependencies are met:

  * Install Red Hat Enterprise Linux (RHEL) Operating System 64-bit
  * Assign an IP address
  * Verify database connectivity with the supplied credentials
  * Required network ports are open for application communication.  Refer to the Appendix for a list of the application required ports.

# Disk Usage Requirements

The Cyber Indicators application uses /etc and /var

/etc
Small configuration files are kept in etc.  Only a trivial (less than 5MB) of space is required by Cyber Indicators on the partition which holds /etc

/var
The application uses 1GB of space for application code.  Logs are persisted to the /var directory.  The size required for logs will depend greatly on your system usage.  For testing systems, we recommend at least 20GB of free space on the partition which holds /var for Cyber Indicators usage.

An administrator will typically import RPM installation files to his or her /home directory.  It's recommended that at least 10GB of free space is allotted for keeping new and older versions of the Cyber Indicators RPM files.

# Network Configuration Requirements

Cyber Indicators requires INPUT and OUTPUT connections.  These are listed in the table below:

|Direction|Adapter|Protocol|Port|Description|
|---------|-------|--------|----|-----------|
|INPUT|eth0|tcp|22|SSH|
|INPUT|eth0|tcp|443|HTTPS Application Access|
|INPUT|eth0|tcp|8443|HTTPS Application Access|
|INPUT|eth0|tcp|88|Kerberos|
|INPUT|eth0|udp|88|Kerberos|
|INPUT|eth0|tcp|1521|Oracle Database|
|OUTPUT|eth0|tcp|22|SSH|
|OUTPUT|eth0|tcp|443|HTTPS Application Access|
|OUTPUT|eth0|tcp|8443|HTTPS Application Access|
|OUTPUT|eth0|tcp|88|Kerberos|
|OUTPUT|eth0|udp|88|Kerberos|
|OUTPUT|eth0|udp|53|DNS|
|OUTPUT|eth0|tcp|123|NTP|
|OUTPUT|eth0|tcp|1521|Oracle Database|

Cyber Indicators also requires a TCP redirect rule from port 443 to port 8443.

!Note! We list "eth0" as the public and "lo" as the loopback adapters.  The public adapter is the adapter that external users and services use to access this application sever.

!Note! The TCP port for Oracle connectivity may not be 1521 in your instance.  Please use the port that your application server will connect to Oracle.  This information is found in the tnsnames.ora file.

# Packages

The packages identified below are required on the application server.  These components are not delivered by GD-AIS, but are installed through typical means (e.g. yum, rpm).

```bash
Required Packages:
  Oracle Java (version 6 or greater)
  Oracle Client Libraries and Oracle SQLPlus (Version to match compatibility with database server)
  Apache Tomcat version 7 STIG Hardened
```

!Important! Ensure that these packages are installed before proceeding to the next section.

!Important! Ensure that Java has the Java Cryptography Extensions (JCE) installed.

# Application Logs

Cyber Indicators logs to the following locations:

```bash
$CATALINA_HOME/logs/catalina.out
```

This log records Web server events, such as the time that the application server was started.

```bash
$CATALINA_HOME/logs/localhost.<TIMESTAMP>.log
```

This log records application events, such as page requests, or application exceptions.

# Install the Application

## Prerequisites

Before you begin, you must have:

* Installed Java
* Installed the Oracle client libraries.
* Set the JAVA_HOME environment variable.
* Set the ORACLE_HOME, TNS_ADMIN and LD_LIBRARY_PATH environment variables.
* Set the system PATH environment variable to include the ORACLE_HOME bin path.

## Install the STIG-hardened Tomcat package.

**Install the RPM.**

```bash
cd [PATH_TO_TOMCAT_7_RPM]
yum -y install [NAME_OF_TOMCAT_7_RPM]
```

## Install the Cyber Indicators package

**Install the RPM.**

```bash
cd [PATH_TO_CYBER_INDICATORS_RPM]
yum -y install [NAME_OF_CYBER_INDICATORS_RPM]
```

**Link the Web Application Folders**

```bash
/var/apps/cyber-indicators/bin/link-tomcat7
```

**Initialize the application web server.**

```bash
/var/apps/cyber-indicators/bin/initialize-application-webserver
```

## [Troubleshooting] Manually execute the rake task.
```bash
TEMPLATE=/etc/cyber-indicators/templates/etc/cyber-indicators/tomcat7/conf/server.xml.erb \
OUTFILE=/usr/share/tomcat7/conf/server.xml /var/apps/cyber-indicators/bin/rake \
db:template:create;
```

**Initialize the application System Configuration.**

```bash
TNS_ADMIN=[TNS_ADMIN] /var/apps/cyber-indicators/bin/initialize-sysconfig
```

**Initialize the application settings.**

```bash
/var/apps/cyber-indicators/bin/initialize-system-settings
```

## [Troubleshooting] Manually execute the rake task.
```bash
TEMPLATE=/etc/cyber-indicators/templates/etc/sysconfig/cyber-indiators.erb \
OUTFILE=/etc/sysconfig/cyber-indicators \
/var/apps/cyber-indicators/bin/rake db:template:create;
```

**Review the System Configuration.**

Edit the application system configuration file.

```bash
/etc/sysconfig/cyber-indicators
```

**Review the default environment variables.**

```bash
# TNS_ADMIN: Specifies the location of the Oracle tnsnames.ora file.
TNS_ADMIN=/etc

# JAVA_OPTS: Specifies the memory used by Java
JAVA_OPTS="-XX:PermSize=512m -XX:MaxPermSize=1024m"

# NLS_LANG: Specifies the character set for your connection to Oracle.
NLS_LANG=AMERICAN_AMERICA.UTF8

# SSL Certificate File:  Location for the server trusted certs.
SSL_CERT_FILE=/etc/pki/tls/cert.pem

# SOLR URL: The URL that the application uses to connect to theG search engine.
SOLR_URL=https://localhost:8983/solr/production

# CYBER_INDICATORS_HOME: Cyber indicators application root path
CYBER_INDICATORS_HOME=/var/apps/cyber-indicators
```

# Displaying the Version Number in the Application

The application will display its version number at the bottom of the webpage once logged in.  You can override this by setting the environment variable VERSION.  Set the environment variable inside of /etc/sysconfig/cyber-indicators

Edit the application system configuration file.

```bash
/etc/sysconfig/cyber-indicators
```

# Configure the Database

This application runs on an Oracle database.

## Prerequisites

You must have:

* A functioning Oracle database with two schemas.
* Verified connectivity between the application server and the database server with the dbadmin and appuser credentials.

You will require the following:

* Credentials for the "dbadmin" and "appuser" schemas.
* Location of the configured tnsnames.ora file on your application server.

## Configure the Application for Oracle

**Grant the application access to the Oracle configuration file.**

```bash
chown root:tomcat $TNS_ADMIN/tnsnames.ora
chmod 0750 $TNS_ADMIN/tnsnames.ora
```

**Initialize the database configuration file.**

```bash
DATABASE=[EXAMPLE_DATABASE_NAME] \
DBADMIN_USERNAME=[DBADMIN_USERNAME] \
DBADMIN_PASSWORD=[DBADMIN_PASSWORD] \
APPUSER_USERNAME=[APPUSER_USERNAME] \
APPUSER_PASSWORD=[APPUSER_PASSWORD] \
/var/apps/cyber-indicators/bin/initialize-database-configuration
```

## [Troubleshooting] Manually run the rake task
```bash
DATABASE=[DATABASE] \
DBADMIN_USERNAME=[DBADMIN_USERNAME] \
DBADMIN_PASSWORD=[DBADMIN_PASSWORD] \
APPUSER_USERNAME=[APPUSER_USERNAME] \
APPUSER_PASSWORD=[APPUSER_PASSWORD] \
OUTFILE=/etc/cyber-indicators/config/database.yml \
TEMPLATE=/etc/cyber-indicators/templates/etc/cyber-indicators/config/database.yml.erb \
/var/apps/cyber-indicators/bin/rake db:template:create
```

## Install the Grant Privileges Stored Procedure

**Initialize the stored procedure.**

```bash
APP_ROLE=[APP_ROLE] /var/apps/cyber-indicators/bin/initialize-grant-privileges-stored-procedure
```

## [Troubleshooting] Run the rake task
```bash
APP_ROLE=[APP_ROLE] \
OUTFILE=/var/apps/cyber-indicators/conf/sql/grant_privs.sql \
TEMPLATE=/var/apps/cyber-indicators/conf/sql/templates/grant_privs.sql.erb \
/var/apps/cyber-indicators/bin/rake db:template:create
```

**Install the procedure.**

```bash
DBADMIN_USERNAME=[DBADMIN_USERNAME] \
DBADMIN_PASSWORD=[DBADMIN_PASSWORD] \
DATABASE=[DATABASE_NAME] \
ORACLE_HOME=/usr/lib/oracle/11.2/client64/ \
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/oracle/11.2/client64/lib/ \
/var/apps/cyber-indicators/bin/install-grant-privileges-stored-procedure
```

## Install the Create Synonyms Stored Procedure

**Initialize the stored procedure.**

```bash
DBADMIN_USERNAME=[DBADMIN_USERNAME] /var/apps/cyber-indicators/bin/initialize-create-synonyms-stored-procedure
```

## [Troubleshooting] Run the rake task
```bash
DBADMIN_USERNAME=[DBADMIN_USERNAME] \
OUTFILE=/var/apps/cyber-indicators/conf/sql/create_synonyms.sql \
TEMPLATE=/var/apps/cyber-indicators/conf/sql/templates/create_synonyms.sql.erb \
/var/apps/cyber-indicators/bin/rake db:template:create
```

**Install the procedure.**

```bash
APPUSER_USERNAME=[APPUSER_USERNAME] \
APPUSER_PASSWORD=[APPUSER_PASSWORD] \
DATABASE=[DATABASE_NAME] \
ORACLE_HOME=[ORACLE_HOME] \
LD_LIBRARY_PATH=[LD_LIBRARY_PATH] \
/var/apps/cyber-indicators/bin/install-create-synonyms-stored-procedure
```

## [Troubleshooting] ActiveRecord::ConnectionAdapters::OracleEnhancedConnectionException: "DESC DBADMIN.PERMISSIONS" failed; does it exist? when running a rake task as the appuser.

The appuser has not been granted privileges.

Grant privilges.

```bash
RAILS_ENV=dbadmin /var/apps/cyber-indicators/bin/rake db:grant
```

## [Troubleshooting] Edit the Oracle database configuration file

Use a text editor to edit the file `/etc/cyber-indicators/config/database.yml`

Replace the contents with the following configuration.

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

!Important! You will need to provide a username and password for each schema for your specific Oracle implementation.  These credentials are the same that were used to verify connectivity out-of-band of the application.

!Important! You will need to provide the name of the database connection string specified in the validated tnsnames.ora file.

!Important! An example of a tnsnames.ora file is as follows:

```bash
EXAMPLE_DATABASE_NAME =
  (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = db)(PORT = 1521))
      (CONNECT_DATA =
        (SERVER = DEDICATED)
        (SERVICE_NAME = EXAMPLE_SERVICE_NAME)
      )
  )
```

!Note! In this example tnsnames.ora file, the connection string is identified by "EXAMPLE_DATABASE_NAME".  This would match the "example_database" entry in the /etc/cyber-indicators/config/database.yml file.  This entry is case insensitive.

!Note! Your tnsnames.ora file will be different.  Please use the connection string identifier in your tnsnames.ora file.

## Run the database migrations

**Run the task.**

```bash
RAILS_ENV=dbadmin /var/apps/cyber-indicators/bin/rake db:migrate
```

## Grant privileges to the Application User

**Execute the task.**

```bash
RAILS_ENV=dbadmin /var/apps/cyber-indicators/bin/rake db:grant
```

## Apply Synonyms to the Application User

**Run the synonyms task.**

```bash
RAILS_ENV=production /var/apps/cyber-indicators/bin/rake db:synonyms
```

## Initialize the Application.

**Bootstrap the application.**

```bash
/var/apps/cyber-indicators/bin/rake app:bootstrap
```

**Create the first user account.**

```bash
/var/apps/cyber-indicators/bin/rake user:create USERNAME=[USERNAME] FIRST_NAME=[FIRST_NAME] LAST_NAME=[LAST_NAME] EMAIL_ADDRESS=[EMAIL_ADDRESS] GROUPS=Administrator
```

# Configure SSO using Active Directory

Before you begin, you will require:

* Credentials for an Active Directory service account.
* Credentials for an Active Directory user account.
* Access to a Windows workstation that is a member of Active Directory.  This workstation should not be an Active Directory server.
* FQDN of the Cyber Indicators application server.
* FQDN of an Active Directory Domain Controller.
* FQDN of your Active Directory Domain.
* Access to a Domain Administrator account capable of running the "Set Service Principal" (setspn.exe) command within Windows AD.
* Access to an Active Directory server with the "setspn.exe" command installed.
* Access to an Active Directory server with the "ktpass.exe" command installed.

Verify:

* Name resolution of the Cyber Indicators application server FQDN.
* Time synchronization between the Cyber Indicators application server and the Active Directory domain.

## Overview

You will configure SSO piecewise.  The reason that you will configure this in pieces is that SSO configuration can be complicated.  Often times, the issues surrounding SSO configuration are due to some minor misconfiguration or incorrectly typed piece of information.  Piecewise configuration of SSO will allow you to avoid these pitfalls.

You will:

* Register a service principal within Active Directory.
* Configure Kerberos.
* Authenticate to active directory with this service principal and password using Kerberos.
* Verify that this service principal can be used for application authentication.
* Generate a Kerberos keytab file for this service principal.
* Authenticate to active directory with this service principal and keytab.
* Verify that this service principal and keytab can be used for appliction authentication.
* Configure the Cyber Indicators application to use this service principal and keytab.

## Configure the Service Principal

Before you begin, you will require:

* Access to a Domain Administrator capable of running the "Set Service Principal" (setspn.exe) command within Windows AD.
* FQDN of the Cyber Indicators application server.
* Credentials for an Active Directory service account.

Log in to Windows Active Directory with an account capable of running the "Set Service Principal" command.

**Launch a Windows Command Prompt as an Administrator.**

Verify that the Service Account does not have any Service Principal registrations.

```cmd
C:\>setspn.exe -L [SERVICE_ACCOUNT_NAME]
Registered ServicePrincipalNames for CN=SERVICE ACCOUNT NAME,CN=Users,DC=domain,DC=com:
```

## [Troubleshooting] Setspn.exe -L "Could not find the Account"

Please verify the account information for the service account that you were given.

If this account does not exist, or the information you were provided is incorrect, then you will not find the account.

**Verify that the application server is not registered with any service principals.**

```cmd
C:\>setspn -Q */[APPLICATION_SERVER_FQDN]
Checking domain DC=domain,DC=com

No such SPN found.
```

**Register the application server service principal.**

```cmd
C:\>setspn -A HTTP/[APPLICATION_SERVER_FQDN] [DOMAIN]\[SERVICE_ACCOUNT_NAME]
Registering ServicePrincipalNames for CN=service account name,CN=Users,DC=domain,DC=com
        HTTP/[APPLICATION_SERVER_FQDN]
Updated object
```

## [Troubleshooting] Failed to assign SPN on account 'CN=docker03 svc,CN=Users,DC=unobtanium,DC=us-cert,DC=gov', error 0x2098/8344 -> Insufficient access rights to perform the operation. when registring the SPN.

*Run the Windows Command Prompt "as administrator".*

```
(Click) Start Menu->(Right Click) Command Prompt->(Click) "Run as administrator"

You will be prompted with a "User Account Control" window:

"Do you want to allow the following program to make changes to this computer?"

Review the program name, and verify:

Program name: Windows Command Processor
Verified publisher: Microsoft Windows

Click Yes if this information is verified.  Click No if this information is not verified.
```

The command prompt, when run as administrator, has special privileges that allow you to interact with Active Directory.

**Log out of Windows.**

## Configure Kerberos.

Before you begin, you will need the following:

* FQDN of your Active Directory Domain.
* FQDN of an Active Directory Domain Controller.
* Credentials for an Active Directory service account.

**Initialize the Kerberos Configuration file.**

```bash
FQDN_DOMAIN=[FQDN_DOMAIN] \
FQDN_ACTIVE_DIRECTORY_DOMAIN_CONTROLLER=[FQDN_ACTIVE_DIRECTORY_DOMAIN_CONTROLLER] \
/var/apps/cyber-indicators/bin/initialize-kerberos-configuration
```

## [Troubleshooting] Run the task
```bash
FQDN_DOMAIN=[FQDN_DOMAIN] \
FQDN_ACTIVE_DIRECTORY_DOMAIN_CONTROLLER=[FQDN_ACTIVE_DIRECTORY_DOMAIN_CONTROLLER] \
OUTFILE=/usr/share/tomcat7/conf/krb5.conf \
TEMPLATE=/etc/cyber-indicators/templates/etc/cyber-indicators/tomcat7/conf/krb5.conf.erb \
/var/apps/cyber-indicators/bin/rake db:template:create
```

**Initialize the Kerberos Login Configuration file.**

```bash
ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME=[ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME] /var/apps/cyber-indicators/bin/initialize-login-configuration
```

## [Troubleshooting] Run the task
```bash
ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME=[ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME]
OUTFILE=/usr/share/tomcat7/conf/login.conf \
TEMPLATE=/etc/cyber-indicators/templates/etc/cyber-indicators/tomcat7/conf/login.conf.erb \
/var/apps/cyber-indicators/bin/rake db:template:create
```

## [Troubleshooting] Edit the Kerberos Configuration file.

```
/usr/share/tomcat7/conf/krb5.conf
```

```bash
[libdefaults]
        default_realm = [FQDN_DOMAIN]
  default_tkt_enctypes = aes128-cts rc4-hmac des3-cbc-sha1 des-cbc-md5 des-cbc-crc
  default_tgs_enctypes = aes128-cts rc4-hmac des3-cbc-sha1 des-cbc-md5 des-cbc-crc
  permitted_enctypes   = aes128-cts rc4-hmac des3-cbc-sha1 des-cbc-md5 des-cbc-crc

[realms]
  [FQDN_DOMAIN] = {
    kdc = [FQDN_KERBEROS_KDC]
    default_domain = [FQDN_DOMAIN]
}

[domain_realm]
  .[FQDN_DOMAIN] = [FQDN_DOMAIN]
```

!Note! Replace [FQDN_DOMAIN] with the fully qualified domain name of your domain.  Enter this information in capital letters.

!Note! Replace [FQDN_KERBEROS_KDC] with the fully qualified domain name of our Kerberos Key Distribution Center.  This is typically a Windows Active Directory Server.  Enter this information in lower-cased letters.

!Example! Here is an example of a complete krb5.conf file:

```bash
[libdefaults]
        default_realm = DOMAIN.COM
  default_tkt_enctypes = aes128-cts rc4-hmac des3-cbc-sha1 des-cbc-md5 des-cbc-crc
  default_tgs_enctypes = aes128-cts rc4-hmac des3-cbc-sha1 des-cbc-md5 des-cbc-crc
  permitted_enctypes   = aes128-cts rc4-hmac des3-cbc-sha1 des-cbc-md5 des-cbc-crc

[realms]
  DOMAIN.COM = {
    kdc = activedirectory.domain.com
    default_domain = DOMAIN.COM
}

[domain_realm]
  .DOMAIN.COM = DOMAIN.COM
```

**Generate the Kerberos login configuration file.**

```bash
ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME=[ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME] /var/apps/cyber-indicators/bin/initialize-login-configuration
```

## Authenticate to Kerberos using HelloKDC

Before you begin, you will need:

* Credentials for an Active Directory service account.

**Initialize HelloKDC.**

```bash
ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME=[ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME] \
ACTIVE_DIRECTORY_SERVICE_ACCOUNT_PASSWORD=[ACTIVE_DIRECTORY_SERVICE_ACCOUNT_PASSWORD] \
/var/apps/cyber-indicators/bin/initialize-hellokdc
```

## [Troubleshooting] Run the task.

```bash
ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME=[ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME] \
ACTIVE_DIRECTORY_SERVICE_ACCOUNT_PASSWORD=[ACTIVE_DIRECTORY_SERVICE_ACCOUNT_PASSWORD] \
OUTFILE=/usr/share/tomcat7/webapps/cyber-indicators/WEB-INF/script/sso/var/apps/sso/HelloKDC/config.properties \
TEMPLATE=/etc/cyber-indicators/templates//usr/share/tomcat7/webapps/cyber-indicators/WEB-INF/script/sso/var/apps/sso/HelloKDC/config.properties.erb \
/var/apps/cyber-indicators/bin/rake db:template:create
```

**Connect to Kerberos.**

```bash
/var/apps/cyber-indicators/bin/connect-to-kerberos-hellokdc
```

You should see "Connection test successful."

**Remove the username and password information from the HelloKDC properties file.**

```bash
ACTIVE_DIRECTORY_SERVICE_ACCOUNT_PASSWORD="" /var/apps/cyber-indicators/bin/initialize-hellokdc
```

## [Troubleshooting] Exception in thread "main" javax.security.auth.login.LoginException: Message stream modified (41) when running HelloKDC or HelloKeytab

Known causes:

* The entry for FQDN_DOMAIN, when generating the Kerberos configuration is either incorrect or printed in lower case.

Corrective action:

* Regenerate the Kerberos configuration file, ensure that the FQDN_DOMAIN value is capitalized.

## [Troubleshooting] Exception in thread "main" javax.security.auth.login.LoginException: Operation not permitted when running HelloKDC or HelloKeytab

Known causes:

* The application server's firewall is blocking communication to the Kerberos infrastructure.

Corrective action:

* Turn off the application server's firewall.
* Repeat the process to connect to Kerberos.
* Enable communication over the ports specified in the documentation.

## [Troubleshooting] Exception in thread "main" java.lang.SecurityException: Configuration Error: when running HelloKDC or HelloKeytab

The configuration file login.conf is configured incorrectly.

**Re-initialize the Kerberos Configuration file.**

```bash
FQDN_DOMAIN=[FQDN_DOMAIN] \
FQDN_ACTIVE_DIRECTORY_DOMAIN_CONTROLLER=[FQDN_ACTIVE_DIRECTORY_DOMAIN_CONTROLLER] \
/var/apps/cyber-indicators/bin/initialize-kerberos-configuration
```

**Re-initialize the Kerberos Login Configuration file.**

```bash
ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME=[ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME] /var/apps/cyber-indicators/bin/initialize-login-configuration
```

**Re-initialize HelloKDC.**

```bash
ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME=[ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME] \
ACTIVE_DIRECTORY_SERVICE_ACCOUNT_PASSWORD=[ACTIVE_DIRECTORY_SERVICE_ACCOUNT_PASSWORD] \
/var/apps/cyber-indicators/bin/initialize-hellokdc
```

**Review the configuration.**

The login configuration file is located here:

```bash
/usr/share/tomcat7/conf/login.conf
```

If necessary, manually configure this file.

## [Troubleshooting] Exception in thread "main" java.lang.IllegalArgumentException: Must provide a username

You have not configured the HelloKDC config.properties file.

**Re-initialize the Kerberos Configuration file.**

```bash
FQDN_DOMAIN=[FQDN_DOMAIN] \
FQDN_ACTIVE_DIRECTORY_DOMAIN_CONTROLLER=[FQDN_ACTIVE_DIRECTORY_DOMAIN_CONTROLLER] \
/var/apps/cyber-indicators/bin/initialize-kerberos-configuration
```

**Re-initialize the Kerberos Login Configuration file.**

```bash
ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME=[ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME] /var/apps/cyber-indicators/bin/initialize-login-configuration
```

**Re-initialize HelloKDC.**

```bash
ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME=[ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME] \
ACTIVE_DIRECTORY_SERVICE_ACCOUNT_PASSWORD=[ACTIVE_DIRECTORY_SERVICE_ACCOUNT_PASSWORD] \
/var/apps/cyber-indicators/bin/initialize-hellokdc
```

**Review the configuration.**

The login configuration file is located here:

```bash
/usr/share/tomcat7/conf/login.conf
```

If necessary, manually configure this file.

## [Troubleshooting] Configure HelloKDC.

**Edit the properties file.**

```bash
/usr/share/tomcat7/webapps/cyber-indicators/WEB-INF/script/sso/var/apps/sso/HelloKDC/config.properties
```

The properties file looks like this:

```bash
config.preauthUsername = [ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME]
config.preauthPassword = [ACTIVE_DIRECTORY_SERVICE_ACCOUNT_PASSWORD]
config.krb5Conf = [PATH_TO_KRB5_CONF_FILE]
config.loginConf = [PATH_TO_LOGIN_CONF_FILE]
config.loginModule = active-directory-client
```

## [Troubleshooting] Manually connect to Kerberos

```bash
pushd /usr/share/tomcat7/webapps/cyber-indicators/WEB-INF/script/sso/var/apps/sso/HelloKDC/
  $JAVA_HOME/bin/java -jar HelloKDC.jar
popd
```

## [Troubleshooting] Manually remove the username and password from the HelloKDC properties file.
```
/usr/share/tomcat7/webapps/cyber-indicators/WEB-INF/script/sso/var/apps/sso/HelloKDC/config.properties
```

The properties file looks like this:

```bash
config.preauthUsername = [ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME]
config.preauthPassword = [ACTIVE_DIRECTORY_SERVICE_ACCOUNT_PASSWORD]
config.krb5Conf = [PATH_TO_KRB5_CONF_FILE]
config.loginConf = [PATH_TO_LOGIN_CONF_FILE]
config.loginModule = active-directory-client
```

Remove the values that you set for ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME and ACTIVE_DIRECTORY_SERVICE_ACCOUNT_PASSWORD.

## Authenticate to Kerberos using HelloKeytab

Before you begin, you will need:

* Access to a Windows workstation that is a member of Active Directory.  This workstation should not be an Active Directory server.
* Access to an Domain Administrator account capable of running the "Set Service Principal" (setspn.exe) command within Windows AD.
* Access to an Active Directory server with the "setspn.exe" command installed.
* Access to an Active Directory server with the "ktpass.exe" command installed.

*Log in to the Windows Active Directory server that has "setspn.exe" and "ktpass.exe" installed on it as the Domain Administrator capable of running these commands.*

**Launch a Windows Command Prompt as an Administrator.**

**Create the Kerberos Keytab.**

```bash
ktpass /out cyber-indicators.keytab
       /princ [ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME]@[DOMAIN_FQDN]
       /pass [ACTIVE_DIRECTORY_SERVICE_ACCOUNT_PASSWORD]
       /ptype KRB5_NT_PRINCIPAL
```

**Copy the Kerberos Keytab file to the application server.**

**Log out of the Windows Active Directory server.**

**Move the Kerberos Keytab on the Application Server.**

Move the keytab file to this location:

```
/usr/share/tomcat7/conf/cyber-indicators.keytab
```

**Initialize HelloKeytab**

```bash
APPLICATION_SERVER_URL=[APPLICATION_SERVER_URL] /var/apps/cyber-indicators/bin/initialize-hellokeytab
```

## [Troubleshooting] Run the task.

```bash
APPLICATION_SERVER_URL=[APPLICATION_SERVER_URL] \
OUTFILE=/usr/share/tomcat7/webapps/cyber-indicators/WEB-INF/script/sso/var/apps/sso/HelloKeytab/config.properties \
TEMPLATE=/etc/cyber-indicators/templates//usr/share/tomcat7/webapps/cyber-indicators/WEB-INF/script/sso/var/apps/sso/HelloKeytab/config.properties.erb \
/var/apps/cyber-indicators/bin/rake db:template:create
```

**Connect to Kerberos.**

```bash
/var/apps/cyber-indicators/bin/connect-to-kerberos-hellokeytab
```
A lot of information will be generated.  If you do not see any exceptions generated, then you have successfully authenticated against Active Directory using the keytab file that you generated.  Your keytab file is valid.

## [Troubleshooting] Exception in thread "main" javax.security.auth.login.LoginException: null (68)

The Kerberos krb5.conf file is configured incorrectly.

The Domain FQDN is specified incorrectly in the krb5.conf file.

Reconfigure the Kerberos configuration file.

## [Troubleshooting] Exception in thread "main" javax.security.auth.login.LoginException: Clock skew too great (37)

The time between your application server and the active directory server is out-of-sync.

Synchronize the time.

## [Troubleshooting] Manually Authenticate to Kerberos via HelloKeytab

```bash
pushd /usr/share/tomcat7/webapps/cyber-indicators/WEB-INF/script/sso/var/apps/sso/HelloKeytab
  $JAVA_HOME/bin/java -cp ".:/var/apps/cyber-indicators/lib/spnego-r7.jar" HelloKeytab
popd
```
A lot of information will be generated.  If you do not see any exceptions generated, then you have successfully authenticated against Active Directory using the keytab file that you generated.  Your keytab file is valid.

## [Troubleshooting] Manually Configure the HelloKeytab Properties File.

**Configure HelloKeytab properties file.**

```
/usr/share/tomcat7/webapps/cyber-indicators/WEB-INF/script/sso/var/apps/sso/HelloKeytab/config.properties
```

The properties file looks like this:

```bash
config.krb5Conf = [PATH_TO_KRB5_CONF_FILE]
config.loginConf = [PATH_TO_LOGIN_CONF_FILE]
config.loginModule = active-directory
config.applicationServerURL = [APPLICATION_SERVER_URL]
```

## [Troubleshooting] Compile HelloKeytab.java

```bash
$JAVA_HOME/bin/javac -cp '.:/var/apps/cyber-indicators/lib/spnego-r7.jar' \
/usr/share/tomcat7/webapps/cyber-indicators/WEB-INF/script/sso/var/apps/sso/HelloKeytab/HelloKeytab.java
```

## [Troubleshooting] Enable network debug mode

```bash
pushd /usr/share/tomcat7/webapps/cyber-indicators/WEB-INF/script/sso/var/apps/sso/HelloKeytab
  $JAVA_HOME/bin/java -cp '.:/var/apps/cyber-indicators/lib/spnego-r7.jar' -Djavax.net.debug=all HelloKeytab
popd
```

## [Troubleshooting] KrbException: Server not found in Kerberos database

This is a general error, and is generally caused by the following:

* Not registing the service principal name.
* Incorrect DNS configuration.
* The SPN you are trying to create is already registered.

Re-register the SPN.  Ensure that you register the SPN using a Windows Command Processor "ran as an administrator".

Verify DNS configuration.  Verify that you are able to resolve both the Domain short-name and fully-qualified domain name for the application server.

### [Troubleshooting] Exception in thread "main" java.net.ConnectException: Connection refused

The entry for the applicationServerURL in the Keytab config.properties file is incorrect.

Verify that you can actually access this URL without this utility over HTTPS.

Verify that you are using the correct URL, such as the application server DNS entry and port combination.

Verify that the application services are running.

### [Troubleshooting] Exception in thread "main" javax.net.ssl.SSLHandshakeException

SSL Trust is not properly configured for your java environment.

Reconfigure SSL trust, and verify that your application server is configured to trust the SSL certificate.

## [Troubleshooting] Exception in thread "main" javax.net.ssl.SSLHandshakeException: sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target

The Java truststore is not properly linked to the application.

Create the primary and local SSL certificates in $JAVA_HOME/jre/lib/security/cacerts.

Copy $JAVA_HOME/jre/lib/security/cacerts to /usr/share/tomcat7/keystore/.

## [Troubleshooting] Exception in thread "main" javax.security.auth.login.LoginException: No CallbackHandler available to garner authentication information from the user

This error means that the application that you are using is unable to use Kerberos for promptless login, hence "garner" authentication information.

This is essentially saying that there is no Java handler to prompt the user or service for a password, and so Java is reporting the exception.

The Keytab file is missing or incorrectly generated.

  Verify SPN registration, and regenerate the Keytab.

The krb5.conf file is incorrect.

The login.conf file is incorrect, or referring to an incorrect keytab.

When troubleshooting HelloKeytab:

  The applicationURL may be incorrect.

  Ensure that the web service at the applicationURL is running.

  If the applicationURL is the same server you are working on, make sure that server.xml is not configured to use ActiveDirectory.

Regenerate the keytab file.

You may use debugging utilities, such as "ktutil" and "klist" to verify the integrity of the keytab file.

Discussion of these utilities is out-of-scope from this document.

## [Troubleshooting] Exception in thread "main" javax.security.auth.login.LoginException: No CallbackHandler available to garner authentication information from the user

This is a specific manifestation of the "javax.security.auth.login.LoginException".  When executing the HelloKeytab utility, this error occurs very early on in execution.

```bash
>>>KinitOptions cache name is /tmp/krb5cc_0
>>> KeyTabInputStream, readName(): DOMAIN
>>> KeyTabInputStream, readName(): USERNAME
>>> KeyTab: load() entry length: 58; type: 23
Ordering keys wrt default_tkt_enctypes list
default etypes for default_tkt_enctypes: 17 23 16 3 1.
Exception in thread "main" javax.security.auth.login.LoginException: No CallbackHandler available to garner authentication information from the user
```

Verify that the DOMAIN and USERNAME (visible in the KeyTabInputStream) match the USERNAME@DOMAIN in the generated keytab, and in the Kerberos configuration file.

```bash
cat /usr/share/tomcat7/conf/krb5.conf
[libdefaults]
  default_realm = DOMAIN.COM
  default_tkt_enctypes = aes128-cts rc4-hmac des3-cbc-sha1 des-cbc-md5 des-cbc-crc
  default_tgs_enctypes = aes128-cts rc4-hmac des3-cbc-sha1 des-cbc-md5 des-cbc-crc
  permitted_enctypes   = aes128-cts rc4-hmac des3-cbc-sha1 des-cbc-md5 des-cbc-crc

[realms]
  DOMAIN.COM = {
    kdc = activedirectory.domain.com
    default_domain = DOMAIN.COM
}

[domain_realm]
  .DOMAIN.COM = DOMAIN.COM
```

In the example above, notice that DOMAIN.COM does not match DOMAIN.

### [Developer Note] Verify that the DOMAIN and USERNAME match the USERNAME@DOMAIN in the generated keytab and in the Kerberos configuration file.

Install Kerberos v5 utilities.

```bash
yum -y install krb5-workstation
```

View the keytab.

```bash
ktutil
ktutil:  rkt /usr/share/tomcat7/conf/cyber-indicators.keytab
ktutil:  list
slot KVNO Principal
---- ---- ---------------------------------------------------------------------
   1    0     USERNAME@DOMAIN
```

## [Troubleshooting] Exception in thread "main" java.net.ConnectException: Connection refused

The utility is not able to connect to the applicationURL provided in the configuration file.

Verify the application URL in the configuration file.

```bash
/usr/share/tomcat7/webapps/cyber-indicators/WEB-INF/script/sso/var/apps/sso/HelloKeytab/config.properties
```

## Configure the Application to use the Keytab

**Initialize the web server with Kerberos.**

```bash
/var/apps/cyber-indicators/bin/initialize-application-webserver-with-kerberos
```

## [Troubleshooting] Run the task.
```bash
KERBEROS_KEYTAB=true \
TEMPLATE=/etc/cyber-indicators/templates/etc/cyber-indicators/tomcat7/conf/server.xml.erb \
OUTFILE=/usr/share/tomcat7/conf/server.xml /var/apps/cyber-indicators/bin/rake \
db:template:create
```

## [Troubleshooting] Manually Configure the Application to use the Keytab

Edit the Tomcat server configuration file.

```
/usr/share/tomcat7/conf/server.xml
```

Locate the Application Context.

The Application Context looks like this:

```xml
  <Context docBase="cyber-indicators" path="/cyber-indicators" reloadable="true">
    <!--
      <Valve className="indicators.cyber.valves.BlackList"
             disallowedHeaders="REMOTE_USER|AUTH_MODE|REMOTE_USER_GUID"/>
      <Valve className="indicators.cyber.valves.ActiveDirectory"
             krb5Conf="/usr/share/tomcat7/conf/krb5.conf"
             loginConf="/usr/share/tomcat7/conf/login.conf"
             loginModule="active-directory"
             />
    -->
  </Context>
```

Replace the Context with this:

```xml
    <Context docBase="cyber-indicators" path="/cyber-indicators" reloadable="true">
      <Valve className="indicators.cyber.valves.BlackList"
             disallowedHeaders="REMOTE_USER|AUTH_MODE|REMOTE_USER_GUID"/>
      <Valve className="indicators.cyber.valves.ActiveDirectory"
             krb5Conf="/usr/share/tomcat7/conf/krb5.conf"
             loginConf="/usr/share/tomcat7/conf/login.conf"
             loginModule="active-directory"
             />
    </Context>
```

## [Troubleshooting] The browser displays "KrbException: Specified version of key is not available (44)"

This issue is caused by recreating or resetting the Service Account used for Kerberos.

Recreate the keytab and specify the "kvno" number:

```bash
ktpass /out cyber-indicators.keytab
       /princ [ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME]@[DOMAIN]
       /pass [ACTIVE_DIRECTORY_SERVICE_ACCOUNT_PASSWORD]
       /ptype KRB5_NT_PRINCIPAL
       /kvno 0
```

## [Troubleshooting] Application Log: Java::JavaSql::SQLRecoverableException (IO Error: could not resolve the connect identifier  "[IDENTIFIER]"):

IDENTIFIER may be any string, and usually matches the name of the database that you are trying to connect to.

Verify that the path to TNS_ADMIN, as shown in /var/log/cyber-indicators/env-production.log, exists, and that the tnsnames.ora file exists.

Verify that the operating system tomcat user can access the tnsnames.ora file.

Verify that the /etc/cyber-indicators/conf/database.yml file exists and is configured correctly.

```bash
chmod 740 /etc/tnsnames.ora
chown root:tomcat /etc/tnsnames.ora
service cyber-indicators restart
```

## [Troubleshooting] SEVERE: A child container failed during start java.util.concurrent.ExecutionException: org.apache.catalina.LifecycleException: Failed to start component [StandardEngine[Catalina].StandardHost[localhost]. StandardContext[/cyber-indicators]] in the catalina log.

This error means that the Valve components cannot start.

This is the result of an incorrect valve configuration.

Verify that the valves are correctly configured, and that the file locations and settings can be referenced by the valve and the tomcat user.

Verify that the login.conf file has an active-directory-client stanza configured.

Verify that the login.conf file has an stanza configured for the loginModule defined in server.xml.  If no loginModule is defined, ensure that an active-directory stanza exists.

```bash
active-directory {
  ...
};

active-directory-client {
  ...
};
```

## [Troubleshooting] Configuring Browser Trust

When accessing the Kerberized Cyber Indicators Application, you will be presented with a login and password dialog if your browser is not configured to trust the Cyber Indicators application.

### Internet Explorer:

Internet Explorer, used within the same Active Directory Domain is already configured to pass credentials for Cyber Indicators Single Sign On.

### Firefox:

The Firefox browser must be configured to pass Kerberos credentials.

In the browser bar, enter:  "about:config"

When warned about changing configuration settings, select "I'll be careful"

Search for "network.negotiate-auth.trusted-uris".

Double-click the Preference "network.negotiate-auth.trusted-uris".

Append the URL for the Cyber Indicators application.

!Note! You do not need to provide the full URL for this to function.  For example, an application server accessed via https://www.server.com:8443/some_path, you do not need to enter this full URL.  You may enter https://www.server.com, and trust will occurr on all ports and paths for this URL.

## [Troubleshooting] ORA-01882: timezone region not found in the localhost log.

After launching the application, if every page load gives you a "something went wrong" error, check the application log, under `/usr/share/tomcat7/logs/localhost.[timestamp].log`

If the page load stack trace error includes `ORA-01882: timezone region not found`, it may be because your timezone setting is corrupt.  The following can remedy this error

```bash
mv /etc/localtime /etc/localtime.old
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
service cyber-indicators restart
```

Change the time zone for the appropriate locale.

## [Troubleshooting] Errno::ECONNREFUSED: Connection refused - {:data=>"<?xml version=\"1.0\" encoding=\"UTF-8\"?><delete><query>type:Address</query></delete>", :headers=>{"Content-Type"=>"text/xml"}, :method=>:post, :params=>{:wt=>:ruby}, :query=>"wt=ruby", :path=>"update", :uri=>#<URI::HTTP:0x2ccddba7 URL:http://localhost:8080/solr/production/update?wt=ruby>, :open_timeout=>nil, :read_timeout=>nil, :retry_503=>nil, :retry_after_limit=>nil} in the localhost log, or on the console when trying to reindex.

Ensure that the /etc/sysconfig/cyber-indicators file has SSL_CERT and SOLR_URL set, and that the cert and URL are valid.

If using the Rake CLI to reindex, pass the SOLR_URL and SSL_CERT to the Rake task.

```bash
SOLR_URL=SOLR_FQDN SSL_CERT=PATH_TO_SSL_CERT /var/apps/cyber-indicators/bin/rake sunspot:solr:reindex
```

## [Troubleshooting] Exception in thread "main" javax.security.auth.login.LoginException: Pre-authentication information was invalid (24)

The Kerberos keytab was generated incorrectly.

Regenerate the keytab file, and ensure that you are entering all of the correct information.

## [Troubleshooting] ActiveRecord::ConnectionAdapters::OracleEnhancedConnectionException ("DESC EXAMPLE_DBADMIN_USERNAME.TABLE_NAME" failed; does it exist?) in the localhost log.

The application production database user does not have the privilege to view the table name.

This is the result of executing a migration, and then not executing the grant and synonym stored procedures.

Fix the permissions on the database for the production database user.

```bash
RAILS_ENV=dbadmin /var/apps/cyber-indicators/bin/rake db:grant
```

```bash
/var/apps/cyber-indicators/bin/rake db:synonyms
```

Restart the application.

```bash
service cyber-indicators restart
```

## [Troubleshooting] Receive "Invalid Request" after logging in to the application for the first time.

This can be caused by the application being out-of-sync with the database.

For example, a new version of the application was installed, data migrations were run, and the application was not restarted.

Stop the application.

```bash
service cyber-indicators stop
```

Synchronize the application.

```bash
/var/apps/cyber-indicators/sbin/synchronize-application
```

Restart the application.

```bash
service cyber-indicators start
```

# Configure SSO Using ICAM Authentication

In order to utilize ICAM Authentication, the WSO2 server needs to be configured to authenticate for CIAP.  Contact the ICAM team to handle this setup.

You will need 4 pieces of information to complete this configuration:

- The Issuer ID for your ICAM connection
- The IDP URL - This is the URL that is used to connect to the ICAM server
  - Example:  https://wso2-erb.sec.dte.cert.org/samlsso
- The hostname of the CIAP server
- The port that the CIAP server is running on (typically this is 8443)

## Set the server into ICAM Authentication mode
```bash
/var/apps/cyber-indicators/sbin/set-icam-authentication
```

## Set up the SAML properties file
```bash
ISSUER_ID=[ISSUER_ID] \
OUR_HOST=[HOSTNAME OF CIAP INSTANCE] \
OUR_PORT=[PORT NUMBER FOR CIAP INSTANCE] \
IDP_URL=[THE IDP URL PROVIDED BY ICAM TEAM] \
ENABLE_ASSERTION_SIGNING=[true OR false - PROVIDED BY ICAM TEAM] \
IDP_CERT_ALIAS=[THE CERT ALIAS PROVIDED BY ICAM TEAM] \
/var/apps/cyber-indicators/bin/initialize-saml-properties
```

# Configure the Application for CIR, if necessary

```bash
MODE=CIR /var/apps/cyber-indicators/sbin/set-username-and-password-authentication
```

# Secure the Application

**Enfore permissions.**

```bash
/var/apps/cyber-indicators/bin/enforce-application-permissions
```

**Configure the Firewall**

If your application server has a firewall, you must enable TCP and UDP ports for the application to successfully communicate.

The Cyber Indicators Application requires these network rules:

Redirection from port 443 to port 8443 on the public network interface.

```bash
SSH Access                    | INPUT TCP port 22
HTTPS Application Access      | INPUT TCP ports 443 and 8443
Internal Application Services | INPUT TCP and UDP on the loopback address | OUTPUT TCP and UDP on the loopback address
Kerberos Authentication       | INPUT TCP port 88 with state NEW, ESTABLISHED, RELATED
Kerberos Authentication       | INPUT UDP port 88
Oracle Database Access        | INPUT TCP port 1521
SSH Access                    | OUTPUT TCP port 22
HTTPS Application Access      | OUTPUT ports 443 and 8443
Kerberos Authentication       | OUTPUT TCP port 88 with state NEW, ESTABLISHED, RELATED
Kerberos Authentication       | OUTPUT UDP port 88
DNS                           | OUTPUT UDP port 53
NTP                           | OUTPUT TCP port 123
Oracle Database Access        | OUTPUT TCP port 1521
```

Please configure your firewall with these rules.

### [Troubleshooting]  Logging Firewall Access

```bash
-A INPUT  -s [IP_ADDRESS_OF_SYSTEM_TRYING_TO_CONNECT_TO_YOU] -j LOG --log-prefix "iptables-input-drop:  " --log-level=info
-A OUTPUT -d [IP_ADDRESS_OF_SYSTEM_TRYING_TO_CONNECT_TO_YOU] -j LOG --log-prefix "iptables-output-drop: " --log-level=info
```

Leave off the IP_ADDRESS_OF_SYSTEM_TRYING_TO_CONNECT_TO_YOU to log all traffic.

## [Troubleshooting] Exception java.lang.OutOfMemoryError: PermGen space

The default PermGen space is too low.  You can increase the PermSize by setting JAVA_OPTS in this file:

```
/etc/sysconfig/cyber-indicators
```

Increase the PermGem space.

```bash
JAVA_OPTS="-XX:PermSize=512m -XX:MaxPermSize=1024m"
```

# Start the Application

**Restart the application service.**

```bash
service cyber-indicators restart
```

**Browse to the application.**

Log in to a workstation in the Windows Active Directory Domain as the user account created in "Bootstrap the application"

Open your web browser.

Browse to the application server FQDN.

## [Troubleshooting] java.lang.UnsupportedClassVersionError: ... Unsupported major.minor version ... catalina log.

The version of Java that you have configured the application to use is incorrect.

Configure the application to use a compatible version of Java specified in this guide.

Set the JAVA_HOME environment variable.

Set the JAVA_HOME environment variable in the /etc/sysconfig/cyber-indicators file.

## [Troubleshooting] Errno::ECONNREFUSED: Connection refused - ... :uri=>#<URI::HTTP:0x4b514eb5 URL:http://localhost:8080/solr/production/update?wt=ruby> ...} when running rails console and trying to create indicators.

One behavior that indicates this issue is that you are able to create indicators through the front-end of the application.

This error is usually followed by: OpenSSL::SSL::SSLError: certificate verify failed (after correcting the first issue.  You do not see these errors together)

The problem is that the SSL_CERT_FILE and SOLR_URL environment variables are not being passed in correctly.

The root cause is that the /etc/sysconfig/cyber-indicators file is not being sourced correctly.

Pass the environment variables in when running rails console.

```bash
SSL_CERT_FILE=[SSL_CERT_FILE] SOLR_URL=[SOLR_URL] /var/apps/cyber-indicators/bin/rals console
```

**Configure the application to start on reboot.**

```bash
chkconfig --level 345 cyber-indicators on
```

# Start the Application

This section serves as reference only.

Under normal operation, or during initial application installation, you do not need to refer to this section.

*Start the application service*

```bash
service cyber-indicators start
```

The application is now started.

## [Troubleshooting] OpenSSL::X509::StoreError: setting default path failed: the trustAnchors parameter must be non-empty

Known Causes:

* Java has been updated on the application
* The Java installation has become corrupt.

Solution:

* Reinstall Java.
* Ensure that JAVA_HOME is set.

## [Troubleshooting] OpenSSL::SSL::SSLError: certificate verify failed or SOLR_URL is pointing to the wrong host, when running rake sunspot:solr:reindex

*Reindex with the SOLR_URL and SSL_CERT_FILE*

```bash
SOLR_URL=[SOLR_URL] SSL_CERT_FILE=[SSL_CERT_FILE] /var/apps/cyber-indicators/bin/rake sunspot:solr:reindex
```

## [Troubleshooting] Net::HTTPBadResponse: wrong status line: "\x15\x03\x01\x00\x02\x02" when running rake tasks that insert data in to the database.

The SOLR URL and SSL certificate are not detected.  Explicitly specify these environment variables on the command line:

```bash
SOLR_URL=[SOLR_URL] SSL_CERT_FILE=/etc/pki/tls/cert.pem rake [command]
```

## [Troubleshooting] Could not load core production, or SOLR core related issues.

Symptom:

SOLR appears to start (e.g. you can access the SOLR admin page), but SOLR logs issues starting the production core.

Known Causes:

* Configuration errors in the schema.xml file.

Solution:

Contact the development team, as this is a core application configuration file.

# Stop the Application

This section serves as reference only.

Under normal operation, or during initial application installation, you do not need to refer to this section.

*Stop the application service*

```bash
service cyber-indicators stop
```

The application is now stopped.

# (Optional) Replicating Weather Map Heat Maps

This section describes how to configure the automated release of weather map indicators between Cyber Indicators systems.

## Prerequisites

* Two Cyber Indicators instances at the same version.
* Network connectivity over TCP/IP port 443 and 8443 between the two instances.
* A machine user API account on both the source and target.

!Note! Please see the API guide for how to provision an API machine account.

!Note! The source system is the system you are copying information from.

!Note! The target system is the system you are copying information to.

## (Optional) Configure Weather Map Heat Map replication.

*Configure the weather map heat map replication*

!Note! Please change the URL to the correct hostname and port in production

```bash
export URL=https://target_hostname:8443/cyber-indicators/heatmaps
export TYPE=heatmap
export API_KEY=TARGET_API_KEY
export API_KEY_HASH=TARGET_API_KEY_HASH
rake replication:create
```

!Example! Configuring the Weather Map Heat Map Replication between CIAP and CIR systems.

```bash
export URL=https://cir_hostname:8443/cyber-indicators/heatmaps
export TYPE=heatmap
export API_KEY=CIR_MACHINE_API_ACCOUNT_API_KEY
export API_KEY_HASH=CIR_MACHINE_API_ACCOUNT_API_KEY_HASH
rake replication:create
```

## (Optional) Replication Commands

This is for reference.

* Show the created replications

```bash
rake replication:list
```

* Test connectivity to the target system

```bash
rake replication:test
```

!Note! This only tests basic HTTP connectivity to the target system.

!Note! After running this command you may re-list the replications.  Replications that will work have a status of OK.

* Test POST connectivity

```bash
rake replication:test:post
```

!Note! Replications that did not succeed with rake replication:test will not be tested.

!Note! This is a representative replication test.  Replications that are marked as OK after this test are usable for replication.

* Remove a specific replication

```bash
ID=NUMBER_FROM_LIST rake replication:destroy
```

* Remove all replications

```bash
rake replication:destroy_all
```

## Manually uploading weather map indicators from a file

A system administrator can upload weather map indicators directly to a Cyber Indicators installation from a CSV file on the command line.  The true or false passed in the command line specifies whether to attempt to replicate the indicators to any replication targets which may be set up (CIR).

!Note! Importing weather map data from the command line turns off search indexing.  The Weather Map search results will not be present until the search indexer is run again

!Note! Be sure your JAVA_HOME environment variable is set

Import a .csv, .csv.gz, .tar.gz or .tgz file as machine_user_01, and attempt replication to other servers

```bash
rake weather:import:file[name_of_csv_file.csv, machine_user_01, true]
```

Import all .csv and .csv.gz files in a directory as machine_user_02, and do not replicate to other servers

```bash
rake weather:import:dir[/path/to/dir/, machine_user_02, false]
```

### Setting up automatic ingest

Using the commands shown above, it's possible to configure the system to automatically import weather map data which is placed into a directory.  Here is a sample addition to run the import every day at 2:30 AM

```bash
30 2 * * * rake weather:import:dir[/path/to/dir/, machine_user_03, true]
```

# Upgrade the Application.

If you have a working instance of the Cyber Indicators application, you can upgrade it to a newer version.

You will require:

* Unlocked dbadmin schema.

## Install the Upgraded Application Package

**Stop the cyber-indicators service.**

```bash
service cyber-indicators stop
```

**Uninstall the application.**

```bash
yum -y remove cyber-indicators
```

**Install the new application.**

```bash
cd [PATH_TO_NEW_CYBER_INDICATORS_RPM]
yum -y install [NAME_OF_NEW_CYBER_INDICATORS_RPM]
```

**Initialize the application System Configuration.**

```bash
TNS_ADMIN=[TNS_ADMIN] /var/apps/cyber-indicators/bin/initialize-sysconfig
```

**Update the application database.**

```bash
RAILS_ENV=dbadmin /var/apps/cyber-indicators/bin/rake db:migrate
```

**Grant application permissions.**

```bash
RAILS_ENV=dbadmin /var/apps/cyber-indicators/bin/rake db:grant
```

**Apply synonyms to the application user.**

```bash
/var/apps/cyber-indicators/bin/rake db:synonyms
```

**Update the groups and permissions**

```bash
/var/apps/cyber-indicators/bin/rake groups:update
```

**If this is a CIR system, turn off SSO**

```bash
MODE=CIR /var/apps/cyber-indicators/sbin/set-username-and-password-authentication
```

**If this system is using ICAM authentication, change necessary settings**

```bash
/var/apps/cyber-indicators/sbin/set-icam-authentication
```

**Update settings.yml**

Update /etc/cyber-indicators/config/settings.yml with the information contained in Appendix I - Proper settings for each Server Type

**Start the application.**

```bash
service cyber-indicators start
```

## [Troubleshooting] ORA-01882: timezone region not found in the localhost log.

The server operating system timezone configuration is incorrect.

```bash
mv /etc/localtime /etc/localtime.old
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
```

!Note! You should replace your time zone with the correct time zone for your region.

Restart the application service.

```bash
service cyber-indicators restart
```

**Rebuild the SOLR Indexes (if necessary)**

```bash
/var/apps/cyber-indicators/bin/solr-reindex
```

!Note! On ECIS and CIR, this process will take less than 15 minutes.  On CIAP, this process will take several hours to complete.

# Clone the Application.

Before you begin, you have:

* Cloned the application server virtual machine.
* Updated the application server network information (IP address and hostname)
* Updated the application server DNS record.
* Cloned an existing Release 6 appuser and dbadmin schema.

**Verify connectivity to the database clone using the new_appuser and new_dbadmin credentials.**

Verify that the privileges for new_appuser and new_dbadmin match the privileges previously specified in this guide.

**Create the application database configuration file.**

DATABASE=[NEW_DATABASE] \
DBADMIN_USERNAME=[NEW_DBADMIN_USERNAME] \
DBADMIN_PASSWORD=[NEW_DBADMIN_PASSWORD] \
APPUSER_USERNAME=[NEW_APPUSER_USERNAME] \
APPUSER_PASSWORD=[NEW_APPUSER_PASSWORD] \
/var/apps/cyber-indicators/bin/initialize-database-configuration

## [Troubleshooting] Run the task.
```bash
DATABASE=[NEW_DATABASE] \
DBADMIN_USERNAME=[NEW_DBADMIN_USERNAME] \
DBADMIN_PASSWORD=[NEW_DBADMIN_PASSWORD] \
APPUSER_USERNAME=[NEW_APPUSER_USERNAME] \
APPUSER_PASSWORD=[NEW_APPUSER_PASSWORD] \
OUTFILE=/etc/cyber-indicators/config/database.yml \
TEMPLATE=/etc/cyber-indicators/templates/etc/cyber-indicators/database.yml.erb \
/var/apps/cyber-indicators/bin/rake db:template:create
```

**Run the database migrations.**

```bash
RAILS_ENV=dbadmin /var/apps/cyber-indicators/bin/rake db:migrate
```

**Grant schema privileges.**

```bash
RAILS_ENV=dbadmin /var/apps/cyber-indicators/bin/rake db:grant
```

**Apply synonyms**

```bash
/var/apps/cyber-indicators/bin/rake db:synonyms
```

**Remove the existing Kerberos keytab file.**

```bash
rm /usr/share/tomcat7/conf/cyber-indicators.keytab
```

**Disable application SSO.**

```bash
/var/apps/cyber-indicators/bin/initialize-application-webserver
```

## [Troubleshooting] Run the task.
```bash
TEMPLATE=/etc/cyber-indicators/templates/etc/cyber-indicators/tomcat7/conf/server.xml.erb \
OUTFILE=/usr/share/tomcat7/conf/server.xml /var/apps/cyber-indicators/bin/rake \
db:template:create
```

## [Troubleshooting]  Manually disable SSO.
Edit the tomcat configuration file:

```bash
/usr/share/tomcat7/conf/server.xml
```

**Locate the Application Context.**

The application context looks like this:

```xml
    <Context docBase="cyber-indicators" path="/cyber-indicators" reloadable="true">
      <Valve className="indicators.cyber.valves.BlackList"
             disallowedHeaders="REMOTE_USER|AUTH_MODE|REMOTE_USER_GUID"/>
      <Valve className="indicators.cyber.valves.ActiveDirectory"
             krb5Conf="/etc/cyber-indicators/tomcat7/conf/krb5.conf"
             loginConf="/etc/cyber-indicators/tomcat7/conf/login.conf"
             loginModule="active-directory"
             />
    </Context>
```

Comment-out the Valves in the Application Context.

```xml
    <Context docBase="cyber-indicators" path="/cyber-indicators" reloadable="true">
      <!--
      <Valve className="indicators.cyber.valves.BlackList"
             disallowedHeaders="REMOTE_USER|AUTH_MODE|REMOTE_USER_GUID"/>
      <Valve className="indicators.cyber.valves.ActiveDirectory"
             krb5Conf="/etc/cyber-indicators/tomcat7/conf/krb5.conf"
             loginConf="/etc/cyber-indicators/tomcat7/conf/login.conf"
             loginModule="active-directory"
             />
      -->
    </Context>
```

**Remove the existing SSL certificates.**

```bash
$JAVA_HOME/bin/keytool -delete -alias cyber-indicators -keystore $JAVA_HOME/jre/lib/security/cacerts
$JAVA_HOME/bin/keytool -delete -alias search -keystore $JAVA_HOME/jre/lib/security/cacerts
```

**Reconfigure SSL by following the procedure "Configure SSL".**

**If using Active Directory, reconfigure SSO by following the procedure "Configure SSO using Active Directory".**

**If using ICAM Authentication, reconfigure SSO by following the procedure "Configure SSO Using ICAM Authentication".**

**Restart the cyber indicators service**

```bash
service cyber-indicators restart
```

# Collecting Support Information

The Cyber Indicators application provides a script to assist with collecting troubleshooting information.

* Collect support information

```bash
/var/apps/cyber-indicators/sbin/collect-support-information
```

This script will collect relevant information for troubleshooting.

!Important!  The contents of the support information contains system configuration specific information.  Therefore, you should safeguard this information.  For example, you should password protect the file before sending it outside of your organization.

# Adding a Redirect to Tomcat

## Prerequisites

* Configured Firewall

## Configure Redirect

*Create a root webapp.*

```bash
mkdir -p /usr/share/tomcat7/webapps/ROOT
```

*Add the index.jsp redirect file.*

```bash
touch /usr/share/tomcat7/webapps/ROOT/index.jsp
```

*Add the redirect to the contents of the index.jsp file.*

Edit index.jsp and add the following entry:

```bash
<% response.sendRedirect("/cyber-indicators"); %>
```

!Note! You must change url-to-redirect-to.

*Change ownership.*

```bash
chown -R tomcat:tomcat /usr/share/tomcat7/webapps/ROOT
```

# Setting up dissemination from ECIS to FLARE

## Via SFTP

Note: If you are attempting to set up dissemination via FLARE API, refer to the "Via API" section, below in this document.

## Prerequisites

You will need the following pieces of information:

  * The IP/Hostname of the FLARE server (where the disseminated files are going to be copied)
  * The directories that the disseminated files will be going to on the FLARE server
  * The name of the user which SFTP will be connecting to on the FLARE server
  * The password for the user which SFTP will be connecting to on the FLARE server

The following will need to be set up on the FLARE server:

  * The above user with the above password
  * The above user needs to have read and write access to the subdirectories of the FLAREclient on the FLARE server
  * The FLARE system needs to be set up to accept SFTP connections.

## Creating the SSH Key

Once you have the user set up properly on the FLARE server, with proper permissions to access the directories, follow the instructions below:

On the ECIS VM:

1. Log in, and sudo to root

2. Run ```ssh-keygen```
Hit enter 3 times

3. ```sftp <above username>@<FLARE server IP>```
Enter password for the account
```
cd .ssh
get authorized_keys
quit
```
NOTE: If authorized_keys does not exist, that is fine.

4. ```
vi authorized_keys
:r ~/.ssh/id_rsa.pub
:wq
```

5. ```sftp <above username>@<FLARE server IP>```
Enter password for the account
```
cd .ssh
put authorized_keys
quit
```

6. ```sftp <above username>@<FLARE server IP>```
You should NOT be prompted for the password
```quit```

At this point, the SFTP connection should be set up properly.

## Create disseminate.yml file

The /etc/cyber-indicators/config/disseminate.yml file should contain the following (```<IP or hostname for FLARE server>``` and ```<above username>``` will need to be replaced with the proper values)

```
#ECIS Information
#FLARE Server
FLARE_SERVER: <IP or hostname for FLARE server>
FLARE_SERVER_USERNAME: <above username>
# API URI information - For https://relayout:1234/publish?collection=<feed>
#     you would use https://relayout:1234/publish
#     Do not put ?collection=<feed>
FLARE_API_URI: https://localhost:3000/cyber-indicators/uploads?overwrite=Y
# MODE is one of SFTP, API, BOTH
MODE: SFTP
```

## Create disseminate_feeds.yml file

The /etc/cyber-indicators/config/disseminate_feeds.yml file should contain the following (both ```<proper directory...>``` will need to be replaced with the proper values)

```
FEDGOV:
    profile:    ISA
    government: Y
    directory:  <proper directory for FEDGOV feed -- get from FLARE team>
    feed:       #not needed
    active:     true
AIS:
    profile:    AIS
    government: N
    directory:  <proper directory for AIS feed -- get from FLARE team>
    feed:       #not needed
    active:     true
CISCP:
    profile:    CISCP
    government: Y
    directory:  <proper directory for CISCP feed -- get from FLARE team>
    feed:       #not needed
    active:     false
SANITIZED_MAPPINGS:
    directory:  <proper directory for SANITIZED_MAPPINGS -- get from FLARE team>
    feed:       #not needed
    active:     false
```

Continue with the "Set up cron task" section, below.

## Via API

## Prerequisites

You will need the following pieces of information:

  * The URI of the API on the FLARE server (where the disseminated files are going to be copied)
  * The names of the feeds which the disseminated files will be going to on the FLARE server

## Create disseminate.yml file

The /etc/cyber-indicators/config/disseminate.yml file should contain the following (```<API>``` will need to be replaced with the proper value)

```
#ECIS Information
#FLARE Server
FLARE_SERVER: #not needed
FLARE_SERVER_USERNAME: #not needed
# API URI information - For https://relayout:1234/publish?collection=<feed>
#     you would use https://relayout:1234/publish
#     Do not put ?collection=<feed>
FLARE_API_URI: <<API>>
# MODE is one of SFTP, API, BOTH
MODE: API
```

## Create disseminate_feeds.yml file

The /etc/cyber-indicators/config/disseminate_feeds.yml file should contain the following (both ```<proper directory...>``` will need to be replaced with the proper values)

```
FEDGOV:
    profile:    ISA
    government: Y
    directory:  #not needed
    feed:       <proper name for FEDGOV feed -- get from FLARE team>
    active:     true
AIS:
    profile:    AIS
    government: N
    directory:  #not needed
    feed:       <proper name for AIS feed -- get from FLARE team>
    active:     true
CISCP:
    profile:    CISCP
    government: Y
    directory:  #not needed
    feed:       CISCP
    active:     false
SANITIZED_MAPPINGS:
    directory:  #not needed
    feed:       JSON
    active:     false
```

## Set up cron task

Lastly, a cron job needs to be set up.  Add this to the root user's crontab file:

```*/10 * * * * /var/apps/cyber-indicators/bin/run_dissemination```

# Creating a machine user

## How to create a machine user

1. Accredited NSD systems may be authorized for write access to the API.
2. Create a Cyber Indicators account for the system.  (In the navigation menu, click users.  Click the "New" button.)
3. The username of the user does not need to match an Active Directory username, but rather should be the name of the system which will be using the API.  Be sure to assign the user to a group which has the proper write permissions to support what that machine user will be doing.
4. After creating the user, click on "Edit".
5. Click the "Generate API Key" button
6. The system will generate an API key for the user.  Click the "Click to show" text to shown the API key.  Send this API key to the user in a secure manner
7. The the user's initial API Key secret.  In the text box below "Change API Key Secret", type in an API Key secret.  Click the "Change API Key Secret" button.  The user's API Key secret is now set.
8. Securely send the API Key and API Key Secret to the user.  The user will use these credentials to generate an API Key Hash to communicate with the API
9. The account must be converted to be a machine user.  Only a System Administrator may perform this step.
10. As a system administrator, run the following as root, substituting the correct USERNAME for what you used in step 3 when creating the user:

```bash
/var/apps/cyber-indicators/bin/rake machineuser:set['USERNAME']
```

You can change the user back to a regular user by changing 'set' to 'unset'

## Revoking an API key

API Keys may be revoked from either regular users or machine users by performing the following steps:

1. Click Users
2. Click the username
3. Click Edit
4. Under API Key, click the "Revoke API Key" button

# Appendix I - Proper settings for each Server Type

!Note! These are the proper values for CIAP / CIR / ECIS / TS-CIAP version 6.5.5-rcX

## Values for DTE:

| Field | CIAP | ECIS | CIR | TS-CIAP |
| -------- | -------- | -------- | -------- | -------- |
| STIX_PREFIX | NCCIC | NCCIC | NCCIC | NCCIC |
| SSO_AD | true | false | false | false |
| SYSTEM_GUID | auto-generated | auto-generated | auto-generated | auto-generated |
| DEFAULT_MAX_RECORDS | 100 | 100 | 100 | 100 |
| MAX_PER_PAGE | 100 | 100 | 100 | 100 |
| TOU | true | true | true | true |
| MODE | CIAP | CIAP | CIR | CIAP |
| HUMAN_REVIEW_CLEAR_TO | PII Redacted | PII Redacted | PII Redacted | PII Redacted |
| HUMAN_REVIEW_ENABLED | true | false | false | false |
| SANITIZATION_ENABLED | false | true | false | false |
| CLASSIFICATION | false | false | false | true |
| BANNER_TEXT | UNCLASSIFIED | UNCLASSIFIED | UNCLASSIFIED | TOP SECRET (UNCLASSIFIED FOR TESTING PURPOSES) |
| BANNER_TEXT_COLOR | 000000 | 000000 | 000000 | 000000 |
| BANNER_COLOR | 00FF00 | 00FF00 | 00FF00 | FFE500 |
| READ_ONLY_EXT | -dup | -dup | -dup | -dup |
| USE_AMQP_SENDER | false | false | false | false |
| USE_AMQP_RECEIVER | false | false | false | false |

## Values for Production:
#
| Field | CIAP | ECIS | CIR | TS-CIAP |
| -------- | -------- | -------- | -------- | -------- |
| STIX_PREFIX | NCCIC | NCCIC | NCCIC | NCCIC |
| SSO_AD | true | false | true | false |
| SYSTEM_GUID | auto-generated | auto-generated | auto-generated | auto-generated |
| DEFAULT_MAX_RECORDS | 100 | 100 | 100 | 100 |
| MAX_PER_PAGE | 100 | 100 | 100 | 100 |
| TOU | true | true | true | true |
| MODE | CIAP | CIAP | CIR | CIAP |
| HUMAN_REVIEW_CLEAR_TO | PII Redacted | PII Redacted | PII Redacted | PII Redacted |
| HUMAN_REVIEW_ENABLED | true | false | false | false |
| SANITIZATION_ENABLED | false | true | false | false |
| CLASSIFICATION | false | false | false | true |
| BANNER_TEXT | UNCLASSIFIED | UNCLASSIFIED | UNCLASSIFIED | TOP SECRET |
| BANNER_TEXT_COLOR | FFFFFF | FFFFFF | FFFFFF | 000000 |
| BANNER_COLOR | 00FF00 | 00FF00 | 00FF00 | FFE500 |
| READ_ONLY_EXT | -dup | -dup | -dup | -dup |
| USE_AMQP_SENDER | false | false | false | false |
| USE_AMQP_RECEIVER | false | false | false | false |

