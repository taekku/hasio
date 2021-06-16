/**
 * 전자결재 상태 변수
 */
// 최초 신청인지를 판별하는 변수
var isNew = false;
// 신청서 상태 정보 추가
var _applStatusCd = null;
// message정보
var _statusName = 'init';
// 버튼클릭시 호출될 서비스 명
var serviceNameB = '';
// 전자결재 의견작성용 index
var clickIndex = 0;

function setStatusName(actionType) {
	_statusName = actionType;
}
function getStatusName() {
	return _statusName;
}
function setIsNew(boolValue) {
	isNew = boolValue;
}
function getIsNew() {
	return isNew;
}
function setApplStatusCd(statusCd) {
	_applStatusCd = statusCd;
}
function getApplStatusCd() {
	return _applStatusCd;
}
/**
 * 전자결재 기능 수행부
 */
function doElaAction(actionType, paramValue) {
	// 업무용 전처리 추가 이효정(2012.04.05)
	if ((typeof applBefore) != "undefined") {
		if (!applBefore(actionType, paramValue))
			return;
	}

	if (actionType == 'composeApprovalLine') {
		var initValue = null;

		initValue = {
			"appl_cd": getApplCd(),
			"isnew": getIsNew(),
			"appl_status_cd": getApplStatusCd()
		};

		top.popUpObject('ELA9000_52', actionType, initValue, true, getCompanyCd(), '', doElaResult, this);

		return;
	}
	
	if (actionType == 'temporarySave') {

		serviceNameB = actionType + "@ELA0010_SAVE_02";
		if (!confirm(__ELA0010_SAVE_02)) {
			return;
		} else {
			if ((typeof applAfter) != "undefined") {	//컨펌 메세지 이후에 이벤트를 태우기 위해서
				if (!applAfter(actionType, paramValue))
					return;
			}
		}
	}

	if (actionType == 'requestApproval') { //기안
		serviceNameB = actionType + "@ELA0010_SAVE_01";

		if (!confirm(__ELA0010_SAVE_01)) {
			return;
		} else {
			if ((typeof applAfter) != "undefined") {	//컨펌 메세지 이후에 이벤트를 태우기 위해서
				if (!applAfter(actionType, paramValue))
					return;
			}
		}
		
		//2021.05.05 상진 : 신청 시는 의견을 남길 필요가 없다는 요청을 받아 주석 처리 함
		//if (useViewComment == "Y") {
		//	editComment(currentWorkIndex);
		//}
	}
	
	if (actionType == 'cancel') {

		if (!confirm(__ELA0010_SAVE_05))
			return;

		serviceNameB = actionType + "@ELA0010_SAVE_05";
	}
	
	if (actionType == 'cancelRequest') {
		
		if (!confirm(__ELA0010_SAVE_05))
			return;
		
		serviceNameB = actionType + "@ELA0010_SAVE_13";
	}

	if (actionType == 'approve') {
		serviceNameB = actionType + "@ELA0010_SAVE_03";

		if (!confirm(__ELA0010_SAVE_03))
			return;

		if (useViewComment == "Y") {
			//여기서 현재 의견보기가 입력되어야 할 index를 알아야함 
			editComment(currentWorkIndex);
			return;
		}
	}
	
	if (actionType == 'return') {
		serviceNameB = actionType + "@ELA0010_SAVE_04";

		if (!confirm(__ELA0010_SAVE_04))
			return;
		
		if (useDenyComment == "Y") {
			editComment(currentWorkIndex);
			return;
		}
	}

	if (actionType == 'elaDelete') {
		serviceNameB = actionType + "@ELA0010_SAVE_06";

		if (!confirm(__CONFIRM_APPR_DEL))
			return;
	}

	if (actionType == 'reapply') {
		serviceNameB = actionType + "@ELA0010_SAVE_07";

		if (!confirm(__ELA0010_SAVE_07))
			return;
	}

	if (actionType == 'agree') {
		serviceNameB = actionType + "@ELA0010_SAVE_08";
		setStatusName(actionType);

		if (!confirm(__ELA0010_SAVE_08)) {
			return;
		}

		if (useViewComment == "Y") {
			editComment(currentWorkIndex);
			return;
		}
	}

	if (actionType == 'parallel') {
		serviceNameB = actionType + "@ELA0010_SAVE_11";

		if (!confirm(__ELA0010_SAVE_03))
			return;

		if (useViewComment == "Y") {
			editComment(currentWorkIndex);
			return;
		}
	}

	// 2020.10.20 상진 - 동원 회람 추가
	if (actionType == 'circular') {
		var initValue = null;

		initValue = {
			"appl_id": getApplId(),
			"appl_cd": getApplCd(),
			"appl_status_cd": getApplStatusCd(),
			"emp_id": "${sessionScope.session_emp_id}"
		};
		
		top.popUpObject('ELA1000', actionType, initValue, true, getCompanyCd(), '', null, this);

		return;
	}
	
	// 2020.10.20 상진 - 동원 열람 추가
	if (actionType == 'peruse') {
		var initValue = null;

		initValue = {
			"appl_id": getApplId(),
			"appl_cd": getApplCd(),
			"appl_status_cd": getApplStatusCd(),
			"emp_id": "${sessionScope.session_emp_id}"
		};

		top.popUpObject('ELA2001', actionType, initValue, true, getCompanyCd(), '', null, this);

		return;
	}
	
	// 2020.10.30 상진 - 동원 문서연결 추가
	if (actionType == 'documentConnection') {
		var initValue = {
				"appl_id": getApplId(),
				"appl_cd": getApplCd(),
				"appl_status_cd": getApplStatusCd(),
				"emp_id": "${sessionScope.session_emp_id}"
			};

		top.popUpObject('ELA3000', actionType, initValue, true, getCompanyCd(), '', function(e){
			var requestObject = {
				"HEADER": headerObject,
				"BODY": {
					"ME_ELA0001_01": [{
						"appl_id": getApplId()
					}]
				}
			};
			
			execute("elaConnDocSaveAfter", "ELA0001_00_R03", requestObject, drawElaConnDoc,
				function(actionType, obj) {
					alert("연결문서 조회 중 오류 발생!");
					return;
				}, false
			);
		}
		, this);

		return;
	}

	doElaAction2();

}

