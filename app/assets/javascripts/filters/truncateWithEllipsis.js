app.filter('truncateWithEllipsis', function truncateWithEllipsis($filter){
    return function(text, maxLength){
        // Default length at which to truncate the string is 15 if not
        // specified.
        var truncateLength = maxLength ? maxLength : 15;

        // Pass the string through as-is if it is shorter than the
        // truncation length or empty, etc.
        if (angular.isUndefined(text) || text == null || text.length <= truncateLength) {return text;}

        // Slice to the allowed length and add an ellipsis.
        return text.slice(0, truncateLength) + "...";
    }
});