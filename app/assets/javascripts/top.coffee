$(document).on 'click', '.global-navi-button-sm', (e) ->
  if $('#pnl_menu').hasClass('hidden-xs')
    $('#pnl_menu').removeClass('hidden-xs')
  else
    $('#pnl_menu').addClass('hidden-xs')
