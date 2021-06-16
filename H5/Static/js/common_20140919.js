/**
 * 콘솔 로그 찍기....
 */
jQuery.logger = function(text) {

	if ((window['console'] !== undefined)) {
		console.log(text);
	}
	//11

};

/**
 * 컨테이너(Table)에 데이터 바인딩
 * 
 * @param containerSelector
 * @param jsonObject
 * @return
 */
function doBind(containerSelector, jsonObject) {
	$(containerSelector).unlink(jsonObject);
	$(containerSelector).link(jsonObject);

	for ( var name in jsonObject) {
		$(jsonObject).trigger("changeField", [ name, jsonObject[name] ]);
	}
}

function formating(domainObj, selector) {
	if (domainObj === undefined || domainObj === null || domainObj.length === 0) {
		//$.logger("domainObj is undefined");
		return;
	}
	
	var _maskFormats = {
		"Ymd" : "9999.99.99",
		"Ym" : "9999.99",
		"IdNo" : "999999-9999999"
	};
	
	var dateChangeFileds = [];
	
	$.each(domainObj, function(i, o) {
		var key = o['key'];
		var domain = o['domain'];
		
		if (domain !== undefined && domain !== null && "Number||IdNo||Ym||Ymd".indexOf(domain) > -1) {
			// var keyObj = $("div[dataProvider='" + selector + "']>table>tbody>tr>td>[name='" + key + "']");
			var keyObj = $("div[dataProvider='" + selector + "']>table").find("[name='" + key + "']");
			var tempObj = $("div[dataProvider='" + selector + "']>table").find("[name='end_ymd']");
			
			switch (domain) {
				case "Ymd":
					keyObj.mask(_maskFormats[domain], {
						placeholder : ' '
					});
					
					if(tempObj[0] !== undefined) {
						tempObj.mask(_maskFormats[domain], {
							placeholder : ' '
						});
					}
					
					dateChangeFileds[dateChangeFileds.length] = keyObj;
					break;
				case "Ym":
				case "IdNo":
					keyObj.mask(_maskFormats[domain], {
						placeholder : ' '
					});
					break;
				case "Number":
					keyObj.unbind("keydown keyup");
					makeComma(keyObj[0]);
					keyObj
					.bind("keydown", function(e) {
						var evt = window.event || e;
						onlyNumberKey(evt);
					})
					.bind("keyup", function(e) {
						var evt = window.event || e;
						makeComma(this, evt);
						
					});
					break;
			}
		}
	});
	
	$.each(dateChangeFileds, function (idx, obj) {
		obj.change();
	});
}

function divSizing(type, targetId, height) {
	//$.logger("\t\t" +type + " :: " + targetId + " : " + height);
	var newHeight;
	if(type == "IBSheet") {
		newHeight = ($(window).height() - $('#sheet_' + targetId).offset().top) * height / 100 - 10 + "px";
		targetId = 'DIV_' + targetId;
	}
	else if(type == "Tree") {
		newHeight = ($(window).height() - $('#' + targetId).offset().top) * height / 100 - 10 + "px";
	}
	else if(type == "ChildObjectContainer") {
		newHeight = ($(window).height() - $('#' + targetId).offset().top) * height / 100 - 27 + "px";
	}
	else if(type == "ChildObjectContainer2") {
		newHeight = ($(window).height() - $('#' + targetId).offset().top) * height / 100 - 43 + "px";
	}
	else {
		newHeight = ($(window).height() - $('#' + targetId).offset().top) * height / 100 - 10 + "px";
	}
	
	if(newHeight !== undefined && newHeight !== null && newHeight !== "") {
		//$.logger("\t" + targetId + " : " + newHeight);
		$("#" + targetId).height(newHeight);
	}
}

function onlyNumberKey(evt) {
	if (!(evt.keyCode == 107 || evt.keyCode == 187 // keyCode( + )
			|| evt.keyCode == 109 || evt.keyCode == 189 // keyCode( - )
			|| evt.keyCode == 110 || evt.keyCode == 190 // keyCode( . )
			|| (evt.keyCode >= 37 && evt.keyCode <= 40) // keyCode( 방향키 )
			|| evt.keyCode == 8 // keyCode ( backspace )
			|| evt.keyCode == 46 // keyCode ( del )
			|| evt.keyCode == 9 // keyCode ( tab )
	|| ((evt.keyCode >= 48 && evt.keyCode <= 57) || (evt.keyCode >= 96 && evt.keyCode <= 105)) // keyCode( 0~9 )
	)) {
		if (evt.prevtDefault)
			evt.prevtDefault();
		else
			evt.returnValue = false;
		
		return false;
	}
	
	return true;
}

function makeComma(obj, evt) {
	if (evt === undefined || evt === null || !(evt.keyCode >= 37 && evt.keyCode <= 40)) {
		var srcValue = $(obj).val();
		var iValue = removeChar(srcValue, ",");
		var pValue = "";
		var sign = "";
		if(srcValue !== null && srcValue !== undefined && srcValue !== "") {
			if (srcValue.substring(0, 1) == "-" || srcValue.substring(0, 1) == "+") {
				sign = srcValue.substring(0, 1);
				iValue = srcValue.substring(1);
			}
			
			if (iValue.indexOf(".") > -1) {
				pValue = iValue.substring(iValue.indexOf("."));
				iValue = iValue.substring(0, iValue.indexOf("."));
			}
			
			var rValue = "";
			for ( var i = 0; i <= iValue.length - 1; i++) {
				if (((iValue.length - i) % 3) == 1 && (i < iValue.length - 1))
					rValue += iValue.charAt(i) + ",";
				else
					rValue += iValue.charAt(i);
			}
			
			$(obj).val(sign + rValue + pValue).change();
		}
	}
	
	return true;
}

