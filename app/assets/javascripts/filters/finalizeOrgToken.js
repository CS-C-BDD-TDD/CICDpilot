app.filter('finalizeOrgToken', function(){
    return function(text){
        if (angular.isUndefined(text) || text == null || text == '') {
            return "DEFAULT_HEATMAP";
        }
        return text;
    }
});
