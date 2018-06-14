package indicators.cyber.valves;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.net.URISyntaxException;
import java.security.PrivilegedActionException;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.security.auth.login.LoginException;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

//import indicators.cyber.spnego.SpnegoAuthenticator;
//import net.sourceforge.spnego.SpnegoHttpFilter.Constants;
//import indicators.cyber.spnego.SpnegoHttpServletResponse;
import net.sourceforge.spnego.SpnegoAuthenticator;
import net.sourceforge.spnego.SpnegoHttpServletResponse;
import net.sourceforge.spnego.SpnegoPrincipal;

import org.apache.catalina.LifecycleException;
import org.apache.catalina.LifecycleState;
import org.apache.catalina.connector.Request;
import org.apache.catalina.connector.Response;
import org.apache.catalina.valves.ValveBase;
import org.apache.tomcat.util.buf.MessageBytes;
import org.apache.tomcat.util.http.MimeHeaders;
import org.ietf.jgss.GSSException;

public class ActiveDirectory extends ValveBase {
	private static final Map<String, Level> levelMap;
	static {
		Map<String, Level> aLevelMap = new HashMap<String, Level>();
		aLevelMap.put("1", Level.FINEST);
		aLevelMap.put("2", Level.FINER);
		aLevelMap.put("3", Level.FINE);
		aLevelMap.put("4", Level.CONFIG);
		aLevelMap.put("5", Level.INFO);
		aLevelMap.put("6", Level.WARNING);
		aLevelMap.put("7", Level.SEVERE);
		levelMap = Collections.unmodifiableMap(aLevelMap);
	}

	private SpnegoAuthenticator authenticator = null;
	private String krb5Conf = "krb5.conf";
	private String loginConf = "login.conf";
	private String loginModule = "active-directory";
	private String preauthUsername = "";
	private String preauthPassword = "";
	private String loggerLevel = "1";
	private Logger activeDirectoryLogger = Logger.getLogger("log");
	private String allowBasic = "false";
	private String allowUnsecureBasic = "false";
	private String promptNTLM = "false";
	private String allowDelegation = "false";
	private String loginClientModule = "active-directory-client";
	private String allowLocalhost = "false";
	private String bypassIfHeaders = "API_KEY|api_key";
	private String bypassIfLocalRequest = "false";
	private String localAddress = "127.0.0.1";

	public void invoke(org.apache.catalina.connector.Request request,
			Response response) throws IOException, ServletException {
		Level currentLoggerLevel = levelMap.get(this.loggerLevel);
		this.activeDirectoryLogger.log(currentLoggerLevel,
				"[ActiveDirectory Valve] Invoked.");

		final HttpServletRequest httpRequest = (HttpServletRequest) request;
		final SpnegoHttpServletResponse spnegoResponse = new SpnegoHttpServletResponse(
				(HttpServletResponse) response);
		final SpnegoPrincipal principal;

		final HttpSession session = request.getSession();
		final SpnegoPrincipal userPrincipal = (SpnegoPrincipal) session
				.getAttribute("session.userPrincipal");

		if (bypassIfLocalRequest.equals("true") && 
		    request.getRemoteAddr().equals(localAddress) ) {
			activeDirectoryLogger
					.log(currentLoggerLevel,
							"[ActiveDirectory Valve] Local request.  Valve will bypass.");
			getNext().invoke((Request) httpRequest, response);
			return;
		}

		String[] bypassHeaders = bypassIfHeaders.split("\\|");

		for (int i = 0; i < bypassHeaders.length; i++) {
			String header = bypassHeaders[i];
			String headerInRequest = request.getHeader(header);
			if (headerInRequest != null) {
				activeDirectoryLogger.log(currentLoggerLevel,
						"[ActiveDirectory Valve] Header: " + header
								+ " is in request.  Valve will bypass.");
				getNext().invoke((Request) httpRequest, response);
				return;
			}
		}

		if (userPrincipal == null) {
			activeDirectoryLogger
					.log(currentLoggerLevel,
							"[ActiveDirectory Valve] userPrincipal was not in session.");
			try {
				activeDirectoryLogger.log(currentLoggerLevel,
						"[ActiveDirectory Valve] Authenticating user.");
				principal = this.authenticator.authenticate(httpRequest,
						spnegoResponse);
				activeDirectoryLogger.log(currentLoggerLevel,
						"[ActiveDirectory Valve] Authentication set HTTP response status: "
								+ response.getStatus());

			} catch (GSSException e) {
				activeDirectoryLogger
						.log(currentLoggerLevel,
								"[ActiveDirectory Valve] Authentication threw an exception.");
				throw new IOException(e);
			}

			if (principal == null) {
				activeDirectoryLogger.log(currentLoggerLevel,
						"[ActiveDirectory Valve] principal was null.");
				getNext().invoke((Request) httpRequest, response);
				return;
			}

			if (principal.toString() == null) {
				activeDirectoryLogger
						.log(currentLoggerLevel,
								"[ActiveDirectory Valve] principal.toString() was null.");
				getNext().invoke((Request) httpRequest, response);
				return;
			} else {
				activeDirectoryLogger.log(currentLoggerLevel,
						"[ActiveDirectory Valve] principal.toString(): "
								+ principal.toString());
			}

			// context/auth loop not yet complete
			if (spnegoResponse.isStatusSet()) {
				activeDirectoryLogger.log(currentLoggerLevel,
						"[ActiveDirectory Valve] isStatusSet() was true.");
				return;
			}

			session.setAttribute("session.userPrincipal", principal);
		} else {
			activeDirectoryLogger
					.log(currentLoggerLevel,
							"[ActiveDirectory Valve] userPrincipal retrieved from session.");
			principal = userPrincipal;
		}

		activeDirectoryLogger.log(currentLoggerLevel,
				"[ActiveDirectory Valve] Set AUTH_TYPE header to SPNEGO.");
		request.setAuthType("SPNEGO");

		activeDirectoryLogger
				.log(currentLoggerLevel,
						"[ActiveDirectory Valve] Assigned authenticated principal to request.");
		request.setUserPrincipal(principal);

		activeDirectoryLogger.log(currentLoggerLevel,
				"[ActiveDirectory Valve] Set REMOTE_USER header.");
		MimeHeaders mimeHeaders = request.getCoyoteRequest().getMimeHeaders();
		MessageBytes remoteUserHeader = mimeHeaders.addValue("REMOTE_USER");
		remoteUserHeader.setString(principal.toString());

		activeDirectoryLogger.log(currentLoggerLevel,
				"[ActiveDirectory Valve] Set AUTH_MODE to active_directory.");
		MessageBytes authTypeHeader = mimeHeaders.addValue("AUTH_MODE");
		authTypeHeader.setString("active_directory");

		activeDirectoryLogger.log(currentLoggerLevel,
				"[ActiveDirectory Valve] Done. Invoking next request.");
		getNext().invoke((Request) httpRequest, response);
	}