function unformating(domainObj, dataObj) {
	if (domainObj === undefined || domainObj === null || domainObj.length === 0) {
		//$.logger("domainObj is undefined");
		return;
	}
	
	if (typeof (dataObj) === 'undefined' || dataObj === undefined || dataObj === null) {
		//$.logger("dataObj is undefined");
		return;
	}
	
	$.each(domainObj, function(i, o) {
		var key = o['key'];
		var domain = o['domain'];
		
		if (domain !== undefined && domain !== null) {
			var tmpData = dataObj;
			
			if ($.isArray(dataObj))
				tmpData = dataObj[0];
			
			if (tmpData[key] !== undefined && tmpData[key] != null) {
				switch (domain) {
					case "Ymd":
					case "Ym":
						tmpData[key] = removeChar(tmpData[key], ".");
						break;
					case "IdNo":
						tmpData[key] = removeChar(tmpData[key], "-");
						break;
					case "Number":
						tmpData[key] = removeChar(tmpData[key], ",");
						break;
				}
			}
		}
	});
}

/**
 * 그리드(html)에서의 데이터 검증 메소드
 * 
 * @param validObj :
 *            {"test1" : {"mandatory" : "true","minLength" : "3","maxLength" : "10"}, "test2" : {"mandatory" : "true","minLength" : "","maxLength" : "10"}} 구조
 * @param value : 특정 그리드를 찾기 위한 selector(dataProvider명 기입) or 데이터객체
 *            
 */

function validation(validObj, selector) {
	var isValidated = true;
	
	if (validObj !== undefined && validObj !== null) {
		$.each(validObj, function(key1, value1) {
			var labelValue = null;
			var validationMsg = null;
			var keyObj = $("div[dataProvider='" + selector + "']>table>tbody>tr>td>[name='" + key1 + "']");
			if (keyObj[0] === undefined || keyObj[0] === null)
				return true;
			
			var thisIdx = keyObj.parent().index();
			
			if (thisIdx > 0) {
				var arr = keyObj.parent().parent().children();
				labelValue = $(arr[thisIdx - 1]).children('label').text()
			}
			
			if (labelValue == null || labelValue == "")
				labelValue = key1;
			
			var fieldValue = getFieldValue(keyObj);
			
			$.each(value1, function(key2, value2) {
				if (key2 == "mandatory" && value2 == "true") {
					if (fieldValue === undefined || fieldValue === null || fieldValue === "") {
						validationMsg = labelValue + "은(는) 필수입니다.";
						return isValidated = false;
					}
				}
				
				if (key2 == "minLength" && value2 !== null && value2 !== "") {
					if (fieldValue !== undefined && fieldValue !== null) {
						var valueLength = fieldValue.length;
						if (valueLength < value2) {
							validationMsg = labelValue + "의 길이는 " + value2 + "자리 이상이어야 합니다.";
							
							return isValidated = false;
						}
					}
				}
				
				if (key2 == "maxLength" && value2 !== null && value2 !== "") {
					if (fieldValue !== undefined && fieldValue !== null) {
						var valueLength = fieldValue.length;
						if (valueLength > value2) {
							validationMsg = labelValue + "의 길이는 " + value2 + "자리를 초과할수 없습니다.";
							
							return isValidated = false;
						}
					}
				}
				
				if (key2 == "dateComparison" && value2 !== null && value2 !== "" && $.isArray(value2)) {
					var staYmdSelector = value2[0], endYmdSelector = value2[1];
					
					validationMsg = dateComparison($(staYmdSelector).val(), $(endYmdSelector).val())
					if(validationMsg != null && validationMsg != "")
						return isValidated = false;
				}
			});
			
			if (!isValidated) {
				alert(validationMsg);
				
				keyObj.focus();
				return isValidated;
			}
		});
	}
	
	return isValidated;
}

function getFieldValue(fieldObj) {
	var returnVal = null;
	
	if (fieldObj !== undefined && fieldObj !== null) {
		var objTagName = fieldObj.prop("tagName");
		
		if (objTagName == "INPUT") {
			var objType = fieldObj.attr("type");
			
			switch (objType) {
				case "radio":
					fieldObj.each(function(i, e) {
						if ($(e).attr("checked") == "checked") {
							returnVal = $(e).val();
						}
					});
					break;
				default:
					returnVal = fieldObj.val();
					break;
				
			}
		} else if (objTagName == "SELECT") {
			returnVal = fieldObj.val();
		} else if (objTagName == "TEXTAREA") {
			returnVal = fieldObj.val();
		}
	}
	
	return returnVal;
}

var _progressActionType = null;
function progressBarHandler(_type, _actionType, _url, _dataObject, _resultHandler, _faultHandler) {
	$.logger("progressBarHandler > " + _type + " >> " + _actionType + " >>> " + _progressActionType + " >>>> " + top.$("#progressbar").length);
	
	switch (_type) {
		case "start":

			if (_progressActionType == null) {
				var progressHeight = top.$("body").height() / 2 - 57;
				var progressWidth = top.$("body").width() / 2 - 195;
				
				var style = "width:390px; height: 114px; background-image: url(/common/img/loding_ani.gif); position: absolute; top:"  + progressHeight + "px; left:" + progressWidth + "px; z-index: 999999999;";
				top.$("body").append("<div id='progressbar' style='" + style + "' name='" + _actionType + "'></div>");
			}
			
			_progressActionType = _actionType;
			//execute1(_actionType, _url, _dataObject, _resultHandler, _faultHandler);
			break;
		case "end":
			if (_progressActionType == _actionType) {
				$.logger("end GOGO");
				
				top.$("#progressbar").remove();
				_progressActionType = null;
			}
			break;
	}
	try {
		
	} catch (e) {
		// TODO: handle exception
	} 
	
}

function execute(_actionType, _url, _dataObject, _resultHandler, _faultHandler, useTimer) {
	$.logger("useTimer >> " + useTimer);
	if(useTimer === undefined || useTimer === null)
		useTimer = true;
	
	//$.logger("execute");
	progressBarHandler("start", _actionType, _url, _dataObject, _resultHandler, _faultHandler);
	
	
	if(useTimer) {
		setTimeout(function() {
			execute1(_actionType, _url, _dataObject, _resultHandler, _faultHandler);
		}, 5);
	}
	else {
		execute1(_actionType, _url, _dataObject, _resultHandler, _faultHandler);
	}
	
}

