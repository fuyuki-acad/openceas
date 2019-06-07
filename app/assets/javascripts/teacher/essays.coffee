essay_ready = ->
  $("table.sortable_essays").tablesorter({
    headers: {
      ## ソートする列の指定
      0: {sorter:false},
      3: {sorter:false}
    },
    cssHeader:'headerSort'
  })
  @

$(document).on('turbolinks:load', essay_ready)
