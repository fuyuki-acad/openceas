$(document).on 'click', '.radio_log_type', (e) ->
  if $(this).val() == "0"
    $(".accesslog_conditions").css({display: 'none'})
  else
    $(".accesslog_conditions").css({display: 'block'})
