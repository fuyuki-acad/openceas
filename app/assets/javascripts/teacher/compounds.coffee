compound_ready = ->
  if $('.self_type:checked').length > 0
    change_disabled($('.self_type:checked'))

  $("table.sortable_compounds").tablesorter({
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

$(document).on 'change', '.self_type', (e) ->
  change_disabled($(this))
  @

@change_disabled = (triger) ->
  if (triger.val() == '2') || (triger.val() == '3')
    $(".self_pass").prop("disabled", false);
  else
    $(".self_pass").prop("disabled", true);
  @

$(document).on('turbolinks:load', compound_ready)
