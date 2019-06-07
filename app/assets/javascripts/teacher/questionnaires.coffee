questionnaire_ready = ->
  $("table.sortable_questionnaires").tablesorter({
    headers: {
      ## ソートする列の指定
      0: {sorter:false},
      3: {sorter:false}
    },
    cssHeader:'headerSort'
  })
  @

$(document).on('turbolinks:load', questionnaire_ready)
