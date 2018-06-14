app.directive('observableLinkSwitch', function($compile){
  return {
    scope: {
             type: '@'
           },
    link: function(scope,element) {
      scope.$watch('type', function() {
        var template;
        if (angular.isUndefined(scope.type) || scope.type=='') {
          template=''
        } else if (scope.type=='DnsQuery') {
          template='<dns-query-selector dns-queries="$parent.dnsQueries" observable_to_be_linked="$parent.observableToBeLinked" link_observable_view="$parent.link_observable_view"></dns-query-selector>';
        } else if (scope.type=='DnsRecord') {
          template='<dns-record-selector dns_records="$parent.dnsRecords" observable_to_be_linked="$parent.observableToBeLinked" link_observable_view="$parent.link_observable_view"></dns-record-selector>';
        } else if (scope.type=='Domain') {
          template='<domain-selector domains="$parent.domains" observable_to_be_linked="$parent.observableToBeLinked" link_observable_view="$parent.link_observable_view"></domain-selector>';
        } else if (scope.type=='EmailMessage') {
          template='<email-selector emails="$parent.emails" observable_to_be_linked="$parent.observableToBeLinked" link_observable_view="$parent.link_observable_view"></email-selector>';
        } else if (scope.type=='CyboxFile') {
          template='<file-selector files="$parent.files" observable_to_be_linked="$parent.observableToBeLinked" link_observable_view="$parent.link_observable_view"></file-selector>';
        } else if (scope.type=='HttpSession') {
          template='<http-session-selector http_sessions="$parent.httpSessions" observable_to_be_linked="$parent.observableToBeLinked" link_observable_view="$parent.link_observable_view"></http-session-selector>';
        } else if (scope.type=='Hostname') {
          template='<hostname-selector hostnames="$parent.hostnames" observable_to_be_linked="$parent.observableToBeLinked" link_observable_view="$parent.link_observable_view"></hostname-selector>';
        } else if (scope.type=='Address') {
          template='<address-selector addresses="$parent.addresses" observable_to_be_linked="$parent.observableToBeLinked" link_observable_view="$parent.link_observable_view"></address-selector>';
        } else if (scope.type=='Link') {
          template='<link-selector links="$parent.links" observable_to_be_linked="$parent.observableToBeLinked" link_observable_view="$parent.link_observable_view"></link-selector>';
        } else if (scope.type=='CyboxMutex') {
          template='<mutex-selector mutexes="$parent.mutexes" observable_to_be_linked="$parent.observableToBeLinked" link_observable_view="$parent.link_observable_view"></mutex-selector>';
        } else if (scope.type=='NetworkConnection') {
          template='<network-connection-selector network_connections="$parent.network_connections" observable_to_be_linked="$parent.observableToBeLinked" link_observable_view="$parent.link_observable_view"></network-connection-selector>';
        } else if (scope.type=='Port') {
          template='<port-selector ports="$parent.ports" observable_to_be_linked="$parent.observableToBeLinked" link_observable_view="$parent.link_observable_view"></port-selector>';
        } else if (scope.type=='Registry') {
          template='<registry-selector registries="$parent.registries" observable_to_be_linked="$parent.observableToBeLinked" link_observable_view="$parent.link_observable_view"></registry-selector>';
        } else if (scope.type=='SocketAddress') {
          template='<socket-address-selector socket_addresses="$parent.socket_addresses" observable_to_be_linked="$parent.observableToBeLinked" link_observable_view="$parent.link_observable_view"></socket-address-selector>';
        } else if (scope.type=='Uri') {
          template='<uri-selector uris="$parent.uris" observable_to_be_linked="$parent.observableToBeLinked" link_observable_view="$parent.link_observable_view"></uri-selector>';
        }
        element.html($compile(template)(scope));
      });
    }
  }
});
