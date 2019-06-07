# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
timerId = "1"

@startTimer =() ->
  attendanceCd = $("#attendance_cd").val()
  if (attendanceCd == "attendance" || attendanceCd == "late")
    restTime = $("#rest_time").val()
    restMinute = $("#rest_minute").val()
    # time to update page
#    var interval = restTime - ((restMinute - 1) * 1000 * 60);
    # update page after interval
#    setTimeout("timer()", interval);
    setTimeout("timer()", 60 * 1000)
  @

@timer = () ->
  attendanceCd = $("#attendance_cd").val()
  restMinute = $("#rest_minute").val()
  $("#rest_minute_count").text(restMinute - 1)
  $("#rest_minute").val(restMinute - 1)
  if ($("#rest_minute").val() > 0)
    timerId = setTimeout("timer()", 60 * 1000)
  else
    latePeriod = $("#late_period").val()
    sessionNo = $("#session_no").val()
    attendanceCount = $("#attendance_count").val()
    if latePeriod > 0
      $("#start_collect_late").submit()
    else
      location.href = 'stop_collect_attendance?session_no=' + sessionNo + '&attendance_count=' + attendanceCount
  @

@stopTimer =() ->
  clearTimeout(timerId)
  @

@showAbsentStudent = (url) ->
#	var attendanceCd = document.getElementById("attendanceCd:attendanceCd").value;
#	if (attendanceCd == "end") {
#	  absentStudentWindow = openWindow3(url, "absentStudentWindow", 500, 480);
#	}
  @

@anotherClassSession = (str) ->
#	var attendanceCd = document.getElementById("attendanceCd:attendanceCd").value;
#	if (attendanceCd == "another") {
#	  document.getElementById("another:button").value = str;
#	}
  @

@recollectAttendance =() ->
  $("form").attr("action", "recollect_attendance")
  $("form").submit()
  @

@recollectLate =() ->
  $("form").attr("action", "recollect_late")
  $("form").submit()
  @

@deleteAttendance =() ->
  $("form").attr("action", "delete_attendance")
  $("form").submit()
  @
