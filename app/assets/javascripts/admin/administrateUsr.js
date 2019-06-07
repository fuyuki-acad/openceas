<!--
function checkUsrForm(form1,form2,form3,form4,form5,form6,message1,message2,message3,message4,message5,message6,message7,message8){
	var usrName = document.getElementById(form1);
	var account = document.getElementById(form2);
	var password = document.getElementById(form3);
	var birthday = document.getElementById(form4);
	var mail = document.getElementById(form5);
	var cellMail = document.getElementById(form6);

	if(usrName.value.length < 1){
		alert(message1);
		return false;

	} else if(account.value.length < 1){
		alert(message2);
		return false;

//	} else if(password.value.length < 1 ){
//		alert(message3);
//		return false;

	} else if(!checkAccountHalfFont(account.value)){
		alert(message4);
		return false;

	} else if(password.value.length > 0 && !checkPasswordHalfFont(password.value)){
		alert(message5);
		return false;

	} else if(password.value.length > 0 && !checkPasswordForm(password.value)){
		alert(message6);
		return false;
	}



	if(!checkMail2(mail.value, message7)){
		return false;
	}

	if(!checkMail2(cellMail.value, message7)){
		return false;
	}

	if(!checkBirthDate(birthday.value)){
		alert(message8);
		return false;
	}

	return true;

}


function checkBirthDate(birthDay){
	if(birthDay.length != 0){
		if(birthDay.indexOf("/") < 0){
			return false;
		}

		var birth = birthDay.split("/");
		if(birth.length != 3){
			return false;
		}else{
			for(i = 0;i < birth.length;i++){
				if(!checkHalfFontNumber(birth[i])){
					return false;
				}
				if(birth[1] < 0 || birth[1] > 12){
					return false;
				}
				if(birth[2] < 0 || birth[2] > 31){
					return false;
				}

			}
		}

		return true;
	}else{
		return true;
	}
}

function checkPasswordForm(password){
	if(checkPassLength(password)){
		return true;
	} else {
		return false;
	}
}


function checkPassLength(string){
	var stringCount = string.length;

	if(stringCount < 6 || stringCount > 256){
		return false;
	} else {
		return true;
	}

}

function checkMail(address,message){
	if(address.length < 1){
		return true;

	} else if ( !checkHalfFont(address)) {
    	alert(message);
    	return false;

	} else if(address.indexOf('@') < 0 || address.indexOf('.') < 0){
		alert(message);
		return false;

	} else {
		return true;
	}
}

function checkMail2(address, message){
	if(address.length < 1){
		return true;

	} else if (!address.match(/[!-?A-~]+@[!-?A-~]+\.[!-?A-~]+/)) {
    	alert(message);
    	return false;
	}

	return true;
}

function checkHalfFont(str){
	if(str.match(/^[0-9a-zA-Z@.-_]+$/)){
		return true;
	}else{
		return false;
	}
}

function checkHalfFont2(str){
	if(str.match(/^[0-9a-zA-Z]+$/)){
		return true;
	}else{
		return false;
	}
}

function checkHalfFontNumber(str){
	if(str.match(/^[0-9]+$/)){
		return true;
	}else{
		return false;
	}
}

function checkAccountHalfFont(str){
	if(str.match(/^[0-9a-zA-Z\.\-\_]+$/)){
		return true;
	}else{
		return false;
	}
}

/**
 * checkPasswordHalfFont -> common.js
 */
//-->
