app.service('File', ['Restangular', '$filter', function (Restangular, $filter) {
    var fetch_markings_object_from_scope=function(scope) {
        var object = _.find(Object.getOwnPropertyNames(scope),function(name) {
            return ((scope[name] instanceof Object) && Object.getOwnPropertyNames(scope[name]).includes('stix_markings_attributes'));
        });
        if (angular.isDefined(object) && object != null) {
            return scope[object]
        }
        else {
            return fetch_markings_object_from_scope(scope.$parent);
        }
    };
    return {
        size_conditions: ["Equals",
            "GreaterThan",
            "GreaterThanOrEqual",
            "LessThan",
            "LessThanOrEqual"],
        get_value: function (file) {
            var value;
            if (angular.isDefined(file.file_name) && file.file_name != null && file.file_name.length) {
                value = file.file_name;
            }
            else if (angular.isDefined(file.md5) && file.md5 != null && file.md5.length) {
                value = file.md5;
            }
            else if (angular.isDefined(file.sha1) && file.sha1 != null && file.sha1.length) {
                value = $filter('truncateWithEllipsis')(file.sha1, 15);
            }
            else if (angular.isDefined(file.sha256) && file.sha256 != null && file.sha256.length) {
                value = $filter('truncateWithEllipsis')(file.sha256, 15);
            }
            else {
                value = file.cybox_object_id;
            }
            return $filter('prefixWithPortionMarking')(value,
                file.portion_marking);
        },
        save: function (file, is_saving, success, failure) {
            if (angular.isUndefined(file) || file == {}) {
                toastr.error("Unable to save file observable");
            }
        },
        fetch_markings_object_from_scope: function(scope) {
            return fetch_markings_object_from_scope(scope)
        }
    };
}]);
