$(document).on 'turbolinks:load', ->
  height = document.body.scrollHeight
  if (height < 500)
    height = 500
  $("#question_file", window.parent.document).height(height)
  $("#multiple_fibMain", window.parent.document).height(height)
  @

$(document).on 'click', '.update_multiplefib', (e) ->
  rows = $("table.multiplefib_questions > tbody > tr")
  for row, i in rows
    cells = $(row).children('td')
    if (cells.length == 0)
      continue

    value = $(cells[2]).find('input').val()
    if (value == "")
      alert($(this).data('msg-not-input-correct'))
      e.preventDefault()
      e.stopPropagation()
      return

    value = $(cells[3]).find('input').val()
    if (value == "")
      alert($(this).data('msg-not-input-score'))
      return false
    if (!value.match(/^[0-9]+$/) || value.match(/^[0-9]+$/) == null)
      alert($(this).data('msg-not-alphanumeric'))
      e.preventDefault()
      e.stopPropagation()
      return

    value = $(cells[4]).find('input').val()
    if (value != "" && (!value.match(/^[0-9]+$/) || value.match(/^[0-9]+$/) == null))
      alert($(this).data('msg-not-alphanumeric'))
      e.preventDefault()
      e.stopPropagation()
      return

    value = $(cells[5]).find('input').val()
    if (value != "" && (!value.match(/^[0-9]+$/) || value.match(/^[0-9]+$/) == null))
      alert($(this).data('msg-not-alphanumeric'))
      e.preventDefault()
      e.stopPropagation()
      return

  form = $(this).parents('form')
  form.append($("table.multiplefib_questions").clone())
  form.submit()
  @

$(document).on 'click', '.btn_add_question', (e) ->
  e.preventDefault()
  e.stopPropagation()

  form = $(".add_question_form")
  $('<input/>', {type: 'hidden', name: 'parent_id', value: $(this).data('parent-id')}).appendTo(form)
  form.append($("table.multiplefib_questions").clone())
  form.submit()
  @
