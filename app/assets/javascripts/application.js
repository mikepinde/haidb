//= require jquery
//= require jquery_ujs
//= require_self
//= require_tree .

$(document).ready(function(){
  var dp = $('input.ui-date-picker');
  if (dp.length > 0)
    dp.datepicker({ dateFormat: 'dd.mm.yy' });
});
