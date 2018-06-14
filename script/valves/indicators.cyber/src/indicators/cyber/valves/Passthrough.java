package indicators.cyber.valves;

import java.io.*;
import java.util.logging.Logger;

import javax.servlet.*;

import org.apache.catalina.connector.*;
import org.apache.catalina.valves.ValveBase;
import org.apache.tomcat.util.http.MimeHeaders;

public class Passthrough extends ValveBase {
  private Logger passthroughLogger = Logger.getLogger("log");

public void invoke(org.apache.catalina.connector.Request request,Response response) throws IOException,
		             										   ServletException 
{
  MimeHeaders mimeHeaders = request.getCoyoteRequest().getMimeHeaders();
  String httpRemoteUser = mimeHeaders.getHeader("HTTP_REMOTE_USER");
  String remoteUser = mimeHeaders.getHeader("REMOTE_USER");  
  this.passthroughLogger.info("[Passthrough] HTTP_REMOTE_USER: "+httpRemoteUser);
  this.passthroughLogger.info("[Passthrough] REMOTE_USER: "+remoteUser);  
  getNext().invoke(request,response);
}

}
