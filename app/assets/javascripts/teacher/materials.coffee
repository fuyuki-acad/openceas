material_ready = ->
  $("table.sortable_materials").tablesorter({
    headers: {
      ## ソートする列の指定
      0: {sorter:false},
      4: {sorter:false},
      5: {sorter:false},
      6: {sorter:false}
    },
    cssHeader:'headerSort'
  })
  
  $("table.sortable_urls").tablesorter({
    headers: {
      ## ソートする列の指定
      0: {sorter:false},
      4: {sorter:false},
      5: {sorter:false}
    },
    cssHeader:'headerSort'
  })
  @

$(document).on('turbolinks:load', material_ready)
