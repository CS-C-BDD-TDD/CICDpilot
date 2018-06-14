package indicators.cyber.jndi;

import java.util.Collections;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.naming.NamingEnumeration;
import javax.naming.NamingException;
import javax.naming.directory.DirContext;
import javax.naming.directory.InitialDirContext;
import javax.naming.directory.SearchControls;
import javax.naming.directory.SearchResult;

@SuppressWarnings("rawtypes")
public class Action implements java.security.PrivilegedAction {
    private Hashtable<String,String> context;
    private static String searchBase = "";
    private static String remoteUser = "";
	private static Logger jndiLogger = Logger.getLogger("log");	
	private static String loggerLevel = "1";
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
    
    
    public Action(Hashtable<String,String> context) {
      this.context = (context);
    }
    
    public Action(Hashtable<String,String> context,String searchBase,String remoteUser) {
        this.context = (context);
        setLoggerLevel(this.context.get("ldap.logger.level"));
        setSearchBase(searchBase);
        setRemoteUser(remoteUser);
      }    

    public Object run() {
    Level level = getLevel(loggerLevel);
    jndiLogger.log(level,"[JNDILogger] Performing JNDI Operation.");	
	String guid = performJndiOperation(context);
    jndiLogger.log(level,"[JNDILogger] Performed JNDI Operation: " + guid);	
	
	return guid;
    }

    private static String performJndiOperation(Hashtable<String,String> context) {
        Level level = getLevel(loggerLevel);

	try {
	    /* Create initial context */
		jndiLogger.log(level,"[JNDILogger] Creating InitialDirContext.");
	    DirContext ctx = new InitialDirContext(context);
		jndiLogger.log(level,"[JNDILogger] Created InitialDirContext.");
	    
	    jndiLogger.log(level,"[JNDILogger] remoteUser: "+remoteUser);
	    jndiLogger.log(level,"[JNDILogger] searchBase: "+searchBase);
		jndiLogger.log(level,"[JNDILogger] Getting GUID.");
        String guid = getGUID(ctx,searchBase,remoteUser);
		jndiLogger.log(level,"[JNDILogger] Got GUID.");
		jndiLogger.log(level,"[JNDILogger] guid: "+guid);
        
	    ctx.close();
	    return guid;
	} catch (NamingException e) {
		jndiLogger.log(level,"[JNDILogger] Cannot execute LDAP query.  Increase logging to fine or finest to see more.");
		return "";
	}
    }
    
    static void setSearchBase(String sb) {
    	searchBase = sb;
    }
    
    static void setRemoteUser(String ru) {
    	remoteUser = ru;
    }
    
    static void setLoggerLevel(String ll) {
    	loggerLevel = ll;
    }
    
    static Level getLevel(String level) {
    	return levelMap.get(level);
    }
    
    static String AddLeadingZero(int k) {
        return (k<0xF)?"0" + Integer.toHexString(k):Integer.toHexString(k);
    }    
    
    static String getGUID(DirContext ctx, String ldapSearchBase, String accountName) throws NamingException {
        Level level = getLevel(loggerLevel);

        String strGUID = "";

	    jndiLogger.log(level,"[JNDILogger] Finding account by name.");
        String searchFilter = "(&(objectClass=user)(userPrincipalName=" + accountName + "))";
        jndiLogger.log(level,"[JNDILogger] searchFilter: " + searchFilter);

        SearchControls searchControls = new SearchControls();
        searchControls.setSearchScope(SearchControls.SUBTREE_SCOPE);

	    jndiLogger.log(level,"[JNDILogger] Executing search.");
        NamingEnumeration<SearchResult> results = ctx.search(ldapSearchBase, searchFilter, searchControls);
	    jndiLogger.log(level,"[JNDILogger] Search did execute.");

        
        SearchResult searchResult = null;
        if(results.hasMoreElements()) {
            jndiLogger.log(level,"[JNDILogger] hasMoreElements(): results have elements.");
        	
            searchResult = (SearchResult) results.nextElement();
    	    jndiLogger.log(level,"[JNDILogger] Getting objectGUID attribute from search result.");
            byte[] objectGUID = (byte[]) searchResult.getAttributes().get("objectGUID").get();
    	    jndiLogger.log(level,"[JNDILogger] Got objectGUID attribute.");

    	    jndiLogger.log(level,"[JNDILogger] Converting objectGUID to string");

            String byteGUID = "";
            //Convert the GUID into string using the byte format
            for (int c=0;c<objectGUID.length;c++) {
              byteGUID = byteGUID + "\\" + AddLeadingZero((int)objectGUID[c] & 0xFF);
            }

            //convert the GUID into string format
            strGUID = "{";
            strGUID = strGUID + AddLeadingZero((int)objectGUID[3] & 0xFF);
            strGUID = strGUID + AddLeadingZero((int)objectGUID[2] & 0xFF);
            strGUID = strGUID + AddLeadingZero((int)objectGUID[1] & 0xFF); 
            strGUID = strGUID + AddLeadingZero((int)objectGUID[0] & 0xFF);
            strGUID = strGUID + "-";
            strGUID = strGUID + AddLeadingZero((int)objectGUID[5] & 0xFF);
            strGUID = strGUID + AddLeadingZero((int)objectGUID[4] & 0xFF);
            strGUID = strGUID + "-";
            strGUID = strGUID + AddLeadingZero((int)objectGUID[7] & 0xFF);
            strGUID = strGUID + AddLeadingZero((int)objectGUID[6] & 0xFF);
            strGUID = strGUID + "-";
            strGUID = strGUID + AddLeadingZero((int)objectGUID[8] & 0xFF);
            strGUID = strGUID + AddLeadingZero((int)objectGUID[9] & 0xFF);
            strGUID = strGUID + "-";
            strGUID = strGUID + AddLeadingZero((int)objectGUID[10] & 0xFF);
            strGUID = strGUID + AddLeadingZero((int)objectGUID[11] & 0xFF);
            strGUID = strGUID + AddLeadingZero((int)objectGUID[12] & 0xFF);
            strGUID = strGUID + AddLeadingZero((int)objectGUID[13] & 0xFF);
            strGUID = strGUID + AddLeadingZero((int)objectGUID[14] & 0xFF);
            strGUID = strGUID + AddLeadingZero((int)objectGUID[15] & 0xFF);
            strGUID = strGUID + "}";
    	    jndiLogger.log(level,"[JNDILogger] Converted objectGUID to string.");
            jndiLogger.log(level,"[JNDILogger] GUID (String format): " + strGUID);
            jndiLogger.log(level,"[JNDILogger] GUID (Byte format): " + byteGUID);
            jndiLogger.log(level,"[JNDILogger] result: "+searchResult);
            //make sure there is not another item available, there should be only 1 match
            if(results.hasMoreElements()) {
            	jndiLogger.log(level,"[JNDILogger] Matched multiple users for the accountName: " + accountName);
            	jndiLogger.log(level,"[JNDILogger] Cannot determine which acount is authoritative.  Exiting.");            	
                return "";
            }
        }
        
	    jndiLogger.log(level,"[JNDILogger] Found GUID.  Return.");
        return strGUID;
      }
    
}




  
