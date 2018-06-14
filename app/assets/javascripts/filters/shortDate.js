app.filter('shortDate', function shortDate($filter){
    return function(text){
        if (angular.isUndefined(text) || text == null) {return text;}
        var  tempdate= new Date(text.replace(/-/g,"/"));
        return $filter('date')(tempdate, "M/d/yy");
    }
});