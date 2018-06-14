app.directive('onlyHex', function () {
  return {
    require: 'ngModel',
    restrict: 'A',
    link: function (scope, element, attr, ctrl) {
      function inputValue(val) {
        if (val) {
          var digits = val.replace(/[^0-9a-fA-F]/g, '');

          if (digits !== val) {
            ctrl.$setViewValue(digits);
            ctrl.$render();
          }
          return digits;
        }
        return undefined;
      }
      ctrl.$parsers.push(inputValue);
    }
  };
});
