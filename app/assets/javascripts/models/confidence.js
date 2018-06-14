app.service('Confidence', function() {
  return {
     values: ["Unknown","Low","Medium","High"],
     confidence: function(object){
         if (angular.isUndefined(object)){return ''}
         else if (angular.isDefined(object.official_confidence)){return object.official_confidence.value}
         else if (angular.isUndefined(object.confidences) || object.confidences == null){return 'UNKNOWN'}
         else if (angular.isUndefined(object.confidences[0])) {
             return 'UNKNOWN'
         }
         else if (angular.isUndefined(object.confidences[0].value) || object.confidences[0].value == null) {
             return 'UNKNOWN'
         }
         else if (object.confidences[0].is_official == false) {
             return 'UNKNOWN'
         }
         else {
             return object.confidences[0].value
         }
     }
  };
});