app.filter('convertBoolean', function(){
  return function(input,true_name,false_name){
    if (input == true){
      return true_name;
    }
    else {
      return false_name;
    }
  }
});