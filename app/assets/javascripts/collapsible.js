$(function(){
    $('[data-collapsible]').next().hide();
    $('[data-collapsible]').click(function() {
      $(this).toggleClass('active');
      $(this).next().slideToggle();
      return false;
    });
});

