evaluation_ready = ->
  $("table.sortable_evaluations").tablesorter({
    headers: {
      ## ソートする列の指定
      0: {sorter:false},
      3: {sorter:false},
      4: {sorter:false},
      5: {sorter:false}
    },
    cssHeader:'headerSort'
  })
  @

$(document).on('turbolinks:load', evaluation_ready)
