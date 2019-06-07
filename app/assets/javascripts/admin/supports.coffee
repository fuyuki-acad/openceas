$(document).on 'click', '.support_paginate li a', (e) ->
  e.preventDefault()
  e.stopPropagation()

  match = $(this).context.search.match(/page=(.*?)(&|$)/);
  if (match)
    $("#page").val(match[1])

  $("#btn_support_detail").click()
  $("#page").val("")
  @

$(document).on 'show.bs.collapse', '.qna-response', (e) ->
  $('a[href="#' + this.id + '"] span.glyphicon-chevron-right')
    .addClass('glyphicon-chevron-down')
    .removeClass('glyphicon-chevron-right')

$(document).on 'hide.bs.collapse', '.qna-response', (e) ->
  $('a[href="#' + this.id + '"] span.glyphicon-chevron-down')
    .addClass('glyphicon-chevron-right')
    .removeClass('glyphicon-chevron-down')
