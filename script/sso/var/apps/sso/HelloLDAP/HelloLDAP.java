import java.io.IOException;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.Map;
import java.util.logging.Logger;
import java.util.Properties;
import java.io.FileInputStream;

import javax.naming.Context;
import javax.security.auth.Subject;
import javax.security.auth.login.LoginException;
import javax.security.auth.login.*;
import javax.naming.NamingEnumeration;
import javax.naming.NamingException;
import javax.naming.directory.DirContext;
import javax.naming.directory.InitialDirContext;

public class HelloLDAP {
  public static void main(final String[] args) throws Exception {
    Properties properties = new Properties();
    try {
      properties.load(new FileInputStream("config.properties"));
    } catch (IOException e) {
      System.out.println("Cannot open config.properties.");
      return;
    }

    final String providerURL = properties.getProperty("config.providerURL","");
    final String securityProtocol = properties.getProperty("config.securityProtocol","ssl");
    final String securityAuthentication = properties.getProperty("config.securityAuthentication","simple");
    final String preauthUsername = properties.getProperty("config.preauthUsername","tomcat.svc");
    final String preauthPassword = properties.getProperty("config.preauthPassword","");

    Hashtable env = new Hashtable();
    env.put(Context.INITIAL_CONTEXT_FACTORY,"com.sun.jndi.ldap.LdapCtxFactory");
    env.put(Context.PROVIDER_URL,providerURL);
    env.put(Context.SECURITY_PROTOCOL,securityProtocol);
    env.put(Context.SECURITY_AUTHENTICATION, securityAuthentication); 

    env.put(Context.SECURITY_PRINCIPAL,preauthUsername);
    env.put(Context.SECURITY_CREDENTIALS,preauthPassword);

    DirContext ctx = new InitialDirContext(env);
  }

}
