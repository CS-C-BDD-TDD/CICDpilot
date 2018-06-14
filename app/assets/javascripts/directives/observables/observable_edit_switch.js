app.directive('observableEditSwitch', function($compile){
  return {
    scope: {
             type: '@'
           },
    link: function(scope,element) {
      var template;
      if (angular.isUndefined(scope.type) || scope.type=='') {
        template=''
      } else if (scope.type=='DnsQuery') {
        template='<div class="page-header"><h1>Edit DNS Query Observable</h1></div><dns-query-form dns-query="$parent.selected" cancel="$parent.showLinkObservable" saved="$parent.after_dns_query_save" editform="true"></dns-query-form>';
      } else if (scope.type=='DnsRecord') {
        template='<div class="page-header"><h1>Edit DNS Record Observable</h1></div><dns-record-form dns="$parent.selected" cancel="$parent.showLinkObservable" saved="$parent.after_dns_save" editform="true"></dns-record-form>';
      } else if (scope.type=='Domain') {
        template='<div class="page-header"><h1>Edit Domain Observable</h1></div><domain-form domain="$parent.selected" cancel="$parent.showLinkObservable" saved="$parent.after_domain_save" editform="true"></domain-form>';
      } else if (scope.type=='EmailMessage') {
        template='<div class="page-header"><h1>Edit Email Observable</h1></div><email-form email="$parent.selected" cancel="$parent.showLinkObservable" saved="$parent.after_email_save" editform="true"></email-form>';
      } else if (scope.type=='CyboxFile') {
        template='<div class="page-header"><h1>Edit File Observable</h1></div><file-form file="$parent.selected" cancel="$parent.showLinkObservable" saved="$parent.after_file_save" editform="true"></file-form>';
      } else if (scope.type=='HttpSession') {
        template='<div class="page-header"><h1>Edit HTTP Session Observable</h1></div><http-session-form httpsession="$parent.selected" cancel="$parent.showLinkObservable" saved="$parent.after_http_save" editform="true"></http-session-form>';
      } else if (scope.type=='Hostname') {
        template='<div class="page-header"><h1>Edit Hostname Observable</h1></div><hostname-form hostname="$parent.selected" cancel="$parent.showLinkObservable" saved="$parent.after_hostname_save" editform="true"></hostname-form>';
      } else if (scope.type=='Address') {
        template='<div class="page-header"><h1>Edit Address Observable</h1></div><address-form address="$parent.selected" cancel="$parent.showLinkObservable" saved="$parent.after_address_save" editform="true"></address-form>';
      } else if (scope.type=='Link') {
        template='<div class="page-header"><h1>Edit Link Observable</h1></div><link-form link="$parent.selected" cancel="$parent.showLinkObservable" saved="$parent.after_link_save" editform="true"></link-form>';
      } else if (scope.type=='CyboxMutex') {
        template='<div class="page-header"><h1>Edit Mutex Observable</h1></div><mutex-form mutex="$parent.selected" cancel="$parent.showLinkObservable" saved="$parent.after_mutex_save" editform="true"></mutex-form>';
      } else if (scope.type=='NetworkConnection') {
        template='<div class="page-header"><h1>Edit Network Connection Observable</h1></div><network-connection-form networkconnection="$parent.selected" cancel="$parent.showLinkObservable" saved="$parent.after_network_save" editform="true"></network-connection-form>';
      } else if (scope.type=='Port') {
        template='<div class="page-header"><h1>Edit Port Observable</h1></div><port-form port="$parent.selected" cancel="$parent.showLinkObservable" saved="$parent.after_port_save" editform="true"></port-form>';
      } else if (scope.type=='Registry') {
        template='<div class="page-header"><h1>Edit Registry Observable</h1></div><registry-form registry="$parent.selected" cancel="$parent.showLinkObservable" saved="$parent.after_registry_save" editform="true"></registry-form>';
      } else if (scope.type=='SocketAddress') {
        template='<div class="page-header"><h1>Edit Socket Address Observable</h1></div><socket-address-form socket_address="$parent.selected" cancel="$parent.showLinkObservable" saved="$parent.after_socket_address_save" editform="true"></socket-address-form>';
      } else if (scope.type=='Uri') {
        template='<div class="page-header"><h1>Edit Uri Observable</h1></div><uri-form uri="$parent.selected" cancel="$parent.showLinkObservable" saved="$parent.after_uri_save" editform="true"></uri-form>';
      }
      element.html($compile(template)(scope));
    }
  }
});
