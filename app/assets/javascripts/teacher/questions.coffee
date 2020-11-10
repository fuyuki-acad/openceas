$(document).on 'change', '.select-max-count', (e) ->
	set_rows($('.select-max-count'))
@

$(document).on 'click', '.btn-delete-question', (e) ->
	e.preventDefault()
	e.stopPropagation()

#  $(this).parents('tr.select_row').remove()
	line = $(this).data('line')
	max = $('.select-max-count').val()
	for i in [1...101]
		continue if i < line
		break if i > max

		$("#question_quizzes_attributes_#{i}_id").val($("#question_quizzes_attributes_#{i+1}_id").val())
		$("#question_quizzes_attributes_#{i}_content").val($("#question_quizzes_attributes_#{i+1}_content").val())
		$("#question_quizzes_attributes_#{i}_select_correct_flag").prop('checked', $("#question_quizzes_attributes_#{i+1}_select_correct_flag").prop('checked'))
		$("#question_quizzes_attributes_#{i}_select_mark_flag").prop('checked', $("#question_quizzes_attributes_#{i+1}_select_mark_flag").prop('checked'))

	$('.select-max-count').val(max-1)
	set_rows($('.select-max-count'))
@

$(document).on 'click', '.btn_order_update', (e) ->
  e.preventDefault()
  e.stopPropagation()
  form = $(this).parents('form')
  action = form.attr("action").replace("destroy", "update_order")
  form.attr("action", action)
  form.find('input[name=_method]').val("patch")
  form.find('input[name=authenticity_token]').val($("meta[name=csrf-token]").attr("content"))

  $(this).addClass('disabled')
  setTimeout ->
    $(this).addClass('disabled')
  , 10000

  target = $(this).data('target')
  $('input[type="checkbox"][name^="'+target+'"]').each (index) ->
    $('<input>').attr({
      type: 'hidden',
      name: 'question[]'
      value: $(this).val()
    }).appendTo(form);

  form.submit()
@

$(document).on 'change', '.pattern_cd', (e) ->
	change_pattern($(this))
@

$(document).on 'click', '.clear_question_form', (e) ->
	e.preventDefault()
	e.stopPropagation()

	$("textarea[name*='question[quizzes_attributes]']").val('')
	$("input[name*='question[quizzes_attributes]']").prop('checked', false)
	$("input[name*='question[quizzes_attributes]']").prop('checked', false)
@

@set_rows = (obj) ->
	count = obj.val()
	if (count <= 1)
    $(".btn-delete-question").css({display: 'none'})
	else
    $(".btn-delete-question").css({display: 'block'})

  $(".select_row").each (index, element) ->
    if (index < count)
      $(this).css('display', '')
    else
      $(this).css('display', 'none')

@change_pattern = (obj) ->
  if (obj.val() == '4')
    $('#answerRow').css('display', '')
    $('#rowCount').css('display', '')
    $('#selectCount').css('display', 'none')
    $('#commentAtRight').css('display', 'none')
    $('#commentAtMistake').css('display', 'none')
    $('#other').css('display', 'none')
    $('.select_row').css('display', 'none')
  else
    $('#selectCount').css('display', '')
    $('#commentAtRight').css('display', '')
    $('#commentAtMistake').css('display', '')
    $('#other').css('display', '')
    $('#answerRow').css('display', 'none')
    $('#rowCount').css('display', 'none')
    set_rows($('.select-max-count'))
	@

$(document).on 'turbolinks:load', (e) ->
  # Table drag and drop sort
  $(".sortable-question tbody").sortable({
    placeholder: 'sort-placeholder'
    forcePlaceholderSize: true
    update: (e, ui) ->
      parent_id = $(ui.item).data('parent-id')
      $("#order_message_"+parent_id).show()
      $("#order_update_"+parent_id).show()
  })

	change_pattern($('.pattern_cd:checked'))
@
