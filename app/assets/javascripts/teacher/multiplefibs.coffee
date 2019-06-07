multiplefib_ready = ->
  $("table.sortable_multiplefibls").tablesorter({
    headers: {
      ## ソートする列の指定
      0: {sorter:false},
      5: {sorter:false},
      6: {sorter:false},
      7: {sorter:false}
    },
    cssHeader:'headerSort'
  })
  @

$(document).on('turbolinks:load', multiplefib_ready)
