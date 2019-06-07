$(document).on 'click', '.search_unassigned_course', (e) ->
  e.preventDefault()
  e.stopPropagation()

  role_id = $("input[name*='role_id']:checked").val()
  $.ajax $(this).attr("href"),
    type: "POST",
    data: "role_id="+role_id+"&keyword="+$("#keyword").val(),
    dataType: "html",
    success: (data, textStatus, jqXHR) ->
      $('#unassigned_courses').html(data)
    error: (data, textStatus, jqXHR) ->
      alert(data.responseText)
    @

$(document).on 'click', '.select_parent_course', (e) ->
  e.preventDefault()
  e.stopPropagation()

  course_id = $(this).attr('data-course-id')
  course_name = $(this).attr('data-course-name')
  $('#course_parent_course_id').val(course_id)
  $('#course_parent_course_name').val(course_name)
  $('#parent-modal').modal('hide')

  return false

$(document).on 'click', '.clear_parent_course', (e) ->
  e.preventDefault()
  e.stopPropagation()

  $('#course_parent_course_id').val("")
  $('#course_parent_course_name').val("")

  return false

$(document).on 'click', '#copy_assigned', (e) ->
  $('#form_copy_assigned').val($(this).prop('checked'))

$(document).on 'click', '#copy_enrollment', (e) ->
  $('#form_copy_enrollment').val($(this).prop('checked'))
