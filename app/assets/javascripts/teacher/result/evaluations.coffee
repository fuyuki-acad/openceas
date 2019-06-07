$(document).on 'click', '.btn_all_score', (e) ->
  if ($('#all_score').val() == "")
    alert($(this).data('not-set'))
    return false

  value = $('#all_score').val()
  $("input[name^='assignment_essay_score']").each ->
    if ($(this).val() == "")
      $(this).val(value)
  return false
  @

$(document).on 'click', '.btn_all_comment', (e) ->
  if ($('#all_comment').val() == "")
    alert($(this).data('not-set'))
    return false

  value = $('#all_comment').val()
  $("input[name^='memo']").each ->
    if ($(this).val() == "")
      $(this).val(value)
  return false
  @

$(document).on 'click', '.btn_send_mail', (e) ->
  e.preventDefault()
  e.stopPropagation()

  if ($("textarea[name='mail_content']").val() == "")
    alert($(this).data('msg-no-mail-contet'))
    return

  checked = $("input[name^='mail_flag']:checked")
  if (checked.length == 0)
    alert($(this).data('msg-not-checked'))
    return

  if (confirm($(this).data('msg-confirm')) == false)
    return

  form = $(".form_send_mail")
  form.append($("table.result_evaluations").clone())
  form.submit()
  @
