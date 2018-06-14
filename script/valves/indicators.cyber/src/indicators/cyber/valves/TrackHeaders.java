package indicators.cyber.valves;

import java.io.IOException;
import java.util.logging.Logger;

import javax.servlet.ServletException;

import org.apache.catalina.connector.Response;
import org.apache.tomcat.util.http.MimeHeaders;
import org.apache.catalina.valves.ValveBase;

public class TrackHeaders extends ValveBase {
	  private Logger trackHeadersLogger = Logger.getLogger("log");
	  private String trackHeaders;
	  
	  
	public void invoke(org.apache.catalina.connector.Request request,Response response) throws IOException,
			             										   ServletException 
	{
	  MimeHeaders mimeHeaders = request.getCoyoteRequest().getMimeHeaders();
	  
	  String[] trackedHeaders = trackHeaders.split("\\|");
		
	  String trackedHeaderValue;
	  for (int i = 0;i < trackedHeaders.length;i++){
	    String mimeHeader = trackedHeaders[i];
	    trackedHeaderValue = mimeHeaders.getHeader(mimeHeader);
	    if (trackedHeaderValue != null) {
	  	  trackHeadersLogger.info("[TrackHeaders] Header: "+mimeHeader+" was set to: "+trackedHeaderValue+".");
	  	  mimeHeaders.removeHeader(mimeHeader);
	    }
	  }  
	  
	  getNext().invoke(request,response);
	}


	public void setTrackHeaders(String trackHeaders) {
		this.trackHeaders = trackHeaders;
	}	
	
}
