app.filter("hyphen2nl", function($filter) {
 return function(data) {
   if (!data) return data;
   return data.replace(/-/g, '\r\n');
 };
});
