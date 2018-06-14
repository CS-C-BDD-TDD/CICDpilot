app.filter('prefixWithPortionMarking',
    function prefixWithPortionMarking($rootScope) {
      return function (text, portionMarking, cachedFieldMarking, defaultMarking) {
        if ($rootScope.setting_value('CLASSIFICATION') == true) {
          // Pass the string through as-is if portion marking and/or the
          // string are not set properly, null, empty, etc.
          if (angular.isUndefined(text) || text == null || text.length === 0) {
            return text;
          }
          // If no portion marking is set but classification is enabled,
          // default to UNCLASSIFIED.
          if (angular.isUndefined(portionMarking) || portionMarking == null ||
              portionMarking.length === 0) {
              if (angular.isUndefined(defaultMarking) || defaultMarking == null ||
                  defaultMarking.length === 0) {
                  portionMarking = 'TS';
              }
              else {
                  portionMarking = defaultMarking;
              }
          }
          if (angular.isDefined(cachedFieldMarking) && cachedFieldMarking != null &&
              cachedFieldMarking.length > 0) {
              portionMarking = cachedFieldMarking;
          }
          // Prefix the text string with the portion marking.
          return "(" + portionMarking + ") " + text;
        } else {
          // Portion marking display is disabled on this systems so pass
          // through the string unchanged.
          return text;
        }
      }
    });