	protected void startInternal() throws LifecycleException {
		setState(LifecycleState.STARTING);
		Level currentLoggerLevel = levelMap.get(this.loggerLevel);

		final Map<String, String> map = new HashMap<String, String>();
		map.put("spnego.allow.localhost", this.allowLocalhost);
		map.put("spnego.allow.basic", this.allowBasic);
		map.put("spnego.allow.unsecure.basic", this.allowUnsecureBasic);
		map.put("spnego.login.client.module", this.loginClientModule);
		map.put("spnego.krb5.conf", this.krb5Conf);
		map.put("spnego.login.conf", this.loginConf);
		map.put("spnego.preauth.username", this.preauthUsername);
		map.put("spnego.preauth.password", this.preauthPassword);
		map.put("spnego.login.server.module", this.loginModule);
		map.put("spnego.prompt.ntlm", this.promptNTLM);
		map.put("spnego.allow.delegation", this.allowDelegation);
		map.put("spnego.logger.level", this.loggerLevel);
		activeDirectoryLogger
				.log(currentLoggerLevel,
						"[ActiveDirectory startInternal] startInternal assignments made.");
		try {
			authenticator = new SpnegoAuthenticator(map);
		} catch (LoginException e) {
			throw new LifecycleException(e);
		} catch (FileNotFoundException e) {
			throw new LifecycleException(e);
		} catch (GSSException e) {
			throw new LifecycleException(e);
		} catch (PrivilegedActionException e) {
			throw new LifecycleException(e);
		} catch (URISyntaxException e) {
			throw new LifecycleException(e);
		}
	}

	public void setBypassIfLocalRequest(String bypassIfLocalRequest) {
		this.bypassIfLocalRequest = bypassIfLocalRequest;
	}
	
	public void setLocalAddress(String localAddress) {
		this.localAddress = localAddress;
	}

	public void setBypassIfHeaders(String bypassIfHeaders) {
		this.bypassIfHeaders = bypassIfHeaders;
	}

	public void setAllowLocalhost(String allowLocalhost) {
		this.allowLocalhost = allowLocalhost;
	}

	public void setLoginClientModule(String loginClientModule) {
		this.loginClientModule = loginClientModule;
	}

	public void setAllowBasic(String allowBasic) {
		this.allowBasic = allowBasic;
	}

	public void setAllowUnsecureBasic(String allowUnsecureBasic) {
		this.allowUnsecureBasic = allowUnsecureBasic;
	}

	public void setAllowDelegation(String allowDelegation) {
		this.allowDelegation = allowDelegation;
	}

	public void setPromptNTLM(String promptNTLM) {
		this.promptNTLM = promptNTLM;
	}

	public void setKrb5Conf(String krb5Conf) {
		this.krb5Conf = krb5Conf;
	}

	public void setLoginConf(String loginConf) {
		this.loginConf = loginConf;
	}

	public void setPreauthUsername(String preauthUsername) {
		this.preauthUsername = preauthUsername;
	}

	public void setPreauthPassword(String preauthPassword) {
		this.preauthPassword = preauthPassword;
	}

	public void setLoginModule(String loginModule) {
		this.loginModule = loginModule;
	}

	public void setLoggerLevel(String loggerLevel) {
		this.loggerLevel = loggerLevel;
	}

}