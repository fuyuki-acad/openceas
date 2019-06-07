$(document).on 'change', '.answer_score', (e) ->
  summary = 0

  $(".answer_score").each ->
    summary += Number($(this).val())

  $("#essay_total_score").val(summary);
  @
