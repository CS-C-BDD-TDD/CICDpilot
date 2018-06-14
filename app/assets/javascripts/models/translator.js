app.service('Translator', function(){
  return {
    get_display_status: function(s){
       switch (s) {
          case "S":
             return "Success";
             break;
          case "F":
             return "Failure";
             break;
          case "I":
             return "In-Progress";
             break;
          case "C":
             return "Canceled";
             break;
          case "R":
             return "Replaced";
             break;
          default:
             return "Failure";
       }
    }

  };
});
