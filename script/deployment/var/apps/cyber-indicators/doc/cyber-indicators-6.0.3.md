# Post-Upgrade Notes

After executing the standard "Upgrade the Application" procedure, and starting the application, please take the following actions.

* Reinitialize the application Kerberos configuration.

```bash
service cyber-indicators stop
/var/apps/cyber-indicators/initialize-application-webserver-with-kerberos
service cyber-indicators start
```

!Note! This recreates the following file:  /usr/share/tomcat7/conf/server.xml.  You should back-up this file prior to running this task.

!Note! This assumes that you have not made any custom modifications to the Kerberos configuration file.

!Important! If this procedure disables Kerberos, then you must reconfigure SSO by following the "Configure SSO" section of the System Administrators Guide.

!Important! Failure to execute this step will disable write access to the application.

* Reindex the application indicators.

```bash
/var/apps/cyber-indicators/bin/rake sunspot:reindex:since
```

!Note! This is a long-running process.  You may optionally execute this process as follows:

```bash
nohup /var/apps/cyber-indicators/bin/rake sunspot:reindex:since &
```

!Important! Failure to execute this step may disable search for some indicator types.



