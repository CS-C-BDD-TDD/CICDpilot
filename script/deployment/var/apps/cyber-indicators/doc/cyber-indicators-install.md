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

!Note! For Microsoft Windows systems, the carat ("^") is used in place of a backslash.

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

!Note! Replace the [EXAMPLE_DBADMIN_USERNAME] with the dbadmin username.

!Note! Replace the [EXAMPLE_DATABASE_NAME] with the database name.

!Note! The database name is located in the tnsnames.ora file.

!Example! An example of a tnsnames.ora file is as follows:

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

!Note! In this example tnsnames.ora file, the connection string is identified by "EXAMPLE_DATABASE_NAME".

  * Connect to the DB as the application user.

```bash
sqlplus [EXAMPLE_APPUSER_USERNAME]@[EXAMPLE_DATABASE_NAME]
```

!Note! Replace the [EXAMPLE_APPUSER_USERNAME] with the appuser username.

!Note! Replace the [EXAMPLE_DATABASE_NAME] with the database name.

!Note! The database name is located in the tnsnames.ora file.

!Example! An example of a tnsnames.ora file is as follows:

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

!Note! In this example tnsnames.ora file, the connection string is identified by "EXAMPLE_DATABASE_NAME".

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

!Note! $CATALINA_HOME is the path to the Web server

!Note! The TIMESTAMP is assigned when the application starts.

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

!Note! The Yum package manager can install local files in addition to files located in a Yum repository.  As an alternative, you may also use the "rpm" command to install the software.

## Install the Cyber Indicators package

**Install the RPM.**

```bash
cd [PATH_TO_CYBER_INDICATORS_RPM]
yum -y install [NAME_OF_CYBER_INDICATORS_RPM]
```

!Important!  This RPM depends on a STIG-hardened version of Tomcat.

!Note! The Yum package manager can install local files in addition to files located in a Yum repository.  As an alternative, you may also use the "rpm" command to install the software.

**Link the Web Application Folders**

```bash
/var/apps/cyber-indicators/bin/link-tomcat7
```

!Note! This command does not produce any output.

!Note! You can verify that this command worked by viewing the newly created /usr/share/tomcat7 directory.

**Initialize the application web server.**

```bash
/var/apps/cyber-indicators/bin/initialize-application-webserver
```

**Initialize the application System Configuration.**

```bash
TNS_ADMIN=[TNS_ADMIN] /var/apps/cyber-indicators/bin/initialize-sysconfig
```

**Initialize the application settings.**

```bash
/var/apps/cyber-indicators/bin/initialize-system-settings
```

!Important! Replace the TNS_ADMIN value with the root path to your Oracle TNS configuration file.

!Example! Setting the TNS_ADMIN environment variable.

If your Oracle TNS configuration file is located here:

```bash
/etc/tnsnames.ora
```

Then the TNS_ADMIN environment variable should be set to:

```bash
TNS_ADMIN=/etc
```

# Displaying the Version Number in the Application

The application will display its version number at the bottom of the webpage once logged in.  You can override this by setting the environment variable VERSION.  Set the environment variable inside of /etc/sysconfig/cyber-indicators

Edit the application system configuration file.

```bash
/etc/sysconfig/cyber-indicators
```

!Example! Change the VERSION environment variable

