<!--

	/**
	 * 公開科目のラジオボタンによって公開パスワードの利用可・利用不可を切り替える
	 */
	function changeRadio(formName) {
		var selfType = document.getElementsByName(formName + ":openRadio");

	    if(selfType[1].checked == true) {
	      document.getElementById(formName + ":openPassword").disabled = false;
	      document.getElementById(formName + ":openPassword").style.backgroundColor='#FFFFFF';
	    }else if(selfType[2].checked == true) {
	      document.getElementById(formName + ":openPassword").disabled = true;
	      document.getElementById(formName + ":openPassword").style.backgroundColor='#D4D0C8';
	      document.getElementById(formName + ":openPassword").value = "";
	    }
	}

	/**
	 * 入力項目をチェックする
	 */
	function checkRegisterCourse(formName, editCourseFlg, str1, str2, str3, str4, str5, str6, str7, str8, str9, str10){
		var courseName = $("#course_course_name").val();
		var courseCd = $("#course_course_cd").val();
		var courseCdSv = $("#course_sv_course_cd").val();
		var overview = $("#course_overview").val();
		var instructorName = $("#course_instructor_name").val();
		var major = $("#course_major").val();
		var openPassword = $("#course_open_course_pass").val();
		var attendanceIp1 = $("#course_attendance_ip1").val();
		var attendanceIp2 = $("#course_attendance_ip2").val();
		var attendanceIp3 = $("#course_attendance_ip3").val();
		var attendanceIp4 = $("#course_attendance_ip4").val();
		var schoolYear = $("#course_school_year").val();
		var schoolYearSv = $("#course_sv_school_year").val();
		var seasonCd = $("#course_season_cd").val();
		var seasonCdSv = $("#course_sv_season_cd").val();

		/* courseName check */
		if(courseName == null || courseName == ""){
			alert(str1);
			return false;
		}
		if(64 < courseName.length){
			alert(str2);
			return false;
		}

		/* courseCd check */
		if(courseCd == null || courseCd == ""){
			alert(str3);
			return false;
		}
		if(128 < courseCd.length){
			alert(str4);
			return false;
		}
		if(!courseCd.match(/^[0-9a-zA-Z\-]+$/)){
			alert(str4);
			return false;
		}

		/* overview check */
		if(4096 < overview.length){
			alert(str5);
			return false;
		}

		/* instructorName check */
		if(128 < instructorName.length){
			alert(str6);
			return false;
		}

		/* major check */
		if(64 < major.length){
			alert(str7);
			return false;
		}

		/* openPassword check */
		if(!openPassword.match(/^[0-9a-zA-Z]+$/) && openPassword.length != 0){
			alert(str8);
			return false;
		}
		if(64 < openPassword.length){
			alert(str8);
			return false;
		}

		/* attendanceIp1 check */
		if(!attendanceIp1.match(/^(([0-9]{1,3})|(\*{1}))\.(([0-9]{1,3})|(\*{1}))\.(([0-9]{1,3})|(\*{1}))\.(([0-9]{1,3})|(\*{1}))$/) && attendanceIp1.length > 0){
			alert(str9);
			return false;
		}
		if(15 < attendanceIp1.length){
			alert(str9);
			return false;
		}

		/* attendanceIp2 check */
		if(!attendanceIp2.match(/^(([0-9]{1,3})|(\*{1}))\.(([0-9]{1,3})|(\*{1}))\.(([0-9]{1,3})|(\*{1}))\.(([0-9]{1,3})|(\*{1}))$/) && attendanceIp2.length > 0){
			alert(str9);
			return false;
		}
		if(15 < attendanceIp2.length){
			alert(str9);
			return false;
		}

		/* attendanceIp3 check */
		if(!attendanceIp3.match(/^(([0-9]{1,3})|(\*{1}))\.(([0-9]{1,3})|(\*{1}))\.(([0-9]{1,3})|(\*{1}))\.(([0-9]{1,3})|(\*{1}))$/) && attendanceIp3.length > 0){
			alert(str9);
			return false;
		}
		if(15 < attendanceIp3.length){
			alert(str9);
			return false;
		}

		/* attendanceIp4 check */
		if(!attendanceIp4.match(/^(([0-9]{1,3})|(\*{1}))\.(([0-9]{1,3})|(\*{1}))\.(([0-9]{1,3})|(\*{1}))\.(([0-9]{1,3})|(\*{1}))$/) && attendanceIp4.length > 0){
			alert(str9);
			return false;
		}
		if(15 < attendanceIp4.length){
			alert(str9);
			return false;
		}
		if(editCourseFlg == 1){
			if(courseCd != courseCdSv){
				return confirm(str10);
			}
			if(schoolYear != schoolYearSv){
				return confirm(str10);
			}
			if(seasonCd != seasonCdSv){
				return confirm(str10);
			}
		}
		$("#course_open_course_pass").prop("disabled", false);
		return true;
	}


	function onClickSearchType1(formName) {
	    var searchType = document.getElementsByName(formName + ":searchType1");

	    var daySelect = document.getElementById(formName+":dayCd_select");
	    var hourSelect = document.getElementById(formName+":hourCd_select");
	    var yearSelect = document.getElementById(formName+":schoolYear_select");
	    var sseasonSelect = document.getElementById(formName+":seasonCd_select");


	    for(var i=0;i<searchType.length;i++) {
	        if (searchType[i].checked && searchType[i].value == '2') {

	            daySelect.selectedIndex = 0;
	            hourSelect.selectedIndex = 0;
	            yearSelect.selectedIndex = 0;
	            sseasonSelect.selectedIndex = 0;
	        }
        }

	}

	function checkBatchUpdate(formName,couseCount,str1,str2) {
		if(couseCount == 0){
			alert(str1);
			return false;
		}

		if(confirm(str2.replace("%{param0}",couseCount))){
			return true;
		}else{
			return false;
		}
	}


  function batchUpdate(formName, enabled) {
    var submitButton = document.getElementById(formName+":revisebutton");
    if (enabled) {
     submitButton.disabled = "";
    } else {
     submitButton.disabled = "true";
    }
   }

//-->
