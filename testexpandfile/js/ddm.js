$(document).ready(function () {
    $('#nav li').hover(
        function () { //show its submenu
           var el=this;
           $('ul', this).stop().slideDown(100);
           setTimeout( function(){
              $(el).find('>ul').fadeOut('slow')
           }, 15000 ); // 15 seconds .. just so it works on ipad
        },
        function () { //hide its submenu
           $('ul', this).stop().slideUp(100);
        } 
    );
});