function doElaAction2() {
	var tempArr = serviceNameB.split("@");

	var actionType = tempArr[0];
	var serviceName = tempArr[1];

	var initData = {};
	var errMsg = {};
	var saveDataDetected = true;

	for (var id in bindingObject) {
		/**
		 * 변경된 자원을 바인딩 메시지에 다시 담기.
		 */
		bindingObject[id] = $("div[dataProvider='" + id + "']").triggerHandler("getData", [errMsg]);

		var valiObj = this["validatorObject_" + id];

		if (valiObj !== undefined) {
			if (!validation(valiObj, id)) {
				return saveDataDetected = false;
			}
		}

		if (errMsg['msg'] !== undefined && errMsg['msg'] !== null && errMsg['msg'] === 'KeyFieldError') {
			return saveDataDetected = false;
		}

		initData[id] = bindingObject[id];
	}

	if (saveDataDetected) {
		initData['ME_ELA_REQUEST'] = getElaRequestMessage();
		initData['ME_FRM_BIZ_WORK'] = getApprLineMessage();

		initData['ME_ELA_REQUEST'][0]['actionType'] = actionType;
		
		var requestObject = {
			"HEADER": headerObject,
			"BODY": initData
		};
		
		execute(actionType, serviceName, requestObject, doElaResult, doElaFault, false);
	}
}

/**
 * 전자결재 결과 처리부
 */