// 크로스 도메인 문제를 해결하기 위한 변수
var _exeForms = {};

// 실행을 위한 폼을 생성하여 반환함.
function submitExeForm(_actionType, _url, _dataObject ,_resultHandler, _faultHandler){
	var exeFormData = {};
	exeFormData.actionType =_actionType;
	exeFormData.resultHandler =_resultHandler;
	exeFormData.faultHandler =_faultHandler;
	
	_exeForms[_actionType] = exeFormData;
	
	if (_url == null)
		_url = "/serviceBroker.h5";
	
	var formName = "exeForm"+_actionType;
	var iFrameName = "_if"+_actionType;
	var oForm = $("#"+formName);
	var iFrame = $("#"+iFrameName);
	
	if (oForm[0] !== null && oForm[0] !== undefined) {
		$("#"+formName).remove();
	}
	if (iFrame[0] !== null && iFrame[0] !== undefined) {
		$("#"+iFrameName).remove();
	}
	
	//alert(_actionType);
	$("body").append("<iframe name='"+iFrameName+"' id='"+iFrameName+"' width='0' height='0' />").append("<form method='POST' target='" + iFrameName + "' action='"+"/serviceBroker.h5"+"' id='"+formName+"'><input type='hidden' name='request_message'></form>");
	oForm = $("#"+formName);
	//console.log(form[formName]);
	//console.log(oForm.find("[name='request_message']"));
	$(oForm.find("[name='request_message']")).val(JSON.stringify(_dataObject));
	
	//alert($(oForm.find("[name='request_message']")).val());
//	request_message.value = JSON.stringify(_dataObject);
	
	//alert(oForm.request_message);
//	$("##request_message").val(JSON.stringify(_dataObject));
	//$("#"+iFrameName+" #request_message").val(JSON.stringify(_dataObject));
	oForm.submit();
}

/**
 * 서비스 실행
 * 
 * @param _actionType
 * @param _url
 * @param _dataObject
 * @param _resultHandler
 * @param _faultHandler
 * @return
 */
function execute1(_actionType, _url, _dataObject, _resultHandler, _faultHandler) {
	//$.logger("execute1");
	var _serviceBroker = "/serviceBroker.h5";
	if (_actionType == undefined || _actionType == null) {
		alert("ERROR :\tactionType is null");
	}
	
	if (_url == undefined || _url == null) {
		alert("ERROR :\turl is null");
	}
	
	if (_dataObject != undefined && _dataObject != null) {
		_dataObject['HEADER']['serviceId'] = _url;
		_dataObject['HEADER']['actionType'] = _actionType;
		if(typeof(getLocaleCode) === 'undefined')
			_dataObject['HEADER']['localeCd'] = "KO";
		else
			_dataObject['HEADER']['localeCd'] = getLocaleCode();
	}
	
	if (_url.indexOf(".json") > -1)
		_serviceBroker = _url;

	if(location.protocol === 'https:'){
		submitExeForm(_actionType, "/serviceBroker.h5", _dataObject ,_resultHandler, _faultHandler);
		
	}else{
	
		$.ajax({
			type : "post",
			dataType : "json",
			data : JSON.stringify(_dataObject),
			contentType : "application/json; charset=utf-8",
			url : _serviceBroker,
			// url: _url,
			async : false,
			success : function(_response, _status, _error) {
				_successHandler(_response, _status, _error, _resultHandler, _faultHandler);
			},
			error : _errorHandler
		});
	}
}

function _successHandler(_response, _status, _error, _resultHandler, _faultHandler) {
	//$.logger("_successHandler");
	var _info = _response["HEADER"];
	var _data = _response["BODY"];
	var _actionType = _info["actionType"];
	var _resultType = _info["resultType"];
	var _resultMessage = _info["resultMessage"];
	
	//$.logger(' _resultType : '+ _resultType);
	//$.logger(' _resultHandler : '+ _resultHandler);
	try {
		if (_resultType == "SUCCESS" && _resultHandler) {
			//$.logger(' _data : '+ _data);
			//$.logger(' _resultMessage : '+ _resultMessage);
			_resultHandler(_actionType, _data, _resultMessage);
		} else if (_resultType == "SESSION_LOG_OUT") {
			alert(_resultMessage);
			top.location = "/logout.jsp";
		} else if (_resultType == "ERROR" && _faultHandler) {
			_faultHandler(_actionType, _data, _resultMessage);
		} else {
			//$.logger("결과가 뭔지 모르믄 안되지 않을까?");
		}
	} catch (e) {
		$.logger(e);
		progressBarHandler("end", _actionType);
	}
	//$.logger("_successHandler end" + _actionType);
	progressBarHandler("end", _actionType);
}

function _errorHandler(_response, _status, _error) {
	//progressBarHandler("end", _actionType);
	//console.log(_response);
	//console.log(_status);
	alert("ERROR :\t" + _error);
}

function objectToString(obj, valueFilter) {
	if (obj != null && obj != undefined) {
		for ( var objI in obj) {
			if (obj[objI].length > 0)
				objectToString(obj[objI], valueFilter);
			else {
				if (valueFilter == null || valueFilter == undefined)
					$.logger("\t" + objI + " :: " + obj[objI]);
				else {
					if (obj[objI].indexOf(valueFilter) > -1) {
						$.logger("\t" + objI + " :: " + obj[objI]);
					}
				}
			}
		}
	}
}

var _companyCd;
var _sessionId;

/**
 * 오브젝트를 지정된 target에 연다.
 * 
 * @companyCd 인사영역 코드
 * @param objectId
 *            열려고 하는 오브젝트의 등록 ID
 * @param target
 *            오브젝트를 여는 타깃
 * @param initValue
 *            오브젝트 초기화 파라미터 (JSON 타입으로 {key:value, key:value} 의 형식으로 전달한다. )
 * @param isPopup
 *            팝업으로 구동된 것인지를 표기 (true/false)
 * @return
 */
