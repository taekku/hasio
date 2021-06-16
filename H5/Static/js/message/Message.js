/**
 * 메시지 생성자
 * 
 * @param messageId
 * @returns
 */
function Message(messageId, jsonObj) {
	this._messageId = messageId;
	this._messageItems = null;
	this._currentIndex = 0;
	this._totalSize = 0;
	this._autoValueColumn = null;
	
	if (jsonObj !== undefined) {
		if (jsonObj instanceof Array) {
			for ( var idx in jsonObj) {
				this.newMessageItem(jsonObj[idx]);
			}
		} else {
			this.newMessageItem(jsonObj);
		}
	}
}

/**
 * 메시지 ID을 반환한다.
 * 
 * @returns {String}
 */
Message.prototype.getMessageId = function() {
	return this._messageId;
};

/**
 * 자동할당 컬럼ID를 적는다.
 * 
 * @param {String}value
 */
Message.prototype.setAutoValueColumn = function(value) {
	this._autoValueColumn = value;
};

/**
 * 메시지 아이템을 추가한다.
 * 
 * @param {MessageItem}
 *            item
 */
Message.prototype.addMessageItem = function(item) {
	if (item !== undefined && item !== null) {
		if (this._messageItems == null) {
			this._messageItems = [];
		}
		
		this._messageItems[this._totalSize++] = item;
	}
};

/**
 * 메시지가 가지고 있는 아이템 갯수를 반환한다.
 * 
 * @returns {Number}
 */
Message.prototype.size = function() {
	return this._totalSize;
};

/**
 * 신규 item를 추가한다.
 * 
 * @returns {MessageItem}
 */
Message.prototype.newMessageItem = function(items) {
	var item = null;
	if (items !== undefined && items !== null) {
		item = new MessageItem(items);
		this.addMessageItem(item);
	} else {
		item = new MessageItem();
		this.addMessageItem(item);
		
		item.setValue("_seq", (this.size()).toString());
		item.setValue("sStatus", "I");
		item.setValue("sDelete", "");
		
		if (this._autoValueColumn != null && this._autoValueColumn != "") {
			item.setValue(this._autoValueColumn, this._autoValueColumn + "_" + this.size());
		}
	}
	
	return item;
};

/**
 * 특정 인덱스의 item를 반환한다.
 * 
 * @param {Number}
 *            idx :
 * @returns {MessageItem}
 */
Message.prototype.getMessageItem = function(idx) {
	if (this._messageItems != null) {
		
		if (idx >= 0 && this.size() > 0 && this.size() - 1 >= idx) {
			return this._messageItems[idx];
		}
	}
	
	return null;
};

/**
 * next item 존재여부
 * 
 * @returns {Boolean}
 */
Message.prototype.hasNext = function() {
	if (this._messageItems != null) {
		if (this._currentIndex <= this.size() - 1) {
			return true;
		}
	}
	
	this._currentIndex = 0;
	return false;
};

/**
 * next item을 반환한다.
 * 
 * @returns {MessageItem}
 */
Message.prototype.next = function() {
	if (this.hasNext()) {
		var item = this.getMessageItem(this._currentIndex);
		this._currentIndex++;
		
		return item;
	}
	
	return null;
};

/**
 * 메시지를 json 구조로 반환한다.
 * 
 * @returns {json}
 */
Message.prototype.getJson = function() {
	if (this.hasNext()) {
		var jsonObj = [];
		var idx = 0;
		
		while (this.hasNext()) {
			var item = this.next();
			jsonObj[idx++] = item.getJson();
		}
		
		return jsonObj;
	}
	
	return null;
};