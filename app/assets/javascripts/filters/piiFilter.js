app.filter("piiFilter", function($filter,$rootScope) {
  return function(data,type) {
    if (!data) return data;

    // Right now, Email Message is the only oobservable
    // type that has PII differences
    if (type.indexOf('Email Message')>=0) {
      var strings = data.split('\n\n');

      if ($rootScope.can('view_pii_fields')) {
        data=strings[0];
      } else {
        data=strings[1];
      }
    }

    return data;
  };
});