function openObject(objectId, target1, initValue, isPopup) {
	 //TODO: (HYS) 2013-11-22 크로닉스 오버랩2
	if($.isFunction(top.setObjectStack))
		top.setObjectStack(objectId);
	
	//$.logger('!OpenObject!:' + objectId);
	//$.logger('!OpenObject!target:' + target1);
	var localeCd = "KO";
	
	if(typeof(getLocaleCode) === "function")
		localeCd = getLocaleCode();
	
	var objectRequestMessage = {
		"HEADER" : {
			"companyCd" : _companyCd,
			"serviceId" : "FRM_OPEN_OBJECT_THIN",
			"sessionId" : _sessionId,
			"localeCd" : localeCd
		},
		"BODY" : {
			"ME_OBJECT_REQUEST" : [ {
				"objectId" : objectId,
				"param" : "",
				"date" : "",
				"isPopup" : isPopup
			} ]
		}
	};
	
	if(top.useDebugBtn && top.useDebugMode)
		objectRequestMessage.PARAM = {"useDebugMode" : "true"};
	
	if (initValue !== null && initValue !== undefined) {
		if(!objectRequestMessage.PARAM)
			objectRequestMessage.PARAM = {};
		
		$.extend(true, objectRequestMessage.PARAM, initValue);
	}
	
	var oForm = $("#tyForm");
	
	if (oForm[0] !== null && oForm[0] !== undefined) {
		$("#tyForm").remove();
	}
	
	$("body").append("<form method='POST' target='" + target1 + "' action='/serviceBroker.h5' id='tyForm'><input type='hidden' id='request_message' name='request_message'></form>");
	oForm = $("#tyForm");
	
	$('#request_message').val(JSON.stringify(objectRequestMessage));
	oForm.submit();
	
	// tyForm.request_message.value = JSON.stringify(objectRequestMessage);
	// tyForm.submit();
	
}

/**
 * 오브젝트를 팝업으로 연다.
 * 
 * 
 * @param objectId
 *            열려고 하는 오브젝트의 등록 ID
 * @param actionType
 *            액션타입. doAction에서 사용하는 값과 같다
 * @param initValue
 *            오브젝트 초기화 파라미터 (JSON 타입으로)
 * @param isModal
 *            모달 윈도우 형식으로 열 경우 true (기술되지 않을 경우 true)
 * @param companyCd
 *            인사영역 코드
 * @param windowName
 *            오브젝트를 여는 윈도우 null 또는 기술되지 않을 경우 새로운 윈도우에 연다.
 * @param dataApplyEventListener
 *            윈도우가 데이터를 적용하려고 할 때 바인딩 하는 이벤트 리스너(함수) 파라미터로 actionType, eventData를 갖는다.
 * 
 * @return
 */
