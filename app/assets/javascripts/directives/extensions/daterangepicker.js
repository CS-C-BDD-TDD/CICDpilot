app.directive('dateRangePicker', ['$compile','$timeout', '$parse', function($compile, $timeout, $parse) {
  return {
    restrict: 'A',
    scope: {
      opts: '=options',
    },
    link: function($scope, element, attrs) {
      var update_opts = function(opts) {
        // Set all default options here
        opts = {
                 opens: 'center',
                 timePickerIncrement: 1,
                 timePicker12Hour: false,
                 timePickerSeconds: true
               }

        // If there are any changes, read them here and then apply to opts
        change_opts = $parse(attrs.options)($scope.$parent, {});

        if (angular.isDefined(change_opts)) {
          if (angular.isDefined(change_opts.timePicker) && change_opts.timePicker==true) {
            opts['format']='MM/DD/YYYY HH:mm:ss';
          } else {
            opts['format']='MM/DD/YYYY';
          }

          if (angular.isDefined(change_opts.defaultRanges) && change_opts.defaultRanges==true) {
            opts['ranges'] = {
                               'Yesterday': [moment().subtract(1, 'days'), moment().subtract(1, 'days')],
                               'Today': [moment(), moment()],
                               'Last 7 Days': [moment().subtract(6, 'days'), moment()],
                               'Last 30 Days': [moment().subtract(29, 'days'), moment()]
                             };
            delete(change_opts.defaultRanges);
          } else if (angular.isDefined(change_opts.lastWeekRanges) && change_opts.lastWeekRanges==true) {
            opts['ranges'] = {
                               //set the range to this saturday -14 to this Friday - 7
                               'Most Recent Week': [moment().startOf('week').subtract(8, 'days'), moment().startOf('week').subtract(2, 'days')]
                             };
            delete(change_opts.lastWeekRanges);
          }

          Object.keys(change_opts).forEach(function(key) {
            opts[key]=change_opts[key];
          });
        }
        return(opts);
      }

      var customOpts, el, opts, _formatted, _getPicker, _init, _validateMax, _validateMin;
      el = $(element);
      // Create a unique ID for this element
      el.uniqueId();

      $scope.$watch("opts",function(newval,oldval) {
        if (angular.isDefined(newval) && angular.isDefined(oldval) && newval != oldval) {
          newval = update_opts(newval);
          el.daterangepicker(newval);
          el.on('apply.daterangepicker', function(ev, picker) {
            var picker_func='dateRangePicker'
            if (angular.isDefined(attrs.picker)) {
              picker_func=attrs.picker;
            }
            $scope.$parent[picker_func](picker);
          });
        }
      });

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

      opts = update_opts(opts);

      var output = 'date_picker_object';
      if (angular.isDefined(attrs.output)) {
        output = attrs.output;
      }

      $scope.$parent[output] = {
                                 startDate: null,
                                 endDate: null,
                                 getStartDate: function() { return ''; },
                                 getEndDate: function() { return ''; }
                               };

      var label="Select Date Range";
      if (angular.isDefined(opts.singleDatePicker) && opts.singleDatePicker) {
        label="Select Date";
      }
      if (el.val == '' || el.val == null) {
          el.val(label);
      }
      el.daterangepicker(opts);
      el.on('apply.daterangepicker', function(ev, picker) {
        var picker_func='dateRangePicker'
        if (angular.isDefined(attrs.picker)) {
          picker_func=attrs.picker;
        }
        $scope.$parent[picker_func](picker);
      });
    }
  };
}]);
