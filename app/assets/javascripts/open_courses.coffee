$(document).on 'click', '.btn_assign_course', (e) ->
  e.preventDefault()
  e.stopPropagation()
  target = $(this).data('target')
  checked = $('input[type="checkbox"][name^="'+target+'"]:checked')

  if (checked.length == 0)
    alert($(this).data('msg-not-checked'))
    return

  if (confirm($(this).data('msg-confirm')) == false)
    return

  $(this).addClass('disabled')
  setTimeout ->
    $(this).addClass('disabled')
  , 10000

  $(this).parents('form').submit()

  @
