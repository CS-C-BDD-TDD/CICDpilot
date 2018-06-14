app.service('Sighting', ['Restangular', '$filter', function (Restangular,
                                                             $filter) {
    return {
        getDisplayName: function (sighting) {
            var value;
            if (angular.isDefined(sighting.sighted_at) &&
                sighting.sighted_at != null && sighting.sighted_at.length) {
                value = "Indicator Sighted At " +
                    $filter('date')(sighting.sighted_at,
                    'MM/dd/yyyy HH:mm');
            }
            else if (angular.isDefined(sighting.description) &&
                sighting.description != null && sighting.description.length) {
                value = 'Indicator Sighting "' +
                    $filter('truncateWithEllipsis')(sighting.description,
                        15) + '"';
            }
            else if (angular.isDefined(sighting.user) &&
                sighting.user != null &&
                angular.isDefined(sighting.user.username) &&
                sighting.user.username != null &&
                sighting.user.username.length) {
                value = "Indicator Sighted By " + sighting.user.username;
            }
            else {
                value = 'Indicator Sighting "' + sighting.guid + '"';
            }
            return value;
        }
    };
}]);
