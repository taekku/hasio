function MessageItem(items) {
	this._items = null;
	
	if(items !== undefined)
		this._items = items;
};

/**
 * 컬럼값을 세팅한다.
 * @param {String} key
 * @param {String} value
 */
MessageItem.prototype.setValue = function (key, value) {
	if(this._items == null) {
		this._items = {};
	}
	
	this._items[key] = value;
};

/**
 * 컬럽값을 반환한다.
 * @param {String} key
 * @returns {String}
 */
MessageItem.prototype.getValue = function(key) {
	if(this._items != null && key in this._items) {
		return this._items[key];
	}
	
	return null;
};

/**
 * 메시지 아이템을 json 구조로 반환한다.
 * @returns {json}
 */
MessageItem.prototype.getJson = function() {
	return this._items;
};