var _currentDialog = null; // 현재 열려있는 다이얼로그 initValue << 확장 2013-03-27
function popUpObject(objectId, actionType, initValue, isModal, companyCd, windowName, dataApplyEventListener, sourcePage) {
	// 먼저 다이얼로그 id와 ifarme이름을 만든다. 준 값이 없으면 임의로 objectId를 이용하여 만든다.
	var dialogId = null;
	var frameName = null;
	
	if (windowName && windowName !== null)
		dialogId = windowName;
	else
		dialogId = 'dlg_' + objectId + "__" + actionType;
	;
	
	frameName = 'frame_' + dialogId;
	
	var _dialogObject = $('#' + dialogId);
	
	// 다이얼로그가 도큐먼트 내에 없으면 하나 만든다
	
	if (_dialogObject === undefined || _dialogObject === null || _dialogObject[0] === undefined || _dialogObject[0] === null) {
		$('body').append("<div id='" + dialogId + "' class='ui-dialog'><iframe id='" + frameName + "' name='" + frameName + "' src='' width='100%' height='100%' frameborder='0'></iframe></div>");
		_dialogObject = $('#' + dialogId);
		
		// _dialogObject.bind("applydata",dataApplyEventListener);
		
		// else
		// _dialogObject.bind("applydata",function(eventData){
		// alert('a');
		// });
	}
	// 다이얼로그를 하나 가져와서 준비.
	_dialogObject['actionType'] = actionType;
	if(sourcePage !== undefined && sourcePage !== null)
		_dialogObject['parentPage'] = sourcePage;
	else
		_dialogObject['parentPage'] = this;
	
	var widthValue = null;
	var heightValue = null;
	var windowName = "";
	
	
	var requestObject = {
			"HEADER" : {  "companyCd": _companyCd, "sessionId": _sessionId, "serviceId": "FRM_OBJECT_PROPERTY", "actionType": "objectSearch" },
			"BODY" : {
				"ME_FRM_OBJECT_CONDITION" : [ {
					  "company_cd" : _companyCd
					, "object_id" : objectId
				} ]
			}
		};
	
	execute("objectSearch", "FRM_OBJECT_PROPERTY", requestObject, function(aType, obj) {
		var data = obj["ME_FRM_OBJECT_PROPERTY"];
		
		if(data.length > 0){
			widthValue = Number(data[0]['width']);
			heightValue = Number(data[0]['height']);
			windowName = data[0]['title'];
		}
		
		//$.logger("open popup //" + widthValue + "//" + heightValue + "//" + windowName);
		var boolModal = true;
		
		if (isModal !== undefined && isModal !== null)
			boolModal = isModal;
		
		if($.isFunction(top.getRexPage) && top.getRexPage() !== undefined && top.getRexPage() !== null) {
			top.getRexPage().document.getElementById('ifrmRexPreview1').contentWindow.document.body.style.display = "none";
		}
		
		//TODO: (HYS) 2013-11-04 크로닉스 오버랩
		/*
		if($.isFunction(top.getCrownixPage) && top.getCrownixPage() !== undefined && top.getCrownixPage() !== null) {
			var obj = top.getCrownixPage();
			obj.page.document.getElementById(obj.targetFrame).contentWindow.document.body.style.display = "none";
		}
		*/
		
		//TODO: (HYS) 2013-11-22 크로닉스 오버랩2
		if(_dialogObject.parentPage._objectInfo) {
			
			if ( top.getObjectStack ){
			
				var objInfo = top.getObjectStack(_dialogObject.parentPage._objectInfo.objectId);
				if(objInfo !== undefined && objInfo !== null) {
					var crownixInfo = objInfo.crownixInfo;
					if(crownixInfo !== undefined) {
						crownixInfo.page.document.getElementById(crownixInfo.targetFrame).contentWindow.document.body.style.display = "none";
					}
				}
			
			}
		}
		
		/*
		if(sourcePage !== undefined && sourcePage.document.getElementById('ifrmRexPreview1') !== undefined && sourcePage.document.getElementById('ifrmRexPreview1') !== null) {
			sourcePage.document.getElementById('ifrmRexPreview1').style.display = "none";
		}
		*/
		
		
		
		var default_option ={
			modal : boolModal,
			autoOpen : false,
			zIndex : -2,
			width : widthValue,
			height : heightValue,
			title : windowName,
			resizable : false,
			position : 'center',
			draggable : true
		};
		
		var bindObj ={}; //넘겨줄 데이터 option을 빼고 넘기기 위한 변수 
	
		if(initValue===null || initValue['dialog_options'] === null || initValue['dialog_options'] === undefined){ //dialog의 옵션을 줄 수 있게 옵션화 하였음.
			bindObj = initValue;
		}else{ //일반적으로 옵션을 주지 않을 경우 
			if(initValue['dialog_options']){ //옵션이 있을경우 체인지
				$.extend(default_option,initValue['dialog_options']);
			}
			bindObj = initValue['initValue'];
		}
		
		
		_dialogObject.dialog(default_option);
		//alert(heightValue);
		
		/*if ( $.browser.msie ) {
			_dialogObject.dialog("option", "width", widthValue+'px');
			_dialogObject.dialog("option", "height", heightValue+'px');
			
		}*/
		_dialogObject.unbind("dialogclose");
		_dialogObject.bind("dialogclose", function(e, ui) {
			
			//$.logger("dialogClose >>" + e.actionType + " : " + actionType + " :: " + $(this).dialog('isOpen'));
			
			if (e.actionType !== undefined && dataApplyEventListener !== undefined && dataApplyEventListener !== null && $.isFunction(dataApplyEventListener)) {
				dataApplyEventListener(e.actionType, e.sendingData);
			}
			
			if($.isFunction(top.getRexPage) && top.getRexPage() !== undefined && top.getRexPage() !== null) {
				top.getRexPage().document.getElementById('ifrmRexPreview1').contentWindow.document.body.style.display = "";
			}
			
			//TODO: (HYS) 2013-11-04 크로닉스 오버랩
			/*
			if($.isFunction(top.getCrownixPage) && top.getCrownixPage() !== undefined && top.getCrownixPage() !== null) {
				var obj = top.getCrownixPage();
				obj.page.document.getElementById(obj.targetFrame).contentWindow.document.body.style.display = "";
			}
			*/
			//TODO: (HYS) 2013-11-22 크로닉스 오버랩2
			if(_dialogObject.parentPage._objectInfo) {
				
				if ( top.getObjectStack ){
					var objInfo = top.getObjectStack(_dialogObject.parentPage._objectInfo.objectId);
					if(objInfo !== undefined && objInfo !== null) {
						var crownixInfo = objInfo.crownixInfo;
						if(crownixInfo !== undefined) {
							crownixInfo.page.document.getElementById(crownixInfo.targetFrame).contentWindow.document.body.style.display = "";
						}
					}
				}
			}
			if($.isFunction(top.deleteObjectStack))
				top.deleteObjectStack(objectId);
			
//			if(sourcePage !== undefined && sourcePage.document.getElementById('ifrmRexPreview1') !== undefined && sourcePage.document.getElementById('ifrmRexPreview1') !== null) {
//				sourcePage.document.getElementById('ifrmRexPreview1').style.display = "";
//			}

			if ($(this).dialog('isOpen')) {
				$(this).dialog('close');
			} else {
				$(this).dialog('destroy');
				// 익스7에서는 객체를 지우면 다이얼로그 객체내의 input의 속성 지정이 비정상으로 처리되어 꼼수로 프레임객체의 주소만 바꿈
				$("#" + frameName).attr("src", "");
				$(this).remove();
			}
			/*
			if($(".ui-widget-overlay")[0] !== undefined)
				$(".ui-widget-overlay").remove();
			*/
			
			if(top.$("#progressbar")[0] !== undefined) {
				_progressActionType = null;
				top.$("#progressbar").remove();
			}
			
		});
		
		_currentDialog = _dialogObject;
		
		_dialogObject.dialog('open');
		
		//$("div[role='dialog'").css('visibility', 'hidden');
		
		// 오브젝트를 연다
		openObject(objectId, frameName, bindObj);
	});
}

/**
 * 팝업창의 크기를 조절한다.
 * 
 * @param widthValue
 *            너비 값
 * @param heightValue
 *            높이 값
 * @param windowName
 *            윈도우 이름
 * @return
 */
function resetPopupWindow(widthValue, heightValue, windowName) {	
	if (_currentDialog != undefined && _currentDialog != null) {
		/*
		_currentDialog.dialog({
			width : widthValue,
			height : heightValue,
			title : windowName,
			position : 'center'
		});		
		// _currentDialog.dialog('open');
		$("div[role='dialog'").css('visibility', 'visible');
		*/
		//$.logger("resetPopupWindow **********************");
		//_currentDialog.dialog('open');
		_currentDialog = null;
		
	}
}

(function($) {
	$('script[src *= "/common/jquery/jquery-1.6.2.min.js"]')
		.after('<script type="text/javascript" src="/common/js/json2.js"></script>')
		.after('<script type="text/javascript" src="/common/jquery-plugin/jquery.maskedinput-1.3.js"></script>')
		.after('<script type="text/javascript" src="/common/jquery/jquery-ui.js"></script>')
		//.after('<script type="text/javascript" src="/common/jquery/jquery-ui-1.8.16.custom.min.js"></script>')
		.after('<script type="text/javascript" src="/common/jquery-plugin/jquery.layout-latest.js"></script>')
		.after('<script type="text/javascript" src="/common/jquery-plugin/jquery.dynatree.js"></script>')
		.after('<script type="text/javascript" src="/common/jquery-plugin/jquery.datalink.js"></script>')
		.after('<script type="text/javascript" src="/common/js/commonSearch.js"></script>')
		.after('<script type="text/javascript" src="/common/js/commonSearch2.js"></script>');
})(jQuery);

