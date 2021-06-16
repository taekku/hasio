/**
 * 크로닉스(RD) 오픈
 * common.js 가 틀린 사이트가 있어서 연말정산용 추가 2014.12.31 피지훈
 * @param targetFrameNm : 오픈할 IFrame Name
 * @param reportPath : 레포트 파일 경로 ex) /test/test.mrd
 * @param paramData : 레포트 오픈시 전송할 파라미터 json object
 * @param windowWidth : 팝업으로 띄울시 windth
 * @param windowHeight : 팝업으로 띄울시 height
 * @param reportOption : 레포트 구동시의 옵션값 json object ({})
 */
function intOpenRD(targetFrameNm, reportPath, paramData , windowWidth , windowHeight, reportOption) {
	if ( targetFrameNm !== undefined && targetFrameNm !== null && targetFrameNm !== "null" && targetFrameNm !== "" ) {
		//TODO: (HYS) 2013-11-22 크로닉스 오버랩2
		if(_objectInfo) {
			
			if ( top.getObjectStack ){
				var objInfo = top.getObjectStack(_objectInfo.objectId);
				if(objInfo !== undefined && objInfo !== null) {
					objInfo.crownixInfo = {
						"targetFrame" : targetFrameNm,
						"page" : this
					};
				}
			}
		}
	}
	
	var paramMode = "KEY_NAME";
	//var paramMode = "SEQUENCE";
	//TODO: (HYS) 2013-11-25 레포트로 전송되는 파라미터 바인딩 구조 설정
	if(reportOption !== undefined && reportOption != null && reportOption.paramMode !== undefined && reportOption.paramMode !== null && (reportOption.paramMode === "KEY_NAME" || reportOption.paramMode === "SEQUENCE")) {
		paramMode = reportOption.paramMode;
	}
	
	var reportForm = $("form#reportForm");
	
	//팝업창으로 열림
	if ( targetFrameNm == null || targetFrameNm == "null" || targetFrameNm == "" || targetFrameNm == undefined ){
		
		var t_xpos = (screen.availWidth)/2;
	 	var t_ypos = (screen.availHeight)/2;
	 	
	 	var openWindowWidth = 800;
	 	var openWindowHeight = 600;
	 	
	 	if ( windowWidth != null && windowWidth != "null" && windowWidth != "" && windowWidth != undefined ){
	 		openWindowWidth = windowWidth;
	 	}
	 	
	 	if ( windowHeight != null && windowHeight != "null" && windowHeight != "" && windowHeight != undefined ){
	 		openWindowHeight = windowHeight;
	 	}
		
		var openWindowStyle = 'top='+ t_ypos +',left='+ t_xpos +',width=' + openWindowWidth + ',height=' + openWindowHeight;
		
		window.open("/common/web/null.html" , "__crownix_rd_popup" ,openWindowStyle);
		
		if(reportForm.length === 0) {
			reportForm = $("<form>").attr({
				"id" : "reportForm",
				"target" : "__crownix_rd_popup",
				"method" : "POST",
				"action" : "/int/web/int_crownix_open.jsp"
			}).appendTo($("body"));
		}
	}else{	// iframe 으로 페이지에 포함
		var target = $("iframe[name='" + targetFrameNm + "']");
		
		if(target.length === 0) {
			alert("iframe를 찾을수 없습니다.");
			return;
		}
		
		if(reportForm.length === 0) {
			reportForm = $("<form>").attr({
				"id" : "reportForm",
				"target" : targetFrameNm,
				"method" : "POST",
				"action" : "/int/web/int_crownix_open.jsp"
			}).appendTo($("body"));
		}
		
	}
	
	reportForm.empty().append($("<input>").attr({
		"id" : "reportPath",
		"name" : "reportPath",
		"type" : "hidden",
		"value" : reportPath
	}));
	
	var paramIdxStr = "";
	var seperator = ",";
	
	if(paramData !== undefined && paramData !== null) {
		
		$.each(paramData, function(key, value) {
	
			reportForm.append($("<input>").attr({
				"id" : key,
				"name" : key,
				"type" : "hidden",
				"value" : value
	
			}));
			paramIdxStr += key + seperator;
		});
		
		reportForm.append($("<input>").attr({
			"id" : "paramIndex",
			"name" : "paramIndex",
			"type" : "hidden",
			"value" : paramIdxStr
		}));
		
		reportForm.append($("<input>").attr({
			"id" : "paRamSeperator",
			"name" : "paRamSeperator",
			"type" : "hidden",
			"value" : seperator
		}));
		
		reportForm.append($("<input>").attr({
			"id" : "paramMode",
			"name" : "paramMode",
			"type" : "hidden",
			"value" : paramMode
		}));
		
		reportForm.append($("<input>").attr({
			"id" : "reportOption",
			"name" : "reportOption",
			"type" : "hidden",
			"value" : JSON.stringify(reportOption)
		}));
	}
	
	reportForm.submit();
}