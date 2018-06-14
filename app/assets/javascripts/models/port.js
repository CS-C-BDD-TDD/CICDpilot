app.service('Port', ['$filter', function ($filter) {
    return {
        get_value: function (port) {
            if (angular.isUndefined(port)) {
                return '';
            }
            var value = '';
            if (port.port) {
                value += port.port;
            }
            if (port.layer4_protocol) {
                if (value == '') {
                   value += port.layer4_protocol;
                }else {
                    value += "/" + port.layer4_protocol;
                }
            }
            if (value == '') {
                value = port.cybox_object_id;
            }
            return $filter('prefixWithPortionMarking')(value,
                port.portion_marking);
        }
    };
}]);
