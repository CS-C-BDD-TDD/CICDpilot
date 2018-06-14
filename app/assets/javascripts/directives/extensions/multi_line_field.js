app.directive('multiLineField',function(){
  return {
    restrict: 'E',
    template: '<span class="preformatted; word-wrap: break-word;">{{field | decodeHtmlEntities | prefixWithPortionMarking: portionmarking:cachemarking}}</span>',
    scope: {
      field: '=',
      portionmarking: '=?',
      cachemarking: '=?'
    }
  };
});

// This filter is used within the multiLineField directive and should not be used anywhere else

app.filter('decodeHtmlEntities',function(){
  return function(str) {
    str = _.unescape(str);
    re = /(&#x([0-9a-fA-F][0-9a-fA-F]);)/;
    while (re.test(str)) {
      str = str.replace(RegExp.$1,String.fromCharCode(parseInt(RegExp.$2,16)));
    }
    re = /(&#(\d{1,3});)/;
    while (re.test(str)) {
      str = str.replace(RegExp.$1,String.fromCharCode(RegExp.$2));
    }
    return str;
  }
});
