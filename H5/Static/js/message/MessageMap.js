function MessageMap() {
	this._messageMap = null;
};

/**
 * 메시지를 추가한다
 * @param message
 */
MessageMap.prototype.addMessage = function(message, msgId) {
	if(message !== undefined && message !== null) {
		if(this._messageMap == null)
			this._messageMap = {};
		
		if(message instanceof Message) {
			if(msgId !== undefined && msgId !== null && msgId !== "")
				this._messageMap[msgId] = message;
			else
				this._messageMap[message.getMessageId()] = message;
		}
		else {
			// 이쪽으로 오는 케이스는 반드시 시스템이 반응할수 있는 구조의 json이다고 판단할것이다!!
			if(msgId !== undefined && msgId !== null && msgId !== "" && message != null) {
				this.addMessage(new Message(msgId, message), msgId);
			}
			else if(message instanceof Object) {
				for(var mId in message) {
					this.addMessage(new Message(mId, message[mId]));
				}
			}
		}
	}
};

/**
 * 메시지를 가져온다.
 * @param messageId
 * @returns
 */
MessageMap.prototype.getMessage = function(messageId) {
	if(this._messageMap != null) {
		if(messageId in this._messageMap == true) {
			return this._messageMap[messageId];
		}
	}
	
	return null;
};

/**
 * 메시지맵을 json 구조로 반환한다.
 * @returns {Json}
 */
MessageMap.prototype.getJson = function() {
	if(this._messageMap != null) {
		var jsonObj = {};
		
		for(var msgId in this._messageMap) {
			jsonObj[msgId] = this._messageMap[msgId].getJson();
		}
		/*
		$.each(this._messageMap, function(msgId, message) {
			jsonObj[msgId] = message.getJson();
		});
		*/
		
		return jsonObj;
	}
	return null;
};