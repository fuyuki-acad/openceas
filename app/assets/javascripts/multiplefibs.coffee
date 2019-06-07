$(document).on 'click', '.multifib_clear_password', (e) ->
  $.ajax $(this).data('request-url'),
    type: "GET",
    dataType: "html",
    success: (data) ->
      window.parent.close()
    error: (data) ->
      window.parent.close()
  @
