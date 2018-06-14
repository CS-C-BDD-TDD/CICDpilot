package indicators.cyber.valves;

import java.io.*;
import java.util.logging.Logger;
import javax.servlet.*;
import org.apache.tomcat.util.http.MimeHeaders;
import org.apache.catalina.connector.*;
import org.apache.catalina.valves.ValveBase;

public class BlackList extends ValveBase {
	private Logger blackListLogger = Logger.getLogger("log");
    private String disallowedHeaders;
	public void invoke(org.apache.catalina.connector.Request request,
			Response response) throws IOException, ServletException {
		blackListLogger.fine("[BlackList] Invoked.");		
		MimeHeaders mimeHeaders = request.getCoyoteRequest().getMimeHeaders();
		String[] blackListHeaders = disallowedHeaders.split("\\|");
		
        String blackListHeaderValue;
        for (int i = 0;i < blackListHeaders.length;i++){
          String mimeHeader = blackListHeaders[i];
          blackListHeaderValue = mimeHeaders.getHeader(mimeHeader);
          if (blackListHeaderValue != null) {
        	  blackListLogger.info("[BlackList] Header: "+mimeHeader+" was set to: "+blackListHeaderValue+".  Resetting.");
        	  mimeHeaders.removeHeader(mimeHeader);
          }
        }
		getNext().invoke(request, response);
	}
	
	public void setDisallowedHeaders(String disallowedHeaders) {
		this.disallowedHeaders = disallowedHeaders;
	}

}
