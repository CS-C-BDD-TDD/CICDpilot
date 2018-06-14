import java.net.URL;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;

import net.sourceforge.spnego.SpnegoHttpURLConnection;

public class HelloKeytab {

    public static void main(final String[] args) throws Exception {
        Properties properties = new Properties();
        try {
          properties.load(new FileInputStream("config.properties"));
        } catch (IOException e) {
          System.out.println("Cannot open config.properties.");
          return;
        }
        
        final String krb5Conf = properties.getProperty("config.krb5Conf","");
        final String loginConf = properties.getProperty("config.loginConf","");
        final String loginModule = properties.getProperty("config.loginModule","active-directory");
        final String applicationServerURL = properties.getProperty("config.applicationServerURL","");

        System.setProperty("java.security.krb5.conf", krb5Conf);
        System.setProperty("sun.security.krb5.debug", "true");
        System.setProperty("java.security.auth.login.config", loginConf);
          
        SpnegoHttpURLConnection spnego = null;
        
        try {
            spnego = new SpnegoHttpURLConnection(loginModule);
            spnego.connect(new URL(applicationServerURL));
            
            System.out.println("HTTP Status Code: " 
                    + spnego.getResponseCode());
            
            System.out.println("HTTP Status Message: "
                    + spnego.getResponseMessage());

        } finally {
            if (null != spnego) {
                spnego.disconnect();
            }
        }
    }
}
