app.filter('showFullClassification', function(){
    return function(text){
        switch(text){
            case 'U': 
              return 'Unclassified';
            case 'C':
              return 'Confidential';
            case 'S':
              return 'Secret';
            case 'TS':
              return 'Top Secret';
            default:
              return 'Unknown';
        }
    }
});