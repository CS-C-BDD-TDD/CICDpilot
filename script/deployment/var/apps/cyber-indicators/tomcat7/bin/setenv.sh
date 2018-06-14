# Set startup parameters for Tomcat. 

# Catalina startup options required by CIS Benchmarks:
export CATALINA_OPTS="-Dorg.apache.catalina.STRICT_SERVLET_COMPLIANCE=true"
export CATALINA_OPTS="${CATALINA_OPTS} -Dorg.apache.catalina.connector.RECYCLE_FACADES=false"
export CATALINA_OPTS="${CATALINA_OPTS} -Dorg.apache.catalina.connector.CoyoteAdapter.ALLOW_BACKSLASH=false"
export CATALINA_OPTS="${CATALINA_OPTS} -Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=false"
export CATALINA_OPTS="${CATALINA_OPTS} -Dorg.apache.coyote.USE_CUSTOM_STATUS_MSG_IN_HEADER=false"
export CATALINA_OPTS="${CATALINA_OPTS} -Dorg.apache.tomcat.util.http.ServerCookie.FWD_SLASH_IS_SEPARATOR=false"