/**
 * 직원이미지를 교체한다.
 * 
 * @param imageType
 *            이미지 타입 P:사진, S:서명, Q:QR 코드
 * @param emp_image
 *            이미지<img> 태그 오브젝트
 * @param changeButton
 *            이미지 교체를 요청한 오브젝트 (버튼 등)
 * @return
 */
function changeEmpImage(imageType, emp_image, changeButton) {
	if (emp_image) {
		var imageURL = emp_image.src;
		if (imageURL != null && imageURL != '' && imageURL != undefined) {
			imageURL = imageURL.substring(0, imageURL.indexOf("image_type=")) + "image_type=" + imageType + imageURL.substring(imageURL.indexOf("&"));
			emp_image.src = imageURL;
		}
	}
	// if(changeButton && changeButton != undefined){
	// changeButton
	// }
}

/**
 * 그리드의 컬럼값을 가져온다.
 * 
 * @param containerId
 *            컨테이너 ID
 * @param columnName
 *            컬럼 명
 * @returns
 */
function getGridColumnValue(containerId, columnName) {
	return $('#' + containerId).triggerHandler('getRowData')[columnName];
}

/**
 * 데이터그리드에서 선택된 로우의 컬럼값을 가져온다
 * 
 * @param containerId
 *            컨테이너 ID
 * @param columnName
 *            컬럼 명
 * @returns
 */
function getDataGridColumnValue(containerId, columnName) {
	return getGridColumnValue("DIV_" + containerId, columnName);
}

/**
 * 트리에서 선택된 로우의 컬럼값을 가져온다
 * 
 * @param containerId
 *            컨테이너 ID
 * @param columnName
 *            컬럼 명
 * @returns
 */
function getTreeColumnValue(containerId, columnName) {
	return getGridColumnValue(containerId, columnName);
}

// 특정문자를 삭제한 값을 리턴
function removeChar(srcString, strchar) {
	var convString = '';
	if(srcString != null){
		for (z = 0; z < srcString.length; z++) {
			if (srcString.charAt(z) != strchar)
				convString = convString + srcString.charAt(z);
		}
	}
	return convString;
}

/**
 * 레포트를 호출한다
 * 
 * @param fileNm
 *            레포트파일(절대경로포함, 확장자 제외)
 * @param param
 *            레포트 파일에서 사용할 param
 * @param openType
 *            레포트 오픈형식(1:iframe open,2:popup open,3:direct print)
 * @param targetId
 *            openType이 1일때 iframe이 들어갈 타겟아이디
 * @param viewBtn
 *            viewer 버튼제어("open,save,refresh,savexls,savepdf,savehwp") open:열기,save:저장,refresh:갱신,savexls:엑셀저장,savepdf:pdf저장,savehwp:한글저장
 * @param printBtn
 * 			  Y/N 출력물을 조회용으로만 사용할때 출력버튼을 감추기
 * @param sheetoption
 * 			  엑셀다운로드시 sheet분리여부
 * @return
 */
