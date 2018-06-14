angular.module('angularFilters', []).filter('encodeURIComponent', function() {
  return window.encodeURIComponent;
});
