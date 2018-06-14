app.factory('objectSuggesterService',[function(){
  var service = {};

  service.get_data = function() {
    var temp = service.data;
    service.set_data({});
    return temp;
  }

  service.get_data_no_clear = function() {
    return service.data;
  }

  service.get_path = function(){
    return service.path;
  }

  service.set_path = function(path){
    return service.path = path;
  }

  service.set_data = function(data) {
    return service.data = data;
  }

  service.get_params = function() {
    var temp = service.params;
    service.set_params({});
    return temp;
  }

  service.get_params_no_clear = function() {
    return service.params;
  }

  service.set_params = function(params) {
    if (angular.isDefined(params.path)){
      service.path = params.path;
    }
    return service.params = params;
  }

  service.is_data_set = function() {
    return angular.isDefined(service) && angular.isDefined(service.data) && service.data != null && !_.isEmpty(service.data);
  }

  service.update_portion_marking = function(add){
    service.data[service.params.portion_marking_col] = add.portion_marking;
  }
  
  return {
    set_data: service.set_data,
    get_data: service.get_data,
    get_data_no_clear: service.get_data_no_clear,
    set_params: service.set_params,
    set_path: service.set_path,
    get_path: service.get_path,
    get_params: service.get_params,
    get_params_no_clear: service.get_params_no_clear,
    is_data_set: service.is_data_set,
    update_portion_marking: service.update_portion_marking
  }

}]);