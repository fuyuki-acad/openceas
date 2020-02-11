
/********** attendance.jsp **********/
<!--
	/*** attendanceTable ***/
	function mouseOverRow( id ){
    background_col_color = $("#col_"+id).css("backgroundColor");
    background_col_color0 = $("#col_"+id).css("backgroundColor");
    background_col_color1 = $("#col_"+id).css("backgroundColor");
    background_col_color2 = $("#col_"+id).css("backgroundColor");
		background_cell_colors = {};
		$("[id^='cell'][id*='_"+id+"']").filter(function(i, e) {
			background_cell_colors[e.id] = $(this).css('background-color');
			$(this).css('background-color', "#FFCCCC");
		});

		document.getElementById("col_"+id ).style.backgroundColor="#FFCCCC";
		document.getElementById("col0_"+id ).style.backgroundColor="#FFCCCC";
		document.getElementById("col1_"+id ).style.backgroundColor="#FFCCCC";
		document.getElementById("col2_"+id ).style.backgroundColor="#FFCCCC";
	}

	function mouseOutRow( id ){
    $("#col_"+id).css("backgroundColor", background_col_color);
    $("#col0_"+id).css("backgroundColor", background_col_color0);
    $("#col1_"+id).css("backgroundColor", background_col_color1);
    $("#col2_"+id).css("backgroundColor", background_col_color2);
		$("[id^='cell'][id*='_"+id+"']").filter(function(i, e) {
			$(this).css('background-color', background_cell_colors[e.id]);
		});

//		document.getElementById("col_"+id ).style.backgroundColor="#dce1f0";
//		document.getElementById("col0_"+id ).style.backgroundColor="white";
//		document.getElementById("col1_"+id ).style.backgroundColor="white";
//		document.getElementById("col2_"+id ).style.backgroundColor="white";
	}

	function mouseOverCol( id ){
    background_row_color = $("#row"+id).css("backgroundColor");

		document.getElementById("row"+id).style.backgroundColor="#ddddff";
	}

	function mouseOutCol( id ){
    $("#row"+id).css("backgroundColor", background_row_color);

//		document.getElementById("row"+id).style.backgroundColor="white";
	}

	function preparePersonalAttendance(course_id, id) {
//	  var personalNo = document.getElementById("attendance:personalNo");
//	  var personalButton = document.getElementById("attendance:personalButton");
//	  personalNo.value = id;
//	  personalButton.click();
	  location.href = course_id + '/edit_user/' + id;
	}

	function prepareClassSessionAttendance(course_id, class_session_count, attendance_count) {
//	  var str = id.split("_");
//	  var classSessionNo = document.getElementById("attendance:classSessionNo");
//	  var attendanceCountNo = document.getElementById("attendance:attendanceCountNo");
//	  var classSessionButton = document.getElementById("attendance:classSessionButton");
//	  classSessionNo.value = str[0];
//	  attendanceCountNo.value = str[1];
//	  classSessionButton.click();
	  location.href = course_id + '/edit/' + class_session_count + '/' + attendance_count;
	}

	function collectColor() {
	  var studentCount = document.getElementById("attendance:studentCount").value;
	  var collectClassSessionNo = document.getElementById("attendance:collectClassSessionNo").value;
	  var collectAttendanceCount = document.getElementById("attendance:collectAttendanceCount").value;
	  for (i = 1; i <= studentCount; i++) {
	    document.getElementById("cell"+i+"_"+collectClassSessionNo+"_"+collectAttendanceCount).style.backgroundColor="#FFFFDD";
	  }
	}
	/*** attendanceTable ***/

//-->
/********** attendance.jsp **********/

/********** classSessionAttendance.jsp **********/
<!--
	/*** classSessionAttendanceTable ***/
	function loadClassSessionAttendanceData() {
		var fm = document.classSessionAttendance;
		var classSessionAttendanceData = document.getElementById("classSessionAttendance:attendanceData").value;
		var studentCount = document.getElementById("classSessionAttendance:studentCount").value;
		for (var i = 1; i <= studentCount; i++) {
			document.getElementById("attendanceData"+i).value = classSessionAttendanceData.charAt(2*(i-1));
		}
	}
	/*** classSessionAttendanceTable ***/

	/*** button ***/
	function registerClassSessionAttendance() {
		var fm = document.classSessionAttendance;
		var classSessionAttendanceData = "";
		var studentCount = document.getElementById("classSessionAttendance:studentCount").value;
		for (var i = 1; i <= studentCount; i++) {
			classSessionAttendanceData += (document.getElementById("attendanceData"+i).value + ",");
		}
		document.getElementById("classSessionAttendance:attendanceData").value = classSessionAttendanceData;
	}

	function confirmBatchDelete(formName, buttonId, message1) {
		if(confirm(message1)){
			var button = document.getElementById(formName+':'+buttonId);
			button.click();
			return true;
		}else{
			return false;
		}
	}

	function confirmBatchDeleteNoClick(message1) {
		if(confirm(message1)){
//			var button = document.getElementById(formName+':'+buttonId);
//			button.click();
			return true;
		}else{
			return false;
		}
	}

	function doSubmit(formName, buttonId) {
		var button = document.getElementById(formName+':'+buttonId);
		button.click();
		return true;
	}
	/*** button ***/


//-->
/********** classSessionAttendance.jsp **********/

/********** attendanceUploadResult.jsp **********/
    function loadAttendanceUploadResultData() {
    	var fileSize = document.getElementById("classSessionAttendance:fileSize").value;
	    if(fileSize != ""){
	    	loadClassSessionAttendanceData();
	    }
    }
/********** attendanceUploadResult.jsp **********/

/********** personalAttendance.jsp **********/
<!--
	/*** personalAttendanceTable ***/
	function loadPersonalAttendanceData() {
		var fm = document.personalAttendance;
		personalAttendanceData = document.getElementById("personalAttendance:attendanceData").value;
		classSessionCount = document.getElementById("personalAttendance:classSessionCount").value;
		var attendanceCountList = new Array(classSessionCount);
		for (var i = 0; i < classSessionCount; i++) {
			attendanceCountList[i] = fm.elements[2 + i].value;
		}
		var num = 0;
		for (var i = 1; i <= classSessionCount; i++) {
			for (var j = 1; j <= attendanceCountList[i - 1]; j++) {
				document.getElementById("attendanceData"+i+"_"+j).value = personalAttendanceData.charAt(2*num);
				num++;
			}
		}
	}
	/*** personalAttendanceTable ***/

	/*** button ***/
	function registerPersonalAttendance() {
		var fm = document.personalAttendance;
		var personalAttendanceData = "";
		var classSessionCount = document.getElementById("personalAttendance:classSessionCount").value;
		var attendanceCountList = new Array(classSessionCount);
		for (var i = 0; i < classSessionCount; i++) {
			attendanceCountList[i] = fm.elements[2 + i].value;
		}
		for (var i = 1; i <= classSessionCount; i++) {
			for (var j = 1; j <= attendanceCountList[i - 1]; j++) {
				personalAttendanceData += (document.getElementById("attendanceData"+i+"_"+j).value + ",");
			}
		}
		document.getElementById("personalAttendance:attendanceData").value = personalAttendanceData;
	}
	/*** button ***/
//-->
/********** personalAttendance.jsp **********/