function doElaResult(actionType, resultValue) {
	if (actionType == 'requestApproval' || actionType == "temporarySave" || actionType == "cancel" || actionType == "reapply") {
		if (openerObject !== null) { // 팝업일때
			if (actionType == "reapply") {
				alert(__ELA0010_SAVE_071);
			}

			var evt = jQuery.Event('dialogclose');
			evt.actionType = openerObject['actionType'];
			openerObject.trigger(evt);

		} else {
			// 프로그래스바 죽이고 페이지 전환하자
			progressBarHandler('end', actionType);
			var menuId = top.getCurrentMenuId();
			var param = {
				"appl_cd": getApplCd()
			};

			top.openMenu('ELA0010_51', 'ELA0010_51', __PVT_E_ELA0010, param);
			setTimeout(function() {
				top.closeMenu(menuId, false);
			}, 400);
		}
	}

	if (actionType == 'composeApprovalLine') {
		if (resultValue !== undefined && resultValue !== null && resultValue.length > 0) {
			applyElaLine(resultValue);
		}

	}

	if (actionType == 'approve' || actionType == 'return' || actionType == 'temporarySave'
		|| actionType == 'requestApproval' || actionType == 'reapply' || actionType == 'cancel' || actionType == 'cancelRequest'
		|| actionType == 'elaDelete' || actionType == 'agree' || actionType == 'parallel') {
		// 1. 승인 , 2 .반려  , 3. 임시저장  , 4. 결제요청 , 5. 반려건 재신청 , 6. 회수 , 7. 합의 , 8. 병렬합의
		if (typeof (openerObject.parentPage.doAction) !== 'undefined') {
			openerObject.parentPage.doAction('retrieve');
			var evt = jQuery.Event('dialogclose');
			evt.actionType = openerObject['actionType'];
			openerObject.trigger(evt);
		} else {
			var evt = jQuery.Event('dialogclose');
			evt.actionType = openerObject['actionType'];
			openerObject.trigger(evt);
		}
	}

	if (actionType == 'circular') {
		// 회람일때
		alert('회람일때 elaCommand.js 파일');
	}
}

/**
 * 전자결재 오류 처리부
 */
function doElaFault(actionType, errorData, _resultMessage) {
	alert(_resultMessage);
	//alert("결재처리중 오류가 발생하였습니다. 관리자에게 문의하세요.");
}
/**
 * 전자결재 처리 요청 메시지를 받는 부분
 * 
 * @return
 */
function getElaRequestMessage() {
	var currentWorkData = {};
	var agreeOpinion = "";

	currentWorkData = [{
		"work_group_id": getApplId(),
		"appl_id": getApplId(),
		"appl_cd": getApplCd(),
		"ela_company_cd" : getElaCompanyCd(),
		"opinion": ""
	}];

	if (getApplStatusCd() == "111") {
		currentWorkData = [{
			"is_new": false,
			"appl_id": getApplId(),
			"work_group_id": getApplId(),
			"work_id": elaLineData[0].id,
			"appl_cd": getApplCd(),
			"ela_company_cd" : getElaCompanyCd(),
			"make_emp_id": getMakeEmpId(),
			"emp_id": ela_getApplyingEmpId(),
			"file_path_id": getFilePathId(),
			"opinion": elaLineData[0].worker_comments
		}];
		return currentWorkData;
	}

	for (var i = 0; i < elaLineData.length; i++) {
		if (elaLineData[i].current_work == 'true') {
			if (getIsNew() == true) {
				currentWorkData = [{
					"is_new": getIsNew(),
					"appl_id": getApplId(),
					"ela_company_cd" : getElaCompanyCd(),
					"work_group_id": getApplId(),
					"work_id": elaLineData[i].id,
					"appl_cd": getApplCd(),
					"make_emp_id": getMakeEmpId(),
					"emp_id": ela_getApplyingEmpId(),
					"file_path_id": getFilePathId(),
					"opinion": elaLineData[i].worker_comments,
					//"opinion" : getOpinionText(),
				}];
			} else {
				currentWorkData = [{
					"appl_id": getApplId(),
					"ela_company_cd" : getElaCompanyCd(),
					"work_group_id": getApplId(),
					"work_id": elaLineData[i].id,
					"appl_cd": getApplCd(),
					"opinion": elaLineData[i].worker_comments
					//"opinion" : getOpinionText()
				}];
			}
			return currentWorkData;
			
		} else { // current_work = false (합의일때는 current_work가 true일수 없음)
			
			if ( getStatusName() == 'agree' && elaLineData[i].appr_kind == 'agree' ) {
				currentWorkData = [{
					"work_id": elaLineData[i].id,
					"ela_company_cd" : getElaCompanyCd(),
					"work_group_id": getApplId(),
					"appl_id": getApplId(),
					"appl_cd": getApplCd(),
					"opinion": $("#dialog_comments").val()
					//"opinion" : getOpinionText()
				}];
				return currentWorkData;
			}
		}
	}
	return currentWorkData;
}

