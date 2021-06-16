

/**
 * INPUT 값의 HH:MM 포맷 적용
 * 
 * onBlur 또는 onKeyup 에 함수적용
 * 
 * ex ) <input type="text" onKeyUp="inputTimeColon" value="" ></input>
 * ex ) $("#text_time").keyup( function(){  inputTimeColon(this); });
 * ex ) $("#text_time").on("blur", function(){ inputTimeColon(this); });
 * 
 * @author jhkim
 * */
function inputTimeColon( time1 ) {
	
	if ( time1 == undefined || time1 == null ){
		
	} else {

		// 먼저 기존에 들어가 있을 수 있는 콜론(:)기호를 제거한다.
	    var replaceTime = time1.value.replace(/\:/g, "");
	
	    // 글자수가 4 ~ 5개 사이일때만 동작하게 고정한다.
	    if(replaceTime.length >= 4 && replaceTime.length < 5) {
	
	        // 시간을 추출
	        var hours = replaceTime.substring(0, 2);
	
	        // 분을 추출
	        var minute = replaceTime.substring(2, 4);
	
	        // 시간은 24:00를 넘길 수 없게 세팅
	        if(hours + minute > 2400) {
	            time1.value = "24:00";
	            return false;
	        }
	
	        // 분은 60분을 넘길 수 없게 세팅
	        if(minute > 60) {
	            time1.value = hours + ":00";
	            return false;
	        }
	
	        // 콜론을 넣어 시간을 완성하고 반환한다.
	        time1.value = hours + ":" + minute;
	    }
	}
}

/**
 * HH:MM TEXT INPUT 의 포맷 제거
 * 
 * @author jhkim
 * */
function removeColon( str ){
	
	if ( str == undefined || str == null ){
		
		return "";
	}
	
	return str.replace(":" , "");
	
}

