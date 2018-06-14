app.directive('noEnter', function () {
  return {
    require: 'ngModel',
    restrict: 'A',
    link: function (scope, element, attr, ctrl) {
      // This directive stops the propagation of the enter key
      // Which was needed on the package form for Title and Short Description

      element.on('keydown',function(event) {
        var keycode = event.which || event.keyCode;
        if (keycode == 13) { // Key code of enter button
          // Cancel default action
          if (event.preventDefault) { // W3C
            event.preventDefault();
          } else { // IE
            event.returnValue = false;
          }
          // Cancel visible action
          if (event.stopPropagation) { // W3C
            event.stopPropagation();
          } else { // IE
            event.cancelBubble = true;
          }
          // We don't need anything else
          return false;
        };
      });
    }
  };
});