/**
 * 결재자 지정시 결재 라인을 받는 부분
 * 
 * @return
 */
function getApprLineMessage() {
	var lineDs = new Message();
	// work_id:채번 값
	// work_group_id:applId
	// emp_id:결재자의 EMP_ID
	// work_type:E 라는 값이 들어간다.
	// ord_no:순서
	// worker_kind_cd:승인/합의/ 뭐 이런 코드가 들어간다.
	// worker_group_cd:sender/receiver 가 들어간다

	if (getIsNew() == true) {
		for (var i = 0; i < elaLineData.length; i++) {
			var apprRecord = lineDs.newMessageItem();
			
			apprRecord.setValue("work_id", elaLineData[i].id);
			apprRecord.setValue("work_group_id", getApplId());
			apprRecord.setValue("emp_id", elaLineData[i].appr_emp_id);
			apprRecord.setValue("repl_emp_id", elaLineData[i].repl_emp_id);
			apprRecord.setValue("work_type", "E");
			apprRecord.setValue("ord_no", elaLineData[i].ord_no);
			apprRecord.setValue("worker_kind_cd", elaLineData[i].nodeTypeCd);
			apprRecord.setValue("worker_group_cd", elaLineData[i].appr_kind);
			apprRecord.setValue("worker_comments", elaLineData[i].worker_comments);
			apprRecord.setValue("ext_worker_group_cd", elaLineData[i].ext_worker_group_cd === "null" ? "" : elaLineData[i].ext_worker_group_cd);
		}
		
	} else {
		
		var reInsertIndex = 9999;
		for (var i = 0; i < elaLineData.length; i++) {
			var current_work = elaLineData[i].current_work;
			if (current_work === "true") {
				reInsertIndex = i;
			}

			if (reInsertIndex < i) {
				elaLineData[i].sStatus = "I";
			}else{
				elaLineData[i].sStatus = "R";
			}
			var apprRecord = lineDs.newMessageItem();
			
			apprRecord.setValue("work_id", elaLineData[i].id);
			apprRecord.setValue("work_group_id", getApplId());
			apprRecord.setValue("emp_id", elaLineData[i].appr_emp_id);
			apprRecord.setValue("repl_emp_id", elaLineData[i].repl_emp_id);
			apprRecord.setValue("work_type", "E");
			apprRecord.setValue("ord_no", elaLineData[i].ord_no);
			apprRecord.setValue("worker_kind_cd", elaLineData[i].nodeTypeCd);
			apprRecord.setValue("worker_group_cd", elaLineData[i].appr_kind);
			apprRecord.setValue("sStatus", elaLineData[i].sStatus);
			apprRecord.setValue("worker_comments", elaLineData[i].worker_comments);
			apprRecord.setValue("ext_worker_group_cd", elaLineData[i].ext_worker_group_cd);
		}
	}
	
	return lineDs.getJson();
}
/**
 * 전자결재시 결재& 합의 개수를 반환한다.
 * 2021-03-28 이문범 추가
 * @return cnt
 */
