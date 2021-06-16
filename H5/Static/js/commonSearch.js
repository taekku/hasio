function CommonSearch() {
	this.dialogId = "__dialog";
	this.dialogFrameId = "__dialogFrame";
	
	this.searchElementId = null;
	this.buttonId = null;
	
	this.searchServiceId = null;
	this.popupObjectId = null;
	this.headerObject = null;
	
	this.paramFunction = null;
	this.bindFunction = null;
	
	this.useEnterEvent = false;
	this.useSearchButton = true;
	
	this.sendMessageId = null;
	this.receiveMessageId = null;
	
	this.searchEndFunction = null;
}

CommonSearch.prototype.setHeaderObject = function(value) {
	this.headerObject = value;
};

CommonSearch.prototype.setSearchServiceId = function(value) {
	this.searchServiceId = value;
};

CommonSearch.prototype.setSendMessageId = function(value) {
	this.sendMessageId = value;
};

CommonSearch.prototype.setReceivemessageId = function(value) {
	this.receiveMessageId = value;
};

CommonSearch.prototype.setSearchEndFunction = function(value) {
	this.searchEndFunction = value;
};

CommonSearch.prototype.getPopupObjectId = function() {
	return this.popupObjectId;
};

CommonSearch.prototype.setPopupObjectId = function(value) {
	this.popupObjectId = value;
};

CommonSearch.prototype.getSearchElementId = function() {
	return this.searchElementId;
};
CommonSearch.prototype.setSearchElementId = function(value) {
	this.searchElementId = value;
};

CommonSearch.prototype.getButtonId = function() {
	return this.buttonId;
};
CommonSearch.prototype.setButtonId = function(value) {
	this.buttonId = value;
};

CommonSearch.prototype.getObjectId = function() {
	return this.objectId;
};
CommonSearch.prototype.setObjectId = function(value) {
	this.objectId = value;
};

CommonSearch.prototype.getUseEnterEvent = function() {
	return this.useEnterEvent;
};

CommonSearch.prototype.setUseEnterEvent = function(value) {
	this.useEnterEvent = value;
};

CommonSearch.prototype.getUseSearchButton = function() {
	return this.useSearchButton;
};

CommonSearch.prototype.setUseSearchButton = function(value) {
	this.useSearchButton = value;
};

CommonSearch.prototype.getDialogObject = function() {
	return $('#' + this.dialogId);
};

CommonSearch.prototype.elementBindByEvent = function() {
	if (this.getSearchElementId() != null && this.getSearchElementId() != "" && this.getUseEnterEvent()) {
		$('#' + this.getSearchElementId()).bind('keydown', {
			"commonSearch" : this
		}, function(event) {
			if (event.keyCode == 13 && $(this).val().length > 0) {
				event.data.commonSearch.doSearch();
			}
		});
	}
	
	if (this.getButtonId() != null && this.getButtonId() != "") {
		$('#' + this.getButtonId()).bind('click', {
			"commonSearch" : this
		}, function(event) {
			event.data.commonSearch.openPopup();
		});
		
		if (!this.getUseSearchButton()) {
			$('#' + this.getButtonId()).attr("display", "none");
		}
	}
};


var _callStack = [];

CommonSearch.prototype.doSearch = function() {
	var initValue = null;
	if (this.paramFunction != null)
		initValue = this.paramFunction();
	
	var bodyObject = {};
	bodyObject[this.sendMessageId] = [initValue];
	
	var requestObject = {
		"HEADER" : this.headerObject,
		"BODY" : bodyObject
	};
	_callStack[this.receiveMessageId] = this;
	execute(this.receiveMessageId, this.searchServiceId, requestObject, this.doSuccess, function(actionType, obj) {
		alert("ERROR commonSearch");
	});
};

CommonSearch.prototype.doSuccess = function(actionType, obj) {
	var orgThis = _callStack[actionType];
	var resultObject = obj[orgThis.receiveMessageId];
	
	if (resultObject.length == 1) {
		if (orgThis.bindFunction != null)
			orgThis.bindFunction(actionType, resultObject[0]);
	} else {
		orgThis.openPopup();
	}
};

CommonSearch.prototype.openPopup = function() {
	var initValue = null;
	if (this.paramFunction != null)
		initValue = this.paramFunction();
	
	popUpObject(this.popupObjectId, this.popupObjectId, initValue, "true", getCompanyCd(), this.dialogId, this.bindFunction);
};

CommonSearch.prototype.popupClose = function() {
	$('#' + this.dialogId).dialog('close');
}