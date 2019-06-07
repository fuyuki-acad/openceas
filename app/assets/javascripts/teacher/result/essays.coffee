$(document).on 'click', '.btn_send_mail_essay', (e) ->
  e.preventDefault()
  e.stopPropagation()

  form = $(".form_send_mail")
  form.submit()
  @

$(document).on 'click', '.btn_return_report_essay', (e) ->
  e.preventDefault()
  e.stopPropagation()

  form = $(".form_return_report")
  form.append($("table.result_essay").clone())
  form.submit()
  @
