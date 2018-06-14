app.factory('suggestionService',[function(){
  service = {}
  service.reset = function() {
    return service = {}
  }
  service.publishCurrentSuggestion = function(suggestion) {
    service.current_suggestion = suggestion;
  }
  service.publishSuggestions = function(suggestions) {
    service.suggestions = suggestions;
  }

  service.publishTagsPromise = function(tagsPromise) {
    service.tagsPromise = tagsPromise;
  }

  service.newSuggestions = function() {  
    return _.filter(service.suggestions,function(suggestion) {
      return suggestion.name == service.current_suggestion;
    });

  }
  
  return service;
}]);