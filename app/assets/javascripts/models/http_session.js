app.service('HttpSession', ['$filter', function ($filter) {
    return {
        get_value: function (http_session) {
            if (angular.isUndefined(http_session)) {
                return '';
            }
            var value = '';
            if (http_session.user_agent) {
                value += http_session.user_agent;
            }
            else if (http_session.domain_name) {
                value += http_session.domain_name;
            }
            if (value == '') {
                value = http_session.cybox_object_id;
            }
            return $filter('prefixWithPortionMarking')(value,
                http_session.portion_marking);
        }
    };
}]);