function getLineCnt() {
	var message = getApprLineMessage();
	if(message == null || message == ''){
		return 0;
	}
	else{
		var line_length = message.length;
		var cnt = 0;
		for(var i = 0; i < line_length; i++){
			if(message[i].worker_kind_cd == '02' ||  message[i].worker_kind_cd == '03'){
				cnt++;
			}
		}
	}
	return cnt;
}


/**
 * 전자결재시 의견을 넣는 부분의 텍스트를 가져온다.
 * 
 * @return
 */
function getOpinionText() {
	return "";
}

/**
 * 첨부 파일의 file path id를 가져온다
 * 
 * @return
 */
function getFilePathId() {
	try {
		var filePathId = $('#elaFileControl').triggerHandler('getFilePathId');
		return filePathId;
	} catch (err) {
		alert(err);
		return "";
	}

}
/**
 * 신청자의 emp_id를 찾아온다
 * 
 * @return
 */
function ela_getApplyingEmpId() {
	try {
		return eval("getApplyingEmpId()");
	} catch (err) {
		$.logger(err);
		return getDefaultApplyingEmpId();
	}
}

/**
 * 신청자의 Emp Id를 받아온다. 기본으로 전자결재선에서 '기안(01)'로 코드마킹이 되어 있는 녀석을 찾는다.
 * 
 * @return
 */
function getDefaultApplyingEmpId() {
	for (var i = 0; i < elaLineData.length; i++) {
		if (elaLineData[i].nodeTypeCd == '01') {
			return elaLineData[i].appr_emp_id;
		}
	}
}

function editComment(index) {
	var widthValue = $("#dialog_ela").parent().css("width").split("px")[0];
	var heightValue = $("#dialog_ela").parent().css("height").split("px")[0];
	var tWidth = (( $(window).width() - widthValue ) / 2) + "px"; 
	var tHeight = (( $(window).height() - heightValue ) / 2.5) + "px";
	$("#dialog_ela").parent().css('left', tWidth);
	$("#dialog_ela").parent().css('top', tHeight);
	
	clickIndex = index;
	$("#dialog_ela #dialog_comments").val(elaLineData[index].worker_comments);
	$("#dialog_ela").dialog("open");
}

function viewComment(index) {
	var widthValue = $("#dialog_ela").parent().css("width").split("px")[0];
	var heightValue = $("#dialog_ela").parent().css("height").split("px")[0];
	var tWidth = (( $(window).width() - widthValue ) / 2) + "px"; 
	var tHeight = (( $(window).height() - heightValue ) / 2.5) + "px";
	$("#dialog_ela").parent().css('left', tWidth);
	$("#dialog_ela").parent().css('top', tHeight);
	
	$("#dialog_ela_view #dialog_view_comments").val(elaLineData[index].worker_comments);
	$("#dialog_ela_view").dialog("open");
}

function commentSubmit(value) {
	var len = 0;
	var lossText = "";
	for (var i = 0; i < value.length; i++) {
		var c = escape(value.charAt(i));
		if (c.length == 1)
			len++;
		else if (c.indexOf("%u") != -1)
			len += 2;
		else if (c.indexOf("%") != -1)
			len += c.length / 3;

		if (len < 60)
			lossText += value.charAt(i);
	}

	if (len > 60)
		lossText += "...";

	if (len > 2000) {

		alert(__ELA_MSG_LENGTH);
	} else {
		$("#dialog_ela").dialog('close');
		elaLineData[clickIndex].worker_comments = value;
		if (useViewComment == "Y" || useDenyComment == "Y") {
			doElaAction2();
		} else {
			var commentRow = '#worker_comments' + clickIndex;
			$(commentRow).text(lossText);
		}
	}
}

function deleteComment(index) {
	elaLineData[index].worker_comments = "";
	var commentRow = '#worker_comments' + index;
	$(commentRow).text("");
}


/**
 * 첨부파일 숫자를 반환한다.
 * 2020.12.24 상진 근태업무에서 사용하신다고 추가 요청
 */
 
