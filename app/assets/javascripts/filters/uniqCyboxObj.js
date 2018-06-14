app.filter('uniqCyboxObject', function() {
  return function(obs) {
    var filtered = [];
    angular.forEach(obs, function(ob) {

      var existing = _.find(filtered, function(item) {
          if (ob.hasOwnProperty("remote_object_id")){
            return item.remote_object_id == ob.remote_object_id;
          } else if(ob.hasOwnProperty("cybox_object_id")) {
            return item.cybox_object_id == ob.cybox_object_id;
          }
      });
      
      if(angular.isUndefined(existing)) {
        filtered.push(ob);
      }

    });

    return filtered;

  };
});