```bash
# VERSION: Specify the version number shown to the users
VERSION=vEXAMPLE
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

!Important!  The two database schemas that are required are called the appuser and dbadmin schemas.

!Important!  You must have a valid tnsnames.ora file that is correctly configured.

!Important!  One common way to verify connectivity between the application server and the database server is to use the Oracle toolchain (e.g. SQLPlus). Verify that you can connect from the application server to the database server using the credentials for each schema.

!Note!  This document refers to the schema under which the application runs in production as the appuser schema.

!Note!  This document refers to the schema under which the application modifies the structure of the database as the dbadmin schema.  The dbadmin schema owns all database objects used by the application.  The application mutates the database, creating tables and sequences under the dbadmin schema.

!Note!  An Oracle stored procedure, executed as the dbadmin, assigns privileges of the objects that the dbadmin schema creates to a role.

!Note!  An Oracle stored procedure, executed as the appuser, creates Oracle synonyms so that the appuser can access objects owned by dbadmin.

!Note! You may wish to add the cyber-indicators binaries to your PATH for convenience.

```bash
export PATH=$PATH:/var/apps/cyber-indicators/bin
```

## Configure the Application for Oracle

**Grant the application access to the Oracle configuration file.**

```bash
chown root:tomcat $TNS_ADMIN/tnsnames.ora
chmod 0750 $TNS_ADMIN/tnsnames.ora
```

!Note! Replace TNS_ADMIN with the path to the tnsnames.ora file.

**Initialize the database configuration file.**

```bash
DATABASE=[EXAMPLE_DATABASE_NAME] \
DBADMIN_USERNAME=[DBADMIN_USERNAME] \
DBADMIN_PASSWORD=[DBADMIN_PASSWORD] \
APPUSER_USERNAME=[APPUSER_USERNAME] \
APPUSER_PASSWORD=[APPUSER_PASSWORD] \
/var/apps/cyber-indicators/bin/initialize-database-configuration
```

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

!Note! In this example tnsnames.ora file, the connection string is identified by "EXAMPLE_DATABASE_NAME".

!Note! When entering the DBADMIN_PASSWORD or APPUSER_PASSWORD, please use single-quotes surrounding the password.  Double-quotes or unquotes passwords with special characters may be interpreted by the shell and insert the incorrect password in to the configuration files.

!Note! The ordering of arguments does not matter.

## Install the Grant Privileges Stored Procedure

**Initialize the stored procedure.**

```bash
APP_ROLE=[APP_ROLE] /var/apps/cyber-indicators/bin/initialize-grant-privileges-stored-procedure
```

!Important! You will need to ask a Database Administator for the correct APP_ROLE value.

**Install the procedure.**

```bash
DBADMIN_USERNAME=[DBADMIN_USERNAME] \
DBADMIN_PASSWORD=[DBADMIN_PASSWORD] \
DATABASE=[DATABASE_NAME] \
ORACLE_HOME=/usr/lib/oracle/11.2/client64/ \
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/oracle/11.2/client64/lib/ \
/var/apps/cyber-indicators/bin/install-grant-privileges-stored-procedure
```

!Important!  You must replace the DBADMIN_USERNAME and DBADMIN_PASSWORD with the correct credentials for the dbadmin schema.

!Important!  You must replace the DATABASE_NAME with the database connection string specified in the validated tnsnames.ora file.

!Important!  This requires the installation of Oracle's tool chain for Linux.  Please ensure that you have installed the Oracle Instant Client with SQLPlus.  Please refer to Oracle's guided documentation on installing the Oracle Instant Client with SQLPlus for the version of Oracle that you intend to use.  You will need to replace ORACLE_HOME and the LD_LIBRARY_PATH with values appropriate for your installation of the Oracle tool chain.

## Install the Create Synonyms Stored Procedure

**Initialize the stored procedure.**

```bash
DBADMIN_USERNAME=[DBADMIN_USERNAME] /var/apps/cyber-indicators/bin/initialize-create-synonyms-stored-procedure
```

!Important! You must replace the DBADMIN_USERNAME with the correct username for the dbadmin schema.

**Install the procedure.**

```bash
APPUSER_USERNAME=[APPUSER_USERNAME] \
APPUSER_PASSWORD=[APPUSER_PASSWORD] \
DATABASE=[DATABASE_NAME] \
ORACLE_HOME=[ORACLE_HOME] \
LD_LIBRARY_PATH=[LD_LIBRARY_PATH] \
/var/apps/cyber-indicators/bin/install-create-synonyms-stored-procedure
```

!Important! You must replace the APPUSER_USERNAME and APPUSER_PASSWORD with the correct credentials for the appuser schema.

!Important! You must replace ORACLE_HOME with the path to Oracle's home directory on your system.  This varies by installation.

!Important!  You must replace the DATABASE_NAME with the database connection string specified in the validated tnsnames.ora file.

!Important! You must replace LD_LIBRARY_PATH with the path to Oracle's library files.  This is typically $ORACLE_HOME/lib.

## Run the database migrations

**Run the task.**

```bash
RAILS_ENV=dbadmin /var/apps/cyber-indicators/bin/rake db:migrate
```

!Important! You must configure the /etc/cyber-indicators/config/database.yml file before migrating the database.

!Important! The RAILS_ENV should match the environment permitted to execute schema changes in the /etc/cyber-indicators/config/database.yml.  By default, this value is 'dbadmin'.

!Important! The RAILS_ENV can be assigned only two values "dbadmin" or "production".  Please refer to the example /etc/cyber-indicators/config/database.yml.

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

!Note!  In this example, RAILS_ENV would be assigned "dbadmin", which corresponds to the "dbadmin" section identifier in this file.  The only section identifiers permitted for the Cyber Indicators application are "production" and "dbadmin".

## Grant privileges to the Application User

!Note! The Cyber Indicators application uses two database schemas: one for the appuser, and one for dbadmin.  After the database tables have been created from the section above as dbadmin, you must allow the appuser privileges to these tables.

**Execute the task.**

```bash
RAILS_ENV=dbadmin /var/apps/cyber-indicators/bin/rake db:grant
```

!Important! The RAILS_ENV should match the environment permitted to execute schema changes in the /etc/cyber-indicators/config/database.yml.  By default, this value is 'dbadmin'.

!Important! The RAILS_ENV can be assigned only two values "dbadmin" or "production".  Please refer to the example /etc/cyber-indicators/config/database.yml.

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

!Note!  In this example, RAILS_ENV would be assigned "dbadmin", which corresponds to the "dbadmin" section identifier in this file.  The only section identifiers permitted for the Cyber Indicators application are "production" and "dbadmin".

## Apply Synonyms to the Application User

**Run the synonyms task.**

```bash
RAILS_ENV=production /var/apps/cyber-indicators/bin/rake db:synonyms
```

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

!Note!  In this example, RAILS_ENV would be assigned "production", which corresponds to the "production" section identifier in this file.  The only section identifiers permitted for the Cyber Indicators application are "production" and "dbadmin".

## Initialize the Application.

**Bootstrap the application.**

```bash
/var/apps/cyber-indicators/bin/rake app:bootstrap
```

**Create the first user account.**

```bash
/var/apps/cyber-indicators/bin/rake user:create USERNAME=[USERNAME] FIRST_NAME=[FIRST_NAME] LAST_NAME=[LAST_NAME] EMAIL_ADDRESS=[EMAIL_ADDRESS] GROUPS=Administrator
```

!Example!

```bash
/var/apps/cyber-indicators/bin/rake user:create USERNAME=firstname.lastname FIRST_NAME=Firstname LAST_NAME=Lastname EMAIL_ADDRESS=firstname.lastname@domain.com GROUPS='Administrator'
```

!Important! The USERNAME field must match an account that you can log in to with Active Directory.

!Note! The first user account is an administator.

!Note! This step may be executed multiple times for multiple user accounts.

# Configure SSO using Active Directory

!Note! If you are setting up this server for ICAM authentication, this section can be completely skipped. Go to the section labelled **Configure SSO using ICAM Authentication**

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

!Note! The default service account name is "tomcat.svc".  You may use any service account name that is valid within Active Directory.  If you use a different service account name, you will need to adjust configurations to reflect this new name.

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

!Note!  This section is accomplished on a Windows workstation or server within the Active Directory domain that you are configuring Single Sign On.

!Note!  The default service account name is "tomcat.svc".  You may use any service account name that is valid within Active Directory.  If you use a different service account name, you will need to adjust configurations to reflect this new name.

Log in to Windows Active Directory with an account capable of running the "Set Service Principal" command.

**Launch a Windows Command Prompt as an Administrator.**

Verify that the Service Account does not have any Service Principal registrations.

```cmd
C:\>setspn.exe -L [SERVICE_ACCOUNT_NAME]
Registered ServicePrincipalNames for CN=SERVICE ACCOUNT NAME,CN=Users,DC=domain,DC=com:
```

!Note! You should see that there are no registered Service Principal Names.

!Note! Replace SERVICE_ACCOUNT_NAME with the service principal account login name.

**Verify that the application server is not registered with any service principals.**

```cmd
C:\>setspn -Q */[APPLICATION_SERVER_FQDN]
Checking domain DC=domain,DC=com

