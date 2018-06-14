app.filter('addSpaceAfterComma', function(){
    return function(text){
        if (angular.isUndefined(text) || text == null || text == '') {
            return text;
        }
        return text.replace(/,/g,', ');
    }
});