function getElaFileCount() {
	//elaAppl에 file_path_id를 따라가서 FRM_FILE_INFO 테이블에서 갯수를 얻어오기 
	var cnt = 0;
	var requestObject = {
		"HEADER": headerObject,
		"BODY": {
			"ME_ELA0002_01": [{
				"appl_id": getApplId()
			}]
		}
	};

	execute("elaFileCntRetrieve", "ELA0002_00_R01", requestObject, function(actionType, obj) {
		var data = obj["ME_ELA0002_02"];
		
		cnt = data[0].file_cnt;
	}, function(actionType, obj) {	// 예외처리
		alert("전자결재 첨부파일 갯수 조회 중 오류 발생!");
		return;
	}, false);
	
	return cnt;
}

/**
 * 구분에 따라 해당 결재선의 숫자를 반환한다.
 * 
 * line_type > W : 작성부서
 *             P : 처리부서
 * */
function getElaLineCount(line_type) {
	return 1;
}

function deleteConnDoc(req_pk, appl_id) {
	if( !confirm("해당 연결문서를 삭제 하시겠습니까?") ) {
		return;
	}
	
	var requestObject = {
		"HEADER": headerObject,
		"BODY": {
			"ME_ELA_CONN_DOC_01": [{
				"req_pk": req_pk,
				"appl_id": appl_id
			}]
		}
	};

	execute("delConnDoc", "ELA_CONN_DOC_B01", requestObject, function(actionType, obj) {
		var data = obj["ME_FRM_SP_RESULT"];
	
		if (data[0].ret_code == "SUCCESS!") {
			alert("삭제 되었습니다!");
			
			var requestObject = {
				"HEADER": headerObject,
				"BODY": {
					"ME_ELA0001_01": [{
						"appl_id": getApplId()
					}]
				}
			};
			
		
			execute("elaConnDocSaveAfter", "ELA0001_00_R03", requestObject, drawElaConnDoc,
				function(actionType, obj) {	// 예외처리
					alert("연결문서 조회 중 오류 발생!");
					return;
				}, false
			);
		}
		
	}, function(actionType, obj) {	// 예외처리
		alert("신청서 신청자와의 정보가 틀립니다!");
		return;
	}, false);
}

// 전자결재 라인을 반영하게 할 함수를 추가한다.
// 전자결재 라인을 팝업으로부터 돌려받는 함수
var elaLineData = {};

function applyElaLine(newLineData) {
	elaLineData = newLineData;
	drawElaLine();
}

/**
 * 결재라인을 그리는 함수
 * - 해당 함수가 호출 되는 시점
 *   1. 처음 신청서를 열때
 *   2. 결재자지정 팝업에서 확인 버튼을 클릭 했을때
 */