function reportOpen(fileNm, param, openType, targetId, viewBtn, printBtn, sheetoption) {
	if(openType !== undefined && openType !== null && openType !== "" && openType === "1" && (typeof(this.openerObject) === 'undefiend' || typeof(this.openerObject) === 'object') && this.openerObject === null) {
		top.setRexPage(this);
	}
	var i = 1;
	// 필수 - 레포트 생성 객체
	var oReport = GetfnParamSet();
	// 필수 - 레포트 파일명
	oReport.rptname = fileNm;
	// oReport.reb("reb" + i).rptname = fileNm;
	
	$.ajax({
		type : "post",
		dataType : "json",
		data : JSON.stringify(param),
		contentType : "application/json; charset=utf-8",
		url : "/common/js/rexportParam.jsp",
		// url: _url,
		async : false,
		success : function(_response, _status, _error) {
			//$.logger(JSON.stringify(_response));
			// 레포트 파라메터 셋팅
			oReport.params = _response;
			
			if(printBtn === undefined || printBtn === null || printBtn === ""){
				printBtn = "Y";
			}
			
			if(sheetoption === undefined || sheetoption === null || sheetoption === ""){
				sheetoption = "2";
			}
			
			// * event handler call
			// * init = 리포트 뷰어 초기화시점
			// * finishdocument = 리포트 문서의 출력이 완료되는 시점
			// * finishprint = 프린트 종료시점
			// * finishexport = PDF, Excel 등 으로의 export가 완료되는 시점.
			// * 사용하지 않을경우 주석해도 무방함.
			
			// oReport.event.init = fnReportEvent;
			
			oReport.event.init = function(oRexCtl, sEvent, oArgs) {
				var views = null;
				
				oRexCtl.SetCSS("appearance.toolbar.button.open.visible=0"); // 열기
				oRexCtl.SetCSS("appearance.toolbar.button.export.visible=0"); // 저장
				if(printBtn == "N"){
					oRexCtl.SetCSS("appearance.toolbar.button.print.visible=0"); // 출력
				}
				oRexCtl.SetCSS("appearance.toolbar.button.refresh.visible=0"); // 갱신
				oRexCtl.SetCSS("appearance.toolbar.button.exportxls.visible=0"); // 엑셀저장
				oRexCtl.SetCSS("appearance.toolbar.button.exportrtf.visible=0"); // 워드저장
				oRexCtl.SetCSS("appearance.toolbar.button.exportpdf.visible=0"); // PDF저장
				oRexCtl.SetCSS("appearance.toolbar.button.exporthwp.visible=0"); // 한글저장
				oRexCtl.SetCSS("appearance.toolbar.button.about.visible=0"); // 등록정보
				oRexCtl.SetCSS("appearance.toolbar.button.movecontent.visible=0"); // 본문창으로이동
				
				
				/* 엑셀저장 옵션 
				 * 여러시트에 저장 = 0, 한시트에 저장 = 1, 한시트에 연속으로 저장 = 2
				 */
				oRexCtl.SetCSS("appearance.toolbar.button.exportxls.option.sheetoption="+sheetoption);
				
				// 페이지 머릿글 바닥글을 한번만 출력
				oRexCtl.SetCSS("appearance.toolbar.button.exportxls.option.pagesectiononceprint=1");
				
				// 자동 셀 머지
				//oRexCtl.SetCSS("appearance.toolbar.button.exportxls.option.autocellmerge=1");
				// 빈 텍스트 박스 자동 셀 머지
				//oRexCtl.SetCSS("appearance.toolbar.button.exportxls.option.emptytextautocellmerge=1");
				
				if (viewBtn !== undefined && viewBtn !== null && viewBtn !== "") {
					var btnArr = viewBtn.split(",");
					
					for (i = 0; i < btnArr.length; i++) {
						// if(btnArr[i] == "open"){
						// oRexCtl.SetCSS("appearance.toolbar.button.open.visible=1"); // 열기
						// } else if(btnArr[i] == "save"){
						// oRexCtl.SetCSS("appearance.toolbar.button.export.visible=1"); // 저장
						// } else if(btnArr[i] == "refresh"){
						// oRexCtl.SetCSS("appearance.toolbar.button.refresh.visible=1"); // 갱신
						// } else
						if ( btnArr[i] == "save" ){
						 oRexCtl.SetCSS("appearance.toolbar.button.export.visible=1"); // 저장
						} else if (btnArr[i] == "savexls") {
							oRexCtl.SetCSS("appearance.toolbar.button.exportxls.visible=1"); // 엑셀저장
						} else if (btnArr[i] == "savedoc") {
							oRexCtl.SetCSS("appearance.toolbar.button.exportrtf.visible=1"); // 워드저장
						} else if (btnArr[i] == "savepdf") {
							oRexCtl.SetCSS("appearance.toolbar.button.exportpdf.visible=1"); // PDF저장
						} else if (btnArr[i] == "savehwp") {
							oRexCtl.SetCSS("appearance.toolbar.button.exporthwp.visible=1"); // 한글저장
						}
					}
				}
				
				oRexCtl.UpdateCSS(); // 옵션적용
			};
			
			oReport.event.finishdocument = fnReportEvent;
			
			if (openType == "1") {
				if ($('#' + targetId) != undefined && $('#' + targetId) != null) {
					$('#' + targetId).empty();
					var iHeight = ($(window).height() - $('#'+targetId).offset().top) * 100/ 100 - 10;
					$('#' + targetId).append("<iframe name='ifrmRexPreview1' id='ifrmRexPreview1' src='/RexServer30/rexpreview.jsp' width='99%' height='" + iHeight + "px'></iframe>");
					oReport.iframe("ifrmRexPreview1");
					/*
					$('#' + targetId).append(rex_getRexCtl('rexview1','100%', '450'));
					oReport.embed('rexview1');
					*/
				}
			} else if (openType == "2") {
				oReport.open();
			} else {		
				var printCnt = parseInt(targetId);		
				oReport.print(false, 1, -1, printCnt, ""); // 뷰잉 없이 프린터로 즉시출력 (다이얼로그표시유무, 시작페이지, 끝페이지, 카피수, 옵션);
			}
		},
		error : _errorHandler
	});
}

// event handler 뷰어관련 이벤트(Zoom, 버튼제어 등)
function fnReportEvent(oRexCtl, sEvent, oArgs) {
	
	if (sEvent == "init") {
	} else if (sEvent == "finishdocument") {		
		if(typeof(reportEnd) != "undefined"){
			reportEnd();
		}
	} else if (sEvent == "finishprint") {
	} else if (sEvent == "finishexport") {
	}
}
/*--------------------------------------------------------------
 // ibsheet 히든컬럼 제외 다운로드하기
 --------------------------------------------------------------*/
// Hiddencol 을 제외한 컬럼을 스트링 형태로 만들기.
function makeHiddenSkipCol(sobj) {
	var lc = sobj.LastCol();
	var colsArr = new Array();
	for ( var i = 3; i <= lc; i++) {
		if (1 == sobj.GetColHidden(i)) {
			colsArr.push(i);
		}
	}
	var rtnStr = "";
	for ( var i = 3; i <= lc; i++) {
		if (!colsArr.contains(i)) {
			rtnStr += "|" + i
		}
	}
	return rtnStr.substring(1);
}

// javascript contains
Array.prototype.contains = function(element) {
	for ( var i = 0; i < this.length; i++) {
		if (this[i] == element) {
			return true;
		}
	}
	return false;
}

// 특정일자에 개월수를 더한 날짜를 리턴한다.
function addMonth(date, add_month) {
	
	date = removeFmt(date);
	
	// 개월수를 더한 년월을 구한다.
	// alert(date);
	yyyymm = getYyyymm(date.substring(0, 6), add_month);
	dd = date.substring(6, 8);
	
	// 구한 년월의 해당월의 마지막 날짜를 구한다.
	lastday = getLastday(yyyymm.substring(0, 4), yyyymm.substring(4, 6));
	
	if (Number(dd) > Number(lastday))
		dd = lastday;
	
	return (yyyymm + dd);
}

// 특정년월의 마지막 날짜를 구한다.
function getLastday(yyyy, mm) {
	
	if (mm.length == 2) {
		if (mm.substring(0, 1) == '0')
			mm = mm.substring(1, 2);
	}
	
	switch (Number(mm)) {
		case 2:
			intDay = (!(yyyy % 4) && (yyyy % 100) || !(yyyy % 400)) ? 29 : 28;
			break;
		case 4:
		case 6:
		case 9:
		case 11:
			intDay = 30;
			break;
		default:
			intDay = 31;
	}
	
	return intDay;
}

