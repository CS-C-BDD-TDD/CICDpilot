app.factory('bulkActionsService',[function(){
  var service = {}
  service.get = function() {
    var temp = service.data;
    service.set([]);
    return temp;
  }

  service.set = function(data) {
    return service.data = data;
  }
  
  return {
    set: service.set,
    get: service.get
  }

}]);