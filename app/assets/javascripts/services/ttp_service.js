app.factory('ttpService',[function(){
  var service = {};

  service.get_data = function() {
    var temp = service.data;
    service.set_data({});
    return temp;
  }

  service.get_data_no_clear = function() {
    return service.data;
  }

  service.set_data = function(data) {
    return service.data = data;
  }

  service.get_params = function() {
    var temp = service.params;
    service.set_params({});
    return temp;
  }

  service.set_params = function(params) {
    return service.params = params;
  }

  service.update_attack_pattern = function(ap) {
    var to_update = _.findIndex(service.data.attack_patterns, function (a){
      return a.stix_id == ap.stix_id;
    })

    if (angular.isDefined(to_update) && to_update > -1){
      service.data.attack_patterns[to_update] = ap;
    }
  }

  service.is_data_set = function() {
    return angular.isDefined(service) && angular.isDefined(service.data) && service.data != null && !_.isEmpty(service.data);
  }
  
  return {
    set_data: service.set_data,
    get_data: service.get_data,
    get_data_no_clear: service.get_data_no_clear,
    set_params: service.set_params,
    get_params: service.get_params,
    update_attack_pattern: service.update_attack_pattern,
    is_data_set: service.is_data_set
  }

}]);
