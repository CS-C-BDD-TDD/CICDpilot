# Enabling LDAPS

On domain controller:

*Generate and install certificate in MS windows AD.*

*Reboot*

*Verify that LDAPS is accessible over port 636*

On application server:

*Trust certificate*

(echo | openssl s_client -showcerts -connect activedirectory.unobtanium.us-cert.gov:636) > ldaps.cert
$JAVA_HOME/bin/keytool -importcert -alias ldaps -file ldaps.cert -keystore /usr/share/tomcat7/keystore/cacerts

*Verify that you can connect to LDAPS*

java HelloLDAPS

*Enable LDAPs Valve*

### server.xml
                 <Valve className="indicators.cyber.valves.LDAP"
                         krb5Conf="/usr/share/tomcat7/conf/krb5.conf"
                         loginConf="/usr/share/tomcat7/conf/login.conf"
                         loginModule="active-directory"
                         providerURL="ldaps://activedirectory.unobtanium.us-cert.gov:636"
                         searchBase="dc=unobtanium,dc=us-cert,dc=gov"
                         securityProtocol="ssl"
                         />
OR
                 <Valve className="indicators.cyber.valves.LDAP"
                         krb5Conf="/usr/share/tomcat7/conf/krb5.conf"
                         loginConf="/usr/share/tomcat7/conf/login.conf"
                         loginModule="active-directory"
                         providerURL="ldaps://activedirectory.unobtanium.us-cert.gov:636"
                         searchBase="dc=unobtanium,dc=us-cert,dc=gov"
                         securityProtocol="ssl"
                         loggerLevel="5"
                         />


*Verify Remote GUID is inserted*

View the catalina.out log.  While or after an AD login.  You should see information populated in this log indicating that the Remote GUID is being set on AD login. 