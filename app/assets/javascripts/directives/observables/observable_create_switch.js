app.directive('observableCreateSwitch', function($compile){
  return {
    scope: {
             type: '@'
           },
    link: function(scope,element) {
      var template;
      if (angular.isUndefined(scope.type) || scope.type=='') {
        template=''
      } else if (scope.type=='DnsQuery') {
        template='<dns-query-creator dns-queries="$parent.$parent.dnsQueries" observables="$parent.$parent.observables" link_an_observable="$parent.linkAnObservable" link_observable_view="$parent.$parent.link_observable_view"></dns-query-creator>';
      } else if (scope.type=='DnsRecord') {
        template='<dns-record-creator dns_records="$parent.$parent.dnsRecords" observables="$parent.$parent.observables" link_an_observable="$parent.linkAnObservable" link_observable_view="$parent.$parent.link_observable_view"></dns-record-creator>';
      } else if (scope.type=='Domain') {
        template='<domain-creator domains="$parent.$parent.domains" observables="$parent.$parent.observables" link_an_observable="$parent.linkAnObservable" link_observable_view="$parent.$parent.link_observable_view"></domain-creator>';
      } else if (scope.type=='EmailMessage') {
        template='<email-creator emails="$parent.$parent.emails" observables="$parent.$parent.observables" link_an_observable="$parent.linkAnObservable" link_observable_view="$parent.$parent.link_observable_view"></email-creator>';
      } else if (scope.type=='CyboxFile') {
        template='<file-creator files="$parent.$parent.files" observables="$parent.$parent.observables" link_an_observable="$parent.linkAnObservable" link_observable_view="$parent.$parent.link_observable_view"></file-creator>';
      } else if (scope.type=='HttpSession') {
        template='<http-session-creator http_sessions="$parent.$parent.httpSessions" observables="$parent.$parent.observables" link_an_observable="$parent.linkAnObservable" link_observable_view="$parent.$parent.link_observable_view"></http-session-creator>';
      } else if (scope.type=='Hostname') {
        template='<hostname-creator hostnames="$parent.$parent.hostnames" observables="$parent.$parent.observables" link_an_observable="$parent.linkAnObservable" link_observable_view="$parent.$parent.link_observable_view"></hostname-creator>';
      } else if (scope.type=='Address') {
        template='<address-creator addresses="$parent.$parent.addresses" observables="$parent.$parent.observables" link_an_observable="$parent.linkAnObservable" link_observable_view="$parent.$parent.link_observable_view"></address-creator>';
      } else if (scope.type=='Link') {
        template='<link-creator links="$parent.$parent.links" observables="$parent.$parent.observables" link_an_observable="$parent.linkAnObservable" link_observable_view="$parent.$parent.link_observable_view"></link-creator>';
      } else if (scope.type=='CyboxMutex') {
        template='<mutex-creator mutexes="$parent.$parent.mutexes" observables="$parent.$parent.observables" link_an_observable="$parent.linkAnObservable" link_observable_view="$parent.$parent.link_observable_view"></mutex-creator>';
      } else if (scope.type=='NetworkConnection') {
        template='<network-connection-creator network_connections="$parent.$parent.network_connections" observables="$parent.$parent.observables" link_an_observable="$parent.linkAnObservable" link_observable_view="$parent.$parent.link_observable_view"></network-connection-creator>';
      } else if (scope.type=='Port') {
        template='<port-creator ports="$parent.$parent.ports" observables="$parent.$parent.observables" link_an_observable="$parent.linkAnObservable" link_observable_view="$parent.$parent.link_observable_view"></port-creator>';
      } else if (scope.type=='Registry') {
        template='<registry-creator registries="$parent.$parent.registries" observables="$parent.$parent.observables" link_an_observable="$parent.linkAnObservable" link_observable_view="$parent.$parent.link_observable_view"></registry-creator>';
      } else if (scope.type=='SocketAddress') {
        template='<socket-address-creator socket_addresses="$parent.$parent.socket_addresses" observables="$parent.$parent.observables" link_an_observable="$parent.linkAnObservable" link_observable_view="$parent.$parent.link_observable_view"></socket-address-creator>';
      } else if (scope.type=='Uri') {
        template='<uri-creator uris="$parent.$parent.uris" observables="$parent.$parent.observables" link_an_observable="$parent.linkAnObservable" link_observable_view="$parent.$parent.link_observable_view"></uri-creator>';
      }
      element.html($compile(template)(scope));
    }
  }
});
