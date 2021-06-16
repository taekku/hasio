function DynamicComboBox() {
	/**
	 * 변경될 콤보의 ID
	 */
	this.comboBoxId = null;
	
	/**
	 * 데이터 조회시 필요한 헤더 정보
	 */
	this.headerObject = null;
	
	/**
	 * 조회될 서비스 ID
	 */
	this.searchServiceId = null;
	
	/**
	 * 조회조건의 메시지 ID
	 */
	this.sendMessageId = null;
	
	/**
	 * 조회결과의 메시지 ID
	 */
	this.receiveMessageId = null;
	
	/**
	 * 조회조건들.... {key1: value1, key2: value2....}
	 */
	this.paramFunction = null;
	
	/**
	 * 임의의 option을 사용할지 여부
	 */
	this.useFirstItem = false;
	
	/**
	 * 임의의 option의 value
	 */
	this.firstItemValue = null;
	
	/**
	 * 임의의 option의 label
	 */
	this.firstItemLabel = null;
};

DynamicComboBox.prototype.setComboBoxId = function(value) {
	this.comboBoxId = value;
};

DynamicComboBox.prototype.setHeaderObject = function(value) {
	this.headerObject = value;
};

DynamicComboBox.prototype.setSearchServiceId = function(value) {
	this.searchServiceId = value;
};

DynamicComboBox.prototype.setSendMessageId = function(value) {
	this.sendMessageId = value;
};

DynamicComboBox.prototype.setReceiveMessageId = function(value) {
	this.receiveMessageId = value;
};

DynamicComboBox.prototype.setUseFirstItem = function(value) {
	this.useFirstItem = value;
};

DynamicComboBox.prototype.setFirstItemValue = function(value) {
	this.firstItemValue = value;
};

DynamicComboBox.prototype.setFirstItemLabel = function(value) {
	this.firstItemLabel = value;
};

DynamicComboBox.prototype.getComboBoxId = function() {
	return this.comboBoxId;
};

DynamicComboBox.prototype.getHeaderObject = function() {
	return this.headerObject;
};

DynamicComboBox.prototype.getSearchServiceId = function() {
	return this.searchServiceId;
};

DynamicComboBox.prototype.getSendMessageId = function() {
	return this.sendMessageId;
};

DynamicComboBox.prototype.getReceiveMessageId = function() {
	return this.receiveMessageId;
};

DynamicComboBox.prototype.isUseFirstItem = function() {
	return this.useFirstItem;
};

DynamicComboBox.prototype.getFirstItemValue = function() {
	return this.firstItemValue;
};

DynamicComboBox.prototype.getFirstItemLabel = function() {
	return this.firstItemLabel;
};


var _dcCallStack = [];

/**
 * 콤보의 데이터를 조회한다.
 */
DynamicComboBox.prototype.execute = function() {
	var initValue = null;
	if (this.paramFunction != null)
		initValue = this.paramFunction;
	
	var bodyObject = {};
	bodyObject[this.getSendMessageId()] = [ initValue ];
	
	var requestObject = {
		"HEADER" : this.headerObject,
		"BODY" : bodyObject
	};
	_dcCallStack[this.getReceiveMessageId()] = this;
	execute(this.getReceiveMessageId(), this.getSearchServiceId(), requestObject, function(actionType, obj) {
		var dc = _dcCallStack[actionType];
		var data = obj[dc.getReceiveMessageId()];
		
		dc.reSetOption(data);
	}, function(actionType, obj) {
		alert("ERROR DynamicCombo");
	});
};

/**
 * 콤보의 option를 새로 만든다.
 */
DynamicComboBox.prototype.reSetOption = function(values) {
	if(this.getComboBoxId() !== null && $("#" + this.getComboBoxId())[0] !== undefined &&  $("#" + this.getComboBoxId())[0] !== null) {
		$("#" + this.getComboBoxId()).empty();
		
		if(this.isUseFirstItem() === true) {
			$("#" + this.getComboBoxId()).append("<option value='" + this.getFirstItemValue() + "'>" + this.getFirstItemLabel() + "</option>");
		}
		
		if(values !== undefined && values !== null) {
			for(var idx =0; idx < values.length; idx++) {
	            var tmp = values[idx];
	            $.logger(idx + " : " + tmp['cd']);
	            $("#" + this.getComboBoxId()).append("<option value='" + tmp['cd'] + "'>" + tmp['cd_nm'] + "</otion>");
	        }
		}
	}
}
