package indicators.cyber.valves;

import java.io.IOException;
import java.util.Collections;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.naming.Context;
import javax.security.auth.Subject;
import javax.security.auth.login.LoginException;
import javax.servlet.ServletException;
import javax.servlet.http.HttpSession;
import javax.security.auth.login.*;

import org.apache.catalina.LifecycleException;
import org.apache.catalina.LifecycleState;
import org.apache.catalina.connector.Response;
import org.apache.catalina.valves.ValveBase;
import org.apache.tomcat.util.buf.MessageBytes;
import org.apache.tomcat.util.http.MimeHeaders;

import indicators.cyber.jndi.Action;

public class LDAP extends ValveBase {	
	private String krb5Conf = "krb5.conf";
	private String loginConf = "login.conf";
	private String loginModule = "active-directory";
	private String providerURL = "";
	private String searchBase = "";
	private String securityAuthentication = "GSSAPI";
	private String securityProtocol = "";
	
	private Action action;
	private Map<String, String> map;
	private Hashtable<String, String> context;
	private Logger ldapLogger = Logger.getLogger("log");	
	private String loggerLevel = "1";
	private String bypassIfHeaders = "API_KEY|api_key";

    private static final Map<String, Level> levelMap;
	static {
		Map<String, Level> aLevelMap = new HashMap<String, Level>();
		aLevelMap.put("1",Level.FINEST);
		aLevelMap.put("2",Level.FINER);
		aLevelMap.put("3",Level.FINE);
		aLevelMap.put("4",Level.CONFIG);
		aLevelMap.put("5",Level.INFO);
		aLevelMap.put("6",Level.WARNING);
		aLevelMap.put("7",Level.SEVERE);
		levelMap = Collections.unmodifiableMap(aLevelMap);
	}
	
	@SuppressWarnings("unchecked")
	public void invoke(org.apache.catalina.connector.Request request,
			Response response) throws IOException, ServletException {
		String guid = "";
		Level currentLoggerLevel = levelMap.get(this.loggerLevel);

		this.ldapLogger.log(currentLoggerLevel,"[LDAP Valve] Invoked.");

		MimeHeaders mimeHeaders = request.getCoyoteRequest().getMimeHeaders();
		MessageBytes remoteUserHeader = mimeHeaders.getValue("REMOTE_USER");
		String remoteUser = remoteUserHeader.getString();

		String[] bypassHeaders = bypassIfHeaders.split("\\|");
		
        for (int i = 0;i < bypassHeaders.length;i++){
           String header = bypassHeaders[i];
           String headerInRequest = request.getHeader(header);
           if (headerInRequest != null) {
   			ldapLogger
   			.log(currentLoggerLevel,"[LDAP Valve] Header: "+header+" is in request.  Valve will bypass.");
			getNext().invoke(request, response);
			return;
           }
        }
		
		this.ldapLogger.log(currentLoggerLevel,"[LDAP Valve] REMOTE_USER: "+remoteUser);
		
		final HttpSession session = request.getSession();		
		final String sessionUserGUID = (String) session.getAttribute("session.userGUID");
		
		this.ldapLogger.log(currentLoggerLevel,"[LDAP Valve] REMOTE_USER_GUID: "+sessionUserGUID);	
		
		if (sessionUserGUID == null) {
			this.ldapLogger.log(currentLoggerLevel,"[LDAP Valve] userGUID was not in session.");
			LoginContext lc = null;
			try {
				lc = new LoginContext(this.loginModule);
				lc.login();
			} catch (LoginException le) {
				this.ldapLogger.log(currentLoggerLevel,"[LDAP Valve] Login Context Failure!");
			}

			this.action = new Action(this.context, this.searchBase, remoteUser);
			guid = Subject.doAs(lc.getSubject(), this.action);
			session.setAttribute("session.userGUID", guid);			
		} else {
			this.ldapLogger.log(currentLoggerLevel,"[LDAP Valve] userGUID retrieved from session.");			
			guid = sessionUserGUID;
		}
        
		MessageBytes remoteUserGuidHeader = mimeHeaders.addValue("REMOTE_USER_GUID");    	
		remoteUserGuidHeader.setString(guid);
		this.ldapLogger.log(currentLoggerLevel,"[LDAP Valve] Done. Invoking next valve.");
		getNext().invoke(request, response);
	}

	
	protected void startInternal() throws LifecycleException {
		Level currentLoggerLevel = levelMap.get(this.loggerLevel);

		setState(LifecycleState.STARTING);
		this.map = new HashMap<String, String>();
		this.context = new Hashtable<String,String>(11);
		map.put("ldap.loginModule", this.loginModule);
		map.put("ldap.providerURL",this.providerURL);
	
        System.setProperty("java.security.krb5.conf", this.krb5Conf);
        System.setProperty("java.security.auth.login.config",this.loginConf);
        
    	this.context.put(Context.INITIAL_CONTEXT_FACTORY, 
    	    "com.sun.jndi.ldap.LdapCtxFactory");
    	this.context.put(Context.PROVIDER_URL, this.providerURL);
        this.context.put(Context.SECURITY_AUTHENTICATION, this.securityAuthentication); 
        this.context.put("java.naming.ldap.attributes.binary", "objectGUID");
        this.context.put(Context.SECURITY_PROTOCOL, this.securityProtocol);
        this.context.put("ldap.logger.level",this.loggerLevel);
		this.ldapLogger.log(currentLoggerLevel,"[LDAP Valve startInternal] Assignments made.");			

  	}
	
	public void setSecurityProtocol(String securityProtocol) {
		this.securityProtocol = securityProtocol;
	}
	
	public void setSecurityAuthentication(String securityAuthentication) {
		this.securityAuthentication = securityAuthentication;
	}
	
	public void setKrb5Conf(String krb5Conf) {
		this.krb5Conf = krb5Conf;
	}
	
	public void setLoginConf(String loginConf) {
		this.loginConf = loginConf;
	}
		
	public void setLoginModule(String loginModule) {
		this.loginModule = loginModule;
	}	

	public void setProviderURL(String providerURL) {
		this.providerURL = providerURL;
	}	
	
	public void setSearchBase(String searchBase) {
	    this.searchBase = searchBase;
		
	}
	
	public void setLoggerLevel(String loggerLevel) {
		this.loggerLevel = loggerLevel;
	}	

}