// FORMAT 문자 전체삭제
function removeFmt(str) {
	result = removeChar(str, '.');
	result = removeChar(result, '-');
	result = removeChar(result, ',');
	result = removeChar(result, '/');
	
	return result;
}

// 특정년월에 개월수를 더한 년월을 구한다.
function getYyyymm(yyyymm, add_month) {
	
	var yyyy = yyyymm.substring(0, 4);
	var mm = yyyymm.substring(4, 6);
	
	var total_month = (parseFloat(yyyy) - 1) * 12 + parseFloat(mm);
	total_month = total_month + Number(add_month);
	
	var yyyy2 = parseInt(total_month / 12) + 1;
	var mm2 = Number(total_month % 12);
	
	if (mm2 == 0) {
		yyyy2 = yyyy2 - 1;
		mm2 = 12;
	}
	s_yyyy2 = "" + yyyy2 + '';
	s_mm2 = "" + mm2 + '';
	
	if (s_mm2.length == 1)
		s_mm2 = "0" + s_mm2;
	return (s_yyyy2 + "" + s_mm2);
}

function dateComparison(_staYmdValue, _endYmdValue) {
	var staYmd = removeChar(_staYmdValue, '.');
	var endYmd = removeChar(_endYmdValue, '.');
	
	if((staYmd === null || staYmd === "") && (endYmd === null || endYmd === ""))
		return null;
	
	var tmp = dateValidation(staYmd);
	
	if(tmp != null)
		return "시작일이 " + tmp;
	
	tmp = dateValidation(endYmd);

	if(tmp != null)
		return "종료일이 " + tmp;
	
	if (staYmd > endYmd) {
		return "시작일이 종료일보다 큽니다.";
	}
	
	return null;
}

function dateValidation(value) {
	var _year = value.substring(0,4);
	var _month = value.substring(4,6);
	var _day = value.substring(6);
	var _isValid = true;
	
	if(_year <= 0) {
		_isValid = false;
	}
	
	if(_month > 12 || _month <= 0) {
		_isValid = false;
	}
	var getValidDay = function (value) {
		switch(value) {
			case "02":
				return (!(_year % 4) && (_year % 100) || !(_year % 400)) ? 29 : 28;
				break;
			case "01": case "03": case "05": case "07": case "08": case "10": case "12":
				return 31;
				break;
			default:
				return 30;
				break;
		}
	};
	
	if(_day != "") {
		if(_day < 0 || getValidDay(_month) < _day) {
			_isValid = false;
		}
			
	}
	
	if(_isValid)
		return null;
	else
		return "올바른 날짜가 아닙니다.";
}

function createIssueIcon(objectOid, objectId, objectNm, objectLink) {
	var that = this; // TODO: (HYS) 2013-11-27 26일자 패치 후 오브젝트 정보(i 아이콘)의 기능이 안돌던 현상 해결
	var img = $("<img id='issueImg' src='/common/img/main/icon_help.png' style='cursor: pointer; position: absolute; top: 5px; left: 5px;'></img>").click(function(e) {
		img.hide();

		top.popUpObject('FRM_OBJ_INFO',objectId,{"object_oid":objectOid, "object_id":objectId, "object_nm":objectNm, "object_link":objectLink, "useDebugMode":"false"},false,getCompanyCd(),null,function(actionType,resultData,alertMsg) {
			img.show();
		}, that); // TODO: (HYS) 2013-11-27 26일자 패치 후 오브젝트 정보(i 아이콘)의 기능이 안돌던 현상 해결
	});
	//$("body").append(img);
} 


/**
 * 크로닉스(RD) 오픈
 * @param targetFrameNm : 오픈할 IFrame Name
 * @param reportPath : 레포트 파일 경로 ex) /test/test.mrd
 * @param paramData : 레포트 오픈시 전송할 파라미터 json object
 * @param windowWidth : 팝업으로 띄울시 windth
 * @param windowHeight : 팝업으로 띄울시 height
 * @param reportOption : 레포트 구동시의 옵션값 json object ({})
 */
function openRD(targetFrameNm, reportPath, paramData , windowWidth , windowHeight, reportOption, afterEvent) {
	if ( targetFrameNm !== undefined && targetFrameNm !== null && targetFrameNm !== "null" && targetFrameNm !== "" ) {
		//TODO: (HYS) 2013-11-22 크로닉스 오버랩2
		
		try{
			
			if( _objectInfo ) {
				
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
		}catch(e){
			
			
		}
	}
	
	var paramMode = "KEY_NAME";
	//var paramMode = "SEQUENCE";
	//TODO: (HYS) 2013-11-25 레포트로 전송되는 파라미터 바인딩 구조 설정
	if(reportOption !== undefined && reportOption != null && reportOption.paramMode !== undefined && reportOption.paramMode !== null && (reportOption.paramMode === "KEY_NAME" || reportOption.paramMode === "SEQUENCE")) {
		paramMode = reportOption.paramMode;
	}
	
	var reportForm = $("form#reportForm");
	
	var isPopup = "N";
	
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
		
		isPopup = "Y";
		
		var openWindowStyle = 'top='+ t_ypos +',left='+ t_xpos +',width=' + openWindowWidth + ',height=' + openWindowHeight;
		
		window.open("/common/web/null.html" , "__crownix_rd_popup" ,openWindowStyle);
		
		if(reportForm.length === 0) {
			reportForm = $("<form>").attr({
				"id" : "reportForm",
				"target" : "__crownix_rd_popup",
				"method" : "POST",
				"action" : "/common/web/crownix_open.jsp"
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
				"action" : "/common/web/crownix_open.jsp"
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
			"id" : "isPopup",
			"name" : "isPopup",
			"type" : "hidden",
			"value" : isPopup
		}));
		
		reportForm.append($("<input>").attr({
			"id" : "reportOption",
			"name" : "reportOption",
			"type" : "hidden",
			"value" : JSON.stringify(reportOption)
		}));
		
		reportForm.append($("<input>").attr({
			"id" : "afterEvent",
			"name" : "afterEvent",
			"type" : "hidden",
			"value" : JSON.stringify(afterEvent)
		}));
	}
	
	reportForm.submit();
}