No such SPN found.
```

!Note! Replace the [APPLICATION_SERVER_FQDN] with the fully qualified domain name of the application server.  For example, if the application server is applicationserver.domain.com, then replace [APPLICATION_SERVER_FQDN] with applicationserver.domain.com.

!Note! If there are alternate URLs used to access the application server, repeat this command replacing the [APPLICATION_SERVER_FQDN] with the alternate URL.  For example, if applicationserver is also used to refer to the application server within the domain, then replace [APPLICATION_SERVER_FQDN] with applicationserver.

!Note! All queries should return "No such SPN found".

**Register the application server service principal.**

```cmd
C:\>setspn -A HTTP/[APPLICATION_SERVER_FQDN] [DOMAIN]\[SERVICE_ACCOUNT_NAME]
Registering ServicePrincipalNames for CN=service account name,CN=Users,DC=domain,DC=com
        HTTP/[APPLICATION_SERVER_FQDN]
Updated object
```

!Note! Replace the [APPLICATION_SERVER_FQDN] with the fully qualified domain name of the application server.  For example, if the application server is applicationserver.domain.com, then replace [APPLICATION_SERVER_FQDN] with applicationserver.domain.com.

!Note! Replace SERVICE_ACCOUNT_NAME with the service principal account login name.

!Note! If there are alternate URLs used to access the application server, repeat this command replacing the [APPLICATION_SERVER_FQDN] with the alternate URL.  For example, if applicationserver is also used to refer to the application server within the domain, then replace [APPLICATION_SERVER_FQDN] with applicationserver.

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

**Initialize the Kerberos Login Configuration file.**

```bash
ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME=[ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME] /var/apps/cyber-indicators/bin/initialize-login-configuration
```

!Note! The ordering of arguments does not matter.

!Note! Replace the FQDN_DOMAIN with the FQDN of your Active Directory Domain.

!Note! Replace the FQDN_ACTIVE_DIRECTORY_DOMAIN_CONTROLLER with the FQDN of an Active Directory Domain Controller.

!Example! Generating the Kerberos Configuration file:

```bash
FQDN_DOMAIN=DOMAIN.COM FQDN_ACTIVE_DIRECTORY_DOMAIN_CONTROLLER=adc.domain.com /var/apps/cyber-indicators/bin/initialize-kerberos-configuration
```

!Important! The value for FQDN_DOMAIN must be in uppercase.

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

!Note! Replace [ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME] with the Service Account username that you created.  If you are following the default configuration, then this is tomcat.svc.

!Note! Replace the [ACTIVE_DIRECTORY_SERVICE_ACCOUNT_PASSWORD] with the password for the Service Account that you created.

**Connect to Kerberos.**

```bash
/var/apps/cyber-indicators/bin/connect-to-kerberos-hellokdc
```

You should see "Connection test successful."

!Note! This means that the Service Principal is registered correctly, and that the networking, DNS, and Time Synchronization is configured correctly for the application server.

!Note! This also means that the krb5.conf and login.conf files are configured correctly.

**Remove the username and password information from the HelloKDC properties file.**

```bash
ACTIVE_DIRECTORY_SERVICE_ACCOUNT_PASSWORD="" /var/apps/cyber-indicators/bin/initialize-hellokdc
```

## Authenticate to Kerberos using HelloKeytab

Before you begin, you will need:

* Access to a Windows workstation that is a member of Active Directory.  This workstation should not be an Active Directory server.
* Access to an Domain Administrator account capable of running the "Set Service Principal" (setspn.exe) command within Windows AD.
* Access to an Active Directory server with the "setspn.exe" command installed.
* Access to an Active Directory server with the "ktpass.exe" command installed.

!Note!  This section is accomplished on a Windows workstation or server within the Active Directory domain that you are configuring Single Sign On.

!Note!  The "ktpass.exe" tool is provided in the Windows Server toolkit.

*Log in to the Windows Active Directory server that has "setspn.exe" and "ktpass.exe" installed on it as the Domain Administrator capable of running these commands.*

**Launch a Windows Command Prompt as an Administrator.**

**Create the Kerberos Keytab.**

```bash
ktpass /out cyber-indicators.keytab
       /princ [ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME]@[DOMAIN_FQDN]
       /pass [ACTIVE_DIRECTORY_SERVICE_ACCOUNT_PASSWORD]
       /ptype KRB5_NT_PRINCIPAL
```

!Note! Replace [APPLICATION_SERVER_FQDN] with the Fully Qualified Domain Name for the application server.

!Note! Replace [DOMAIN_FQDN] with fully-qualified domain name.

!Note! Replace [ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME] with the username of the service account.

!Note! Replace [ACTIVE_DIRECTORY_SERVICE_ACCOUNT_PASSWORD] with the service account password.

!Example! Given an APPLICATION_SERVER_FQDN = server.domain.com, DOMAIN = DOMAIN.COM, ACTIVE_DIRECTORY_SERVICE_ACCOUNT_USERNAME = tomcat.svc, and ACTIVE_DIRECTORY_SERVICE_ACCOUNT_PASSWORD = P@ssw0rd!

```bash
ktpass /out cyber-indicators.keytab^
       /princ tomcat.svc@DOMAIN.COM^
       /pass P@ssw0rd!^
       /ptype KRB5_NT_PRINCIPAL
```

**Copy the Kerberos Keytab file to the application server.**

**Log out of the Windows Active Directory server.**

!Note! You no longer need to be logged in to the Windows Active Directory server.

**Move the Kerberos Keytab on the Application Server.**

Move the keytab file to this location:

```
/usr/share/tomcat7/conf/cyber-indicators.keytab
```

**Initialize HelloKeytab**

```bash
APPLICATION_SERVER_URL=[APPLICATION_SERVER_URL] /var/apps/cyber-indicators/bin/initialize-hellokeytab
```

!Note! Replace APPLICATION_SERVER_URL with the full URL that users will use to access the application.  For example, if the cyber-indicators application will be accessed via https://www.server.com:8443/cyber-indicators, then you should enter https://www.server.com:8443/cyber-indicators as the APPLICATION_SERVER_URL.

**Connect to Kerberos.**

```bash
/var/apps/cyber-indicators/bin/connect-to-kerberos-hellokeytab
```
A lot of information will be generated.  If you do not see any exceptions generated, then you have successfully authenticated against Active Directory using the keytab file that you generated.  Your keytab file is valid.

## Configure the Application to use the Keytab

**Initialize the web server with Kerberos.**

```bash
/var/apps/cyber-indicators/bin/initialize-application-webserver-with-kerberos
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

!Note! You should substitute port 1521 with the port that your Oracle database uses.

!Important! You may have additional firewall rules for your organization in addition to these rules.  Please merge these rules with your rules.

Please configure your firewall with these rules.

# Start the Application

**Restart the application service.**

```bash
service cyber-indicators restart
```

**Browse to the application.**

Log in to a workstation in the Windows Active Directory Domain as the user account created in "Bootstrap the application"

Open your web browser.

Browse to the application server FQDN.

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

!Important! The application's database is external to the application server.  You must coordinate with the manager of the application's database to unlock the schema.

## Install the Upgraded Application Package

**Stop the cyber-indicators service.**

```bash
service cyber-indicators stop
```

**Uninstall the application.**

```bash
yum -y remove cyber-indicators
```

!Example!

```bash
[root@application-server ~]$ yum -y remove cyber-indicators
Loaded plugins: fastestmirror
Setting up Remove Process
Resolving Dependencies
--> Running transaction check
---> Package cyber-indicators.x86_64 0:p0 will be erased
--> Finished Dependency Resolution

Dependencies Resolved

==========================================================================================================================================================================
 Package                              Arch                       Version                              Repository                                                     Size
==========================================================================================================================================================================
Removing:
 cyber-indicators                     x86_64                     p0                      @/cyber-indicators-p0.x86_64                     103 M

Transaction Summary
==========================================================================================================================================================================
Remove        1 Package(s)

Installed size: 103 M
Downloading Packages:
Running rpm_check_debug
Running Transaction Test
Transaction Test Succeeded
Running Transaction
  Erasing    : cyber-indicators-p0.x86_64                                                                                                                1/1
  Verifying  : cyber-indicators-p0.x86_64                                                                                                                1/1

Removed:
  cyber-indicators.x86_64 0:master-p55f47f2

Complete!
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

!Important! The RAILS_ENV should match the environment permitted to execute schema changes in the /etc/cyber-indicators/config/database.yml.  By default, this value is 'dbadmin'.

!Important! The RAILS_ENV can be assigned only two values "dbadmin" or "production".  Please refer to the example /etc/cyber-indicators/config/database.yml.

!Example!  /etc/cyber-indicators/config/database.yml:

```yaml
production:
  adapter: oracle_enhanced
  database: example_database
  username: example_username
  password: example_password
dbadmin:
  adapter: oracle_enhanced
  database: example_database
  username: example_username
  password: example_password