function drawElaLine() {
	var str           = {};
	var strLong       = '';
	var refHtml       = '';
	var lineLabel     = '';
	var apprKind      = null;
	var nextApprType  = null;
	var stateLabel    = null;
	var senderCnt     = 0;
	var receiverCnt   = 0;
	var lastIdx       = 0;
	var senderHdChk   = true;
	var receiverHdChk = true;
	
	elaLineData.reverse();
	lastIdx = elaLineData.length - 1;
	
	$.each(elaLineData, function(index, entry1) {
		var gubun = "";
		var currentApprKind = entry1["appr_kind"];
		var current_work = entry1["current_work"];
		
		if (currentApprKind !== apprKind) { // 치환하면서 계속 비교 
			apprKind = currentApprKind;
			str[currentApprKind] = "";   
		}
		
		if ( currentApprKind === 'sender' ) {
			senderCnt++;
		} else if( currentApprKind === 'receiver' && entry1["nodeTypeCd"] !== "04" ) { 
			receiverCnt++;
		}
		
		if( current_work == "true" ) {
			currentWorkIndex = lastIdx - index;
		}

		// ------ S. 라인타입
		if (currentApprKind === 'request' || currentApprKind === 'sender') {
			lineLabel = sendLabel;
		}
		if (currentApprKind === 'receiver') {
			lineLabel = receiveLabel;
		}
		// ------ E. 라인타입

		
		// ------ S. 결재구분
		if( entry1["nodeTypeCd"] === "01" ) {
			gubun = "상신";
		}
		else if( entry1["nodeTypeCd"] === "02" && entry1["ext_worker_group_cd"] === "agree" ) {
			gubun = "합의";
		}
		else if( entry1["nodeTypeCd"] === "02" && entry1["ext_worker_group_cd"] === "parallel" ) {
			gubun = "병렬합의";
		}
		else {
			gubun = "결재";
		}
		// ------ E. 결재구분

		
		// ------ S. 승인상태
		if( index !== lastIdx ) {
			nextApprKind = elaLineData[index+1]["appr_kind"];
		}
		
		// 기본 상태
		stateLabel = entry1["appr_type_nm"];
		
		if(   ( entry1["nodeTypeCd"] === "01"  && entry1["appr_date"] !== "" ) 
		   || ( currentApprKind === "receiver" && entry1["appr_date"] !== "" && nextApprKind === "sender" ) ) 
		{
			// 신청자 이거나 첫번째 처리부서 결재자가 결재를 했으면 [작성]으로 표시
			stateLabel = "작성";
		}
		if(   ( entry1["ext_state_cd"] === "202" && currentApprKind === "sender"   && entry1["appr_date"] !== "" && senderCnt === 1 ) 
		   || ( entry1["ext_state_cd"] === "202" && currentApprKind === "receiver" && entry1["appr_date"] !== "" && receiverCnt === 1 ) ) 
		{
			// 각 라인의 마지막 결재자가 승인을 했으면 [전결]로 표시
			stateLabel = "전결";
		}
		// ------ E. 승인상태
		
		// ------ S. 결재라인 그리기
		if (index == 0) {
			str[currentApprKind] +="<div style='width: 99%; height: auto; overflow-y:auto'>";   
			str[currentApprKind] +="  <table height='60px' class='move' style='width:100%;padding:5px 0px 0 10px;margin:0;'>";   
		}

		// 헤더
		if(   ( ( currentApprKind === "sender" || currentApprKind === "request" ) && senderHdChk ) 
		   || ( currentApprKind === "receiver" && receiverHdChk && entry1["nodeTypeCd"] !== "04" ) )
		{
			str[currentApprKind] +="<tr>";
			str[currentApprKind] +="  <th class='move_title'  colspan='7'>" + lineLabel + "</th>";
			str[currentApprKind] +="</tr>";
			str[currentApprKind] +="<tr>";
			str[currentApprKind] +="  <th class='ela-line-th th-gubun'><label style='font-weight: bold;'>"+header_type+"</label></th>";
			str[currentApprKind] +="  <th class='ela-line-th th-name'><label style='font-weight: bold;'>"+header_name+"</label></th>";
			str[currentApprKind] +="  <th class='ela-line-th th-date'><label style='font-weight: bold;'>"+header_date+"</label></th>";
			if( useViewComment === "Y" ) {
				str[currentApprKind] +="  <th class='ela-line-th th-comment'><label style='font-weight: bold;'>"+header_opinion+"</label></th>";
			}
			// str[currentApprKind] +="  <th class='ela-line-th th-status'><label style='font-weight: bold;'>승인상태</label></th>";
			str[currentApprKind] +="</tr>";
			
			if( currentApprKind === "sender" ) {
				senderHdChk = false;
			} else {
				receiverHdChk = false;
			}
		}
		
		// 결재라인
		if( entry1["nodeTypeCd"] !== "04" ) { // 참조는 밑에서 추가
			str[currentApprKind] +="<tr>";
			str[currentApprKind] +="  <td height='30px' align='center'><label>" + gubun + "</label></td>";
			str[currentApprKind] +="  <td height='30px' align='left'>";
			str[currentApprKind] +="    <label>" + entry1["worker_label"] + "</label>"
			str[currentApprKind] +="  </td>";
			str[currentApprKind] +="  <td height='30px' align='center'><label>" + entry1["appr_date"] + "</label></td>";
			if( useViewComment === "Y" ) {
				str[currentApprKind] +="<td>";
				if( entry1["worker_comments"] !== "" && entry1["worker_comments"] !== null ) {
					str[currentApprKind] +="<div class='view-comment-icon'>";
					str[currentApprKind] +="  <img onclick='viewComment("+ (lastIdx-index) +")' class='view-comment-icon-img' src='/common/images/common/icon-comment-2.png' />"
					str[currentApprKind] +="</div>";
				}
				str[currentApprKind] +="</td>";
			}
			// str[currentApprKind] +="  <td height='30px' align='center'><label>" + stateLabel + "</label></td>";
			str[currentApprKind] +="</tr>";
		}
		
		// 참조(수신/열람) 추가
		if( entry1["nodeTypeCd"] === "04" ) { // 참조
			if( refHtml !== "" && refHtml !== null ) {
				refHtml += "<span style='padding: 0 8px;'>,</span>";
			}
			refHtml += "<span style='font-weight:normal;color:#000;'>" + entry1["worker_label"] + "</span>";
		}
		// ------ E. 결재라인 그리기
	});
	
	if ((elaLineData.length - 1) == index) {
		str[currentApprKind] +="  </table>";
		str[currentApprKind] +="</div>";
	}

	for (var index in str) {
		if (str[index] !== undefined) {
			strLong += str[index];
		}
	}
	
	$('#elaLinePart').html(strLong);

	if( refHtml !== null && refHtml !== "" ) {
		$("#referInfo").html(refHtml);
	} else {
		$("#referInfo").empty();
	}
	
	$('button.editBtn').button({ icons: { primary: 'ui-icon-pencil' }, text: false });
	$('button.editBtn').removeClass('ui-button-icon-only');
	
	$('button.viewBtn').button({ icons: { primary: 'ui-icon-search' }, text: false });
	$('button.viewBtn').removeClass('ui-button-icon-only');
	
	$('button.deleteBtn').button({ icons: { primary: 'ui-icon-trash' }, text: false });
	$('button.deleteBtn').removeClass('ui-button-icon-only');
	
	if (senderCnt > 0) {
		$('td.sender:first').attr('rowspan', senderCnt);
		$('td.sender:not(td.sender:first)').remove();
	}
	
	if (receiverCnt > 0) {
		$('td.receiver:first').attr('rowspan', receiverCnt);
		$('td.receiver:not(td.receiver:first)').remove();
	}
	
	elaLineData.reverse();
}

