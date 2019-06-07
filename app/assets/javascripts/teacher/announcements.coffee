$(document).on 'click', '.search-user', (e) ->
  e.preventDefault()
  e.stopPropagation()

  $.ajax $(this).attr("href"),
    type: "GET",
    data: "&keyword="+$("#keyword").val(),
    dataType: "html",
    success: (data, textStatus, jqXHR) ->
      $('#result_users').html(data)
    error: (data, textStatus, jqXHR) ->
      alert(data.responseText)

$(document).on 'click', '.send-mail', (e) ->
  e.preventDefault()
  e.stopPropagation()
  target = $(this).data('target')
  checked = $('input[type="checkbox"][name^="'+target+'"]:checked')

  if (checked.length == 0)
    alert($(this).data('msg-not-checked'))
    return

  if (confirm($(this).data('msg-confirm')) == false)
    return

  $(this).parents('form').submit()
  @
