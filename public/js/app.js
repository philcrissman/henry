$(function() {
  
  $("#show").toggle(function(){
        $("#stuff").animate({marginTop:'+=148px'}, {queue:false,duration:300});
        setTimeout(1000);
        $("#show")[0].innerHTML = '&#9759;';
      },
      function(){
        $("#stuff").animate({marginTop:'-=148px'}, {queue:false,duration:300});
        setTimeout(($("#show")[0].innerHTML = '&#9757;'),1000);
      });
});