function drawElaConnDoc(actionType, obj) {
	var data = obj["ME_ELA0001_02"];
	var strHtml = "";

	$("#conn_list").html("");
	
	for(var i=0; i < data.length; i++) {
		var param_pk_id = data[i].ela_conn_doc_id;
		var conn_appl_id = data[i].conn_appl_id;
		var param_appl_nm = data[i].appl_nm
		var param_object_nm = data[i].object_nm;
		var param_appl_cd = data[i].conn_appl_cd;
		
		strHtml += "<span style='cursor:pointer;'>";
		strHtml += "  <a style='padding:5px;' onClick=\"openConnDocObj(" + param_pk_id + "," + conn_appl_id + ", '" + param_appl_cd + "', '" + param_object_nm + "')\">" + param_appl_nm + "</a>";
		strHtml += "  <a onClick=\"deleteConnDoc(" +  param_pk_id + ", "+ conn_appl_id + ")\">x</a>";
		strHtml += "</span>";
	}
	
	$("#conn_list").html(strHtml);
}

function openConnDocObj(connDocId, applId, applCd, objectNm) {
	var initData = {
			"appl_id" : applId,
			"appl_cd" : applCd
		};
	top.popUpObject(objectNm,'openPopup',initData,true,getCompanyCd(),null,null,this, connDocId);
}