function CommonSearch2() {
	this.dialogId = "__dialog";
	this.dialogFrameId = "__dialogFrame";
	
	this.searchServiceId = null;
	this.popupObjectId = null;
	this.headerObject = null;
	
	this.paramFunction = null;
	this.bindFunction = null;
	
	this.sendMessageId = null;
	this.receiveMessageId = null;
	
	this.authCntMessageId = null;
	
	// 엔터 이벤트 발생시 검색필드의 값이 "" 인 경우 초기화 시키기 위한 기능 추가 홍영석(2012/03/05)
	this.searchValue = null;
	
	// searchEndEvent 기능 미구현 추가, 이효정 추가(2012/02/24)
	this.searchEndFunction = null;	
	
	// 해당 액션이 일어난 페이지
	this.sourcePage = null;
}

// 엔터 이벤트 발생시 검색필드의 값이 "" 인 경우 초기화 시키기 위한 기능 추가 홍영석(2012/03/05)
CommonSearch2.prototype.setSearchValue = function(value) {
	this.searchValue = value;
};

CommonSearch2.prototype.setHeaderObject = function(value) {
	this.headerObject = value;
};

CommonSearch2.prototype.setSearchServiceId = function(value) {
	this.searchServiceId = value;
};

CommonSearch2.prototype.setSendMessageId = function(value) {
	this.sendMessageId = value;
};

CommonSearch2.prototype.setReceiveMessageId = function(value) {
	this.receiveMessageId = value;
};

CommonSearch2.prototype.setAuthCntMessageId = function(value) {
	this.authCntMessageId = value;
};

CommonSearch2.prototype.setPopupObjectId = function(value) {
	this.popupObjectId = value;
};

CommonSearch2.prototype.getDialogObject = function() {
	return $('#' + this.dialogId);
};
//searchEndEvent 기능 미구현 추가, 이효정 추가(2012/02/24)
CommonSearch2.prototype.setSearchEndFunction = function(value) {
	this.searchEndFunction = value;
};

CommonSearch2.prototype.setSourcePage = function(value) {
	this.sourcePage = value;
};

CommonSearch2.prototype.getSourcePage = function() {
	return this.sourcePage;
};

CommonSearch2.prototype.elementBindByEvent = function() {
};

var _callStack = [];

CommonSearch2.prototype.doSearch = function() {
	var menuId = top.getCurrentMenuId();
	
	//alert("curMenuId : " + menuId);

	if(this.searchValue == null || this.searchValue == "") {
		this.binding(this.receiveMessageId, {});
	}
	else {
		var initValue = null;
		if (this.paramFunction != null)
			initValue = this.paramFunction();
		
		var bodyObject = {};
		
		initValue.auth_str = menuId;
		
		bodyObject[this.sendMessageId] = [initValue];

		var requestObject = {
			"HEADER" : this.headerObject,
			"BODY" : bodyObject
		};
		_callStack[this.receiveMessageId] = this;
		execute(this.receiveMessageId, this.searchServiceId, requestObject, this.doSuccess, function(actionType, obj) {
			alert("ERROR commonSearch");
		});
	}
};

CommonSearch2.prototype.doSuccess = function(actionType, obj) {
	var orgThis = _callStack[actionType];
	var resultObject = obj[orgThis.receiveMessageId];
	var authYn = "N";
	var authCnt = null;
	if(orgThis.authCntMessageId != null){
		authYn = "Y";
		var authObject = obj[orgThis.authCntMessageId];
		authCnt = parseInt(authObject[0]['cnt']);
	}

	//console.log("resultObject.length : " + resultObject.length);
	//console.log("authCnt : " + authCnt);
	//console.log("authYn : " + authYn);

	if (resultObject.length == 1) {
		if(authYn == "Y" && authCnt == 0){
			orgThis.openPopup();
		} else {
			if (orgThis.bindFunction != null) {
				var tmp = {};
				tmp[orgThis.receiveMessageId] = resultObject[0];
				// 홍댈수정(2012/02/24) searchendfunction만드느라..
				orgThis.binding(actionType, tmp);
			}
		}
	} else {
		orgThis.openPopup();
	}
};
// 홍영석수정(2012/03/05) searchend 처리시 두가지 발생 유형 모두 처리되도록 수정
CommonSearch2.prototype.binding = function(actionType, value) {
	var bindFunc = null;
	var searchFunc = null;
	
	if(typeof(this.bindFunction) == "undefined") {
		var orgThis = _callStack[actionType];
		
		if(typeof(orgThis.bindFunction) != "undefined") {
			bindFunc = orgThis.bindFunction;
			searchFunc = orgThis.searchEndFunction;
			orgThis.bindFunction(actionType, value);
		}
	}
	else {
		bindFunc = this.bindFunction;
		searchFunc = this.searchEndFunction;
		this.bindFunction(actionType, value);
	}
	
	if(bindFunc != null && typeof(bindFunc) != "undefined")
		bindFunc(actionType, value);
	
	if(searchFunc != null && typeof(searchFunc) != "undefined")
		searchFunc(actionType, value);

};

CommonSearch2.prototype.openPopup = function() {
	var menuId = top.getCurrentMenuId();
	var initValue = null;
	if (this.paramFunction != null)
		initValue = this.paramFunction();	
		
	initValue.auth_str = menuId;
	
	// 홍댈수정(2012/02/24) searchendfunction만드느라..
	_callStack[this.receiveMessageId] = this;
	
	top.popUpObject(this.popupObjectId, this.receiveMessageId, initValue, "true", getCompanyCd(), this.dialogId, this.binding, this.getSourcePage());
};

CommonSearch2.prototype.popupClose = function() {
	$('#' + this.dialogId).dialog('close');
}
