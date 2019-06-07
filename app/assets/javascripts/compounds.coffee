$(document).on 'change', '.self_score', (e) ->
  summary = Number($("#hidden_multiple_score").val())

  $(".self_score").each ->
    summary += Number($(this).val())

  $(".self_total_score").val(summary)
  total_point = Number($("#total_point").val())
  per_hundred = Math.round(summary * 100 / total_point)
  $(".total_score_per_hundred").val(per_hundred)
  @

$(document).on 'confirm:complete', '.btn_cancel_close', (e) ->
  if e.detail[0] == true
    window.close()