```

!Note!  In this example, RAILS_ENV would be assigned "dbadmin", which corresponds to the "dbadmin" section identifier in this file.  The only section identifiers permitted for the Cyber Indicators application are "production" and "dbadmin".

**Grant application permissions.**

```bash
RAILS_ENV=dbadmin /var/apps/cyber-indicators/bin/rake db:grant
```

!Important! The RAILS_ENV should match the environment permitted to execute schema changes in the /etc/cyber-indicators/config/database.yml.  By default, this value is 'dbadmin'.

!Important! The RAILS_ENV can be assigned only two values "dbadmin" or "production".  Please refer to the example /etc/cyber-indicators/config/database.yml.

!Example!  /etc/cyber-indicators/config/database.yml:

```yaml
production:
  adapter: oracle_enhanced
  database: example_database
  username: example_username
  password: example_password
dbadmin:
  adapter: oracle_enhanced
  database: example_database
  username: example_username
  password: example_password
```

!Note!  In this example, RAILS_ENV would be assigned "dbadmin", which corresponds to the "dbadmin" section identifier in this file.  The only section identifiers permitted for the Cyber Indicators application are "production" and "dbadmin".

**Apply synonyms to the application user.**

```bash
/var/apps/cyber-indicators/bin/rake db:synonyms
```

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

!Note!  In this example, RAILS_ENV would be assigned "production", which corresponds to the "production" section identifier in this file.  The only section identifiers permitted for the Cyber Indicators application are "production" and "dbadmin".

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

!Note! If in Active Directory mode, and previously working users start getting "You do not have an account on this system",

Run the following to fix and restat cyber indicators:

```bash
/var/apps/cyber-indicators/sbin/set-kerberos-authentication
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

!Important! You must verify connectivity to the database server out-of-band of the application.  One common way to do this is to use the Oracle toolchain (e.g. SQLPlus) to verify that you can connect from the application server to the database server using the credentials for each schema.

!Important! You must be able to log in to both schemas before proceeding.

Verify that the privileges for new_appuser and new_dbadmin match the privileges previously specified in this guide.

!Note! You will need to consult with the Oracle Database Administrator to determine whether or not the permissions are correct.

**Create the application database configuration file.**

DATABASE=[NEW_DATABASE] \
DBADMIN_USERNAME=[NEW_DBADMIN_USERNAME] \
DBADMIN_PASSWORD=[NEW_DBADMIN_PASSWORD] \
APPUSER_USERNAME=[NEW_APPUSER_USERNAME] \
APPUSER_PASSWORD=[NEW_APPUSER_PASSWORD] \
/var/apps/cyber-indicators/bin/initialize-database-configuration

!Note! The ordering of arguments does not matter.

!Note!  To distinguish between previous examples, the database configuration settings are prefixed with "new".  You should replace these values with values that are appropriate for your specific environment.

!Important!  The TNS_ADMIN environment variable must be set.

!Example! After running this command, the database.yml file should look like this
```bash
/etc/cyber-indicators/config/database.yml
```

```bash
production:
  adapter: oracle_enhanced
  database: new_example_database_name
  username: new_appuser_username
  password: new_appuser_password
dbadmin:
  adapter: oracle_enhanced
  database: new_example_database_name
  username: new_dbadmin_username
  password: new_dbadmin_password
```

!Example! An example of a tnsnames.ora file is as follows:

```bash
NEW_EXAMPLE_DATABASE_NAME =
  (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = db)(PORT = 1521))
      (CONNECT_DATA =
        (SERVER = DEDICATED)
        (SERVICE_NAME = EXAMPLE_SERVICE_NAME)
      )
  )
```

!Note! In this example tnsnames.ora file, the connection string is identified by "NEW_EXAMPLE_DATABASE_NAME".

!Important! Replace the new_database_name with the NEW_EXAMPLE_DATABASE_NAME set in the tnsnames.ora file.

!Important! Replace the new_dbadmin_username with the username for the dbadmin schema.

!Important! Replace the new_dbadmin_password with the password for the dbadmin schema.

!Important! Replace the new_appuser_username with the username for the appuser schema.

!Important! Replace the new_appuser_password with the password for the appuser schema.

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

**Remove the existing SSL certificates.**

```bash
$JAVA_HOME/bin/keytool -delete -alias cyber-indicators -keystore $JAVA_HOME/jre/lib/security/cacerts
$JAVA_HOME/bin/keytool -delete -alias search -keystore $JAVA_HOME/jre/lib/security/cacerts
```

!Note! The default password for the keystore is 'changeit'

**Reconfigure SSL by following the procedure "Configure SSL".**

**If using Active Directory, reconfigure SSO by following the procedure "Configure SSO using Active Directory".**

!Important! For this procedure, you must choose a different service account name than "tomcat.svc".

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

