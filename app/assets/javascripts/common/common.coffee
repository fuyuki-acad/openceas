# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

#
# Windowを閉じる
@closeWindow =() ->
  if (/Chrome/i.test(navigator.userAgent))
    window.close()
  else
    window.open('about:blank', '_self').close()
  @

@closeWindow2 =() ->
  window.parent.close();
  @

@openWindow1 =(url, pageName) ->
	if (url != '')
		newWindow1 = window.open(url, pageName)
  @

@openWindow2 =(url, pageName, width, height) ->
  if (url && (url != ''))
  	newWindow2 = window.open(url, pageName,
		  'toolbar=no,location=no,status=no,menubar=no,scrollbars=no,resizable=yes,width='+width+',height='+height).focus()
	  return false
  @

@openWindow3 =(url, pageName, width, height) ->
  if (url && (url != ''))
  	newWindow3 = window.open(url, pageName,
		  'toolbar=no,location=no,status=no,menubar=no,scrollbars=yes,resizable=yes,width='+width+',height='+height).focus()
	  return false
  @

@fadeOut =(classname) ->
  $("."+classname).fadeOut();
  @

@fadeIn =(classname) ->
  $("."+classname).fadeIn();
  @

@changeFrame =(frameId, url) ->
  question_file=window.top.document.getElementById(frameId);
  question_file.src = url;
  @

#
# アンカースクロール
@smoothScrolling = (className) ->
  target = $("[id="+className+"]").offset().top
  $('html,body').animate({ scrollTop: target }, '400, swing')
@

#
# ドキュメント表示時、初期処理
ready = ->
  #ツールチップバルーン表示
  $('[data-toggle="tooltip"]').tooltip()

  #PC/スマホパネル制御
  if isDesktop()
    collapseAddIn("collapseUser")
    collapseAddIn("collapseListInfo")
    collapseAddIn("collapseListFAQ")
    collapseAddIn("collapseMenu")
  else
    collapseRemoveIn("collapseUser")
    collapseRemoveIn("collapseListInfo")
    collapseRemoveIn("collapseListFAQ")
    collapseRemoveIn("collapseMenu")

  # Datetime picker
  $(".datetimepicker").datetimepicker()

  #２重submit防止
  $('form').submit ->
    double_submit_protection(this)

  # 他の科目からのコピーでのテーブルソート
  $("table.sortable_select_pages").tablesorter({
    headers: {
      ## ソートする列の指定
      0: {sorter:false}
    },
    cssHeader:'headerSort'
  })

  $('#iframe1').load ->
    $(this).height(0)
    $(this).height(this.contentWindow.document.documentElement.scrollHeight)

  @

#
# PC/スマホパネル制御
$(window).resize ->
  if isDesktop()
    collapseAddIn("collapseUser")
    collapseAddIn("collapseListInfo")
    collapseAddIn("collapseListFAQ")
    collapseAddIn("collapseMenu")
  else
    collapseRemoveIn("collapseUser")
    collapseRemoveIn("collapseListInfo")
    collapseRemoveIn("collapseListFAQ")
    collapseRemoveIn("collapseMenu")
  @

#
# windowサイズ判定
@isDesktop = () ->
  if $(window).width() >= 768
    return true
  else
    return false
  @

#
# パネル開く
@collapseAddIn = (className) ->
  $("[id^="+className+"]").each ->
    $(this).addClass("in")
    $(this).css("height", "")
  @

#
# パネル閉じる
@collapseRemoveIn = (className) ->
  $("[id^="+className+"]").each ->
    $(this).removeClass("in")
  @

#
# 科目検索
@searchCourse =(url) ->
  param = ""

  if location.search.substring(1)
    arr_params = location.search.substring(1).split('&')
    for i in [0..arr_params.length - 1]
      if arr_params[i].indexOf('name=') != 0
        if param == ""
          param += "?"
        else
          param += "&"
        param += arr_params[i]

  if $("#course_name").length && $("#course_name").val().length > 0
    if param == ""
      param = "?course_name="+encodeURI($("#course_name").val())
    else
      param += "&course_name="+encodeURI($("#course_name").val())

  location.href=url+param
  @

@loadGlobalNaviModal =() ->
  $('#global-navi-modal').removeData('bs.modal');
  $('#global-navi-modal').modal({'remote': "/layout/navi/global-navi"})
  @

$(document).on 'click', '.check_selector', (e) ->
  e.preventDefault()
  e.stopPropagation()
  target = $(this).data('target')
  if ($(this).attr('data-status') == 'on')
    $('input[type="checkbox"][name^="'+target+'"]').prop('checked', false)
    $(this).attr('data-status', 'off')
    $(this).text($(this).data('on-title'))
  else
    $('input[type="checkbox"][name^="'+target+'"]').prop('checked', true)
    $(this).attr('data-status', 'on')
    $(this).text($(this).data('off-title'))
  @

$(document).on 'click', '.check_all_selector', (e) ->
  e.preventDefault()
  e.stopPropagation()
  if ($(this).attr('data-status') == 'on')
    $('input[type="checkbox"]').prop('checked', false)
    $(this).attr('data-status', 'off')
    $(this).text($(this).data('on-title'))
  else
    $('input[type="checkbox"]').prop('checked', true)
    $(this).attr('data-status', 'on')
    $(this).text($(this).data('off-title'))
  @

$(document).on 'click', '.check_text', (e) ->
  e.preventDefault()
  e.stopPropagation()
  target = $(this).data('target')
  if ($('input[name^="'+target+'"]').val() == '')
    alert($(this).data('msg-empty'))
    return

  $(this).parents('form').submit()

@double_submit_protection =(submit) ->
  self = submit
  $(":submit", self).prop("disabled", true)
  setTimeout ->
    $(":submit", self).prop("disabled", false)
  , 10000
@

$(document).on 'click', '.multi_delete', (e) ->
  e.preventDefault()
  e.stopPropagation()
  target = $(this).data('target')
  checked = $('input[type="checkbox"][name^="'+target+'"]:checked')

  if (checked.length == 0)
    alert($(this).data('msg-not-checked'))
    return

  if (confirm($(this).data('msg-confirm')) == false)
    return

  $(this).addClass('disabled')
  setTimeout ->
    $(this).addClass('disabled')
  , 10000

  $(this).parents('form').submit()

  @

$(document).on 'click', '.close_and_clear_password', (e) ->
  $.ajax $(this).data('request-url'),
    type: "GET",
    dataType: "html",
    success: (data) ->
      window.close()
    error: (data) ->
      window.close()
  @

$(document).on('show.bs.modal', '.select-course-modal', (event) ->
  course_id = $(event.relatedTarget).data('id')
  controller = $(event.relatedTarget).data('controller')
  action = $(event.relatedTarget).data('action')
  if (action == undefined) 
    action = ""

  $.ajax '/other_courses/'+course_id+"?controller_name="+controller+"&list_action="+action,
    type: "get",
    cache: false,
    success: (data, textStatus, jqXHR) ->
      $('.select-course-modal .modal-content').html(data)
    error: (data, textStatus, jqXHR) ->
      alert(data.responseText)
)

$(document).on("ajax:success", ".pagination li a", (event) ->
  data = event.detail[0]
  $('.select-course-modal .modal-content').html(data.body.innerHTML)
)


$(document).on('turbolinks:load', ready)
