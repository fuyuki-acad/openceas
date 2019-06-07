$(document).on 'click', '#submit_execution', (e) ->
  e.preventDefault()
  e.stopPropagation()

  form = $(this).parents('form')
  action = form.attr("action").replace("save", "confirm")
  form.attr("action", action)
  form.submit()
  $(this).attr("disabled", true)
  setTimeout ->
    $(this).attr("disabled", false)
  , 10000
