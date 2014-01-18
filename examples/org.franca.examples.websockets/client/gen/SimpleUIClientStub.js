function SimpleUIClientStub(address) {
	this.socket = new (require('ws'))(address);
	this.callID = 0;
}

// export the "constructor" function to provide a class-like interface
module.exports = SimpleUIClientStub;

SimpleUIClientStub.prototype.getNextCallID = function() {
	this.callID = this.callID + 1;
	return this.callID;
};

// call to get the value of title asynchronously
SimpleUIClientStub.prototype.getTitle = function() {
	var cid = this.getNextCallID();
	this.socket.send('[2, "get:title:' + cid + '", "get:title"]');
	return cid;
};

// call to set the value of title asynchronously
SimpleUIClientStub.prototype.setTitle = function(title) {
	var cid = this.getNextCallID();
	this.socket.send('[2, "set:title:' + cid + '", "set:title", "' + title + '"]');
	return cid;
};

// call this method to subscribe for the changes of the attribute title
SimpleUIClientStub.prototype.subscribeTitleChanged = function() {
	this.socket.send('[5, "signal:title"]');
};

// call this method to unsubscribe from the changes of the attribute title
SimpleUIClientStub.prototype.unsubscribeTitleChanged = function() {
	this.socket.send('[6, "signal:title"]');
};

// call this method to invoke setMode on the server side
SimpleUIClientStub.prototype.setMode = function(p1) {
	var cid = this.getNextCallID();
	this.socket.send('[2, "invoke:setMode:' + cid + '", "invoke:setMode", "' + p1 + '"]');
	return cid;
};

SimpleUIClientStub.prototype.open = function(f) {
	var _this = this;
	_this.socket.on('open', function() {
		// subscribing for all broadcasts
		_this.socket.send('[5, "broadcast:updateVelocity"]');
		f();
	});
};

SimpleUIClientStub.prototype.init = function() {
	var _this = this;
	
	_this.socket.on('message', function(data) {
		var message = JSON.parse(data);
		if (Array.isArray(message)) {
			var messageType = message.shift();
			
			// handling of CALLRESULT messages
			if (messageType === 3) {
				var tokens = message.shift().split(":");
				var mode = tokens[0];
				var name = tokens[1];
				var cid = tokens[2];
				
				if (mode === "get") {
					if (name === "title" && typeof(_this.onGetTitle) === "function") {
						_this.onGetTitle(cid, message);
					}
				}
				else if (mode === "set") {
					if (name === "title" && typeof(_this.onSetTitle) === "function") {
						// no message is passed
						_this.onSetTitle(cid);
					}
				}
				else if (mode === "invoke") {
					if (name === "setMode" && typeof(_this.replySetMode) === "function") {
						_this.replySetMode(cid);
					}
				}
			}
			// handling of EVENT messages
			else if (messageType === 8) {
				var topicURI = message.shift();
				if (topicURI === "signal:title" && typeof(_this.onChangedTitle) === "function") {
					_this.onChangedTitle(message);
				}
				if (topicURI === "broadcast:updateVelocity" && typeof(_this.signalUpdateVelocity) === "function") {
					_this.signalUpdateVelocity(message);
				}
			}
		}
	});	
};

// definition of enumeration 'Mode'
var Mode = function(){
	return {
		'M_RADIO':0,
		'M_NAVIGATION':1,
		'M_MULTIMEDIA':2,
		'M_SETTINGS':3
	}
}();
module.exports.Mode = Mode;

