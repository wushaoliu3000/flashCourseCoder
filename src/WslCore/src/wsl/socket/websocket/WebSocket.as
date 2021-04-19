package wsl.socket.websocket
{
	import com.adobe.net.URI;
	import com.adobe.net.URIEncodingBitmap;
	import com.adobe.utils.StringUtil;
	import com.hurlant.crypto.hash.SHA1;
	import com.hurlant.crypto.tls.TLSConfig;
	import com.hurlant.crypto.tls.TLSEngine;
	import com.hurlant.crypto.tls.TLSSecurityParameters;
	import com.hurlant.crypto.tls.TLSSocket;
	import com.hurlant.util.Base64;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.OutputProgressEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.Timer;
	
	import wsl.events.WslEvent;
	
	[Event(name="connectionFail",type="wsl.socket.websocket.WebSocketErrorEvent")]
	[Event(name="ioError",type="flash.events.IOErrorEvent")]
	[Event(name="abnormalClose",type="wsl.socket.websocket.WebSocketErrorEvent")]
	[Event(name="message",type="wsl.socket.websocket.WebSocketEvent")]
	[Event(name="frame",type="wsl.socket.websocket.WebSocketEvent")]
	[Event(name="ping",type="wsl.socket.websocket.WebSocketEvent")]
	[Event(name="pong",type="wsl.socket.websocket.WebSocketEvent")]
	[Event(name="open",type="wsl.socket.websocket.WebSocketEvent")]
	[Event(name="closed",type="wsl.socket.websocket.WebSocketEvent")]
	[Event(name="receiveByteArray",type="wsl.socket.websocket.WebSocketEvent")]
	[Event(name="receiveBytes",type="wsl.events.WslEvent")]
	[Event(name="outProgress",type="wsl.events.WslEvent")]
	
	public class WebSocket extends EventDispatcher{
		private static const MODE_UTF8:int = 0;
		private static const MODE_BINARY:int = 0;
		
		private static const MAX_HANDSHAKE_BYTES:int = 10 * 1024; // 10KiB
		
		private var _bufferedAmount:int = 0;
		
		private var _readyState:int;
		private var _uri:URI; 
		private var _protocols:Array;
		private var _serverProtocol:String;
		private var _host:String;
		private var _port:uint;
		private var _resource:String;
		private var _secure:Boolean;
		private var _origin:String;
		private var _useNullMask:Boolean = false;
		
		private var rawSocket:Socket;
		private var socket:Socket;
		private var timeout:uint;
		
		/** 致命错误 */
		private var fatalError:Boolean = false;
		
		private var nonce:ByteArray;
		private var base64nonce:String;
		private var serverHandshakeResponse:String;
		private var serverExtensions:Array;
		private var curFrame:WebSocketFrame;
		private var frameQueue:Vector.<WebSocketFrame>;
		private var fragmentationOpcode:int = 0;
		private var fragmentationSize:uint = 0;
		
		private var waitingForServerClose:Boolean = false;
		private var closeTimeout:int = 5000;
		private var closeTimer:Timer;
		
		private var handshakeBytesReceived:int;
		private var handshakeTimer:Timer;
		private var handshakeTimeout:int = 10000;
		
		private var tlsConfig:TLSConfig;
		private var tlsSocket:TLSSocket;
		
		private var URIpathExcludedBitmap:URIEncodingBitmap = new URIEncodingBitmap(URI.URIpathEscape);
		public var config:WebSocketConfig = new WebSocketConfig();
		public var debug:Boolean = false;
		
		private var buf:ByteArray = new ByteArray();
		
		public static var logger:Function = function(text:String):void {
			//trace(text);
		};
		
		//-------------------------------------传输进度控制---------------------------------
		/** 要传输文件的字节数 */
		private var totalSize:Number;
		/** 一个文件开始输出前，socket已经输出的字节数 */
		private var initSize:Number;
		/** 是否是第一次输出 */
		private var isFirst:Boolean;
		/** 是否打开了输入进度事件 */
		private var isOpenInput:Boolean;
		
		/** 打开输出进度事件。<br>
		 * totalSize 要传输文件的大小<br>。 
		 * size 第一次要写入的字节数。*/
		public function openOutputEvent(totalSize:int, size:int):void{
			if(!socket) return;
			this.totalSize = totalSize;
			this.initSize = size;
			isFirst = true;
			socket.addEventListener(OutputProgressEvent.OUTPUT_PROGRESS, outPutHandler);
		}
		
		/** 关闭输出进度事件 */
		public function closeOutputEvent():void{
			totalSize = 0;
			socket.removeEventListener(OutputProgressEvent.OUTPUT_PROGRESS, outPutHandler);
		}
		
		private function outPutHandler(e:OutputProgressEvent):void{
			if(isFirst){
				initSize = e.bytesTotal - initSize;
				isFirst = false;
			}
			var n:int = int((e.bytesTotal-initSize)/totalSize*100);
			if(n > 100) n = 100;
			this.dispatchEvent(new WslEvent("outProgress", n));
		}
		
		/** 打开输入进度事件。<br>
		 * totalSize 要传输文件的大小。*/
		public function openInputEvent(totalSize:int):void{
			if(!socket) return;
			this.totalSize = totalSize;
			this.initSize = 0;
			this.isOpenInput = true;
		}
		
		/** 关闭输入进度事件 */
		public function closeInputEvent():void{
			totalSize = 0;
			initSize = 0;
			isOpenInput = false;
		}
		//-----------------------------------------------------------------------------------
		
		
		public function WebSocket(uri:String, origin:String, protocols:* = null, timeout:uint=10000)
		{
			super(null);
			_uri = new URI(uri);
			
			if (protocols is String) {
				_protocols = [protocols];
			}
			else {
				_protocols = protocols;
			}
			if (_protocols) {
				for (var i:int=0; i<_protocols.length; i++) {
					_protocols[i] = StringUtil.trim(_protocols[i]);
				}
			}
			_origin = origin;
			this.timeout = timeout;
			this.handshakeTimeout = timeout;
			init();
		}
		
		private function init():void {
			parseUrl();
			
			validateProtocol();
			
			frameQueue = new Vector.<WebSocketFrame>();
			fragmentationOpcode = 0x00;
			fragmentationSize = 0;
			
			curFrame = new WebSocketFrame();

			fatalError = false;
			
			closeTimer = new Timer(closeTimeout, 1);
			closeTimer.addEventListener(TimerEvent.TIMER, handleCloseTimer);
			
			handshakeTimer = new Timer(handshakeTimeout, 1);
			handshakeTimer.addEventListener(TimerEvent.TIMER, handleHandshakeTimer);
			
			rawSocket = socket = new Socket();
			socket.timeout = timeout;
			
			if (secure) {
				tlsConfig = new TLSConfig(TLSEngine.CLIENT, null, null, null, null, null, TLSSecurityParameters.PROTOCOL_VERSION);
				tlsConfig.trustAllCertificates = true;
				tlsConfig.ignoreCommonNameMismatch = true;
				socket = tlsSocket = new TLSSocket();
			}
			
			
			rawSocket.addEventListener(Event.CONNECT, handleSocketConnect);
			rawSocket.addEventListener(IOErrorEvent.IO_ERROR, handleSocketIOError);
			rawSocket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleSocketSecurityError);
			
			socket.addEventListener(Event.CLOSE, handleSocketClose);			
			socket.addEventListener(ProgressEvent.SOCKET_DATA, handleSocketData);
			
			_readyState = WebSocketState.INIT;
		}
		
		private function validateProtocol():void {
			if (_protocols) {
				var separators:Array = [
					"(", ")", "<", ">", "@",
					",", ";", ":", "\\", "\"",
					"/", "[", "]", "?", "=",
					"{", "}", " ", String.fromCharCode(9)
				];
				
				for (var p:int = 0; p < _protocols.length; p++) {
					var protocol:String = _protocols[p];
					for (var i:int = 0; i < protocol.length; i++) {
						var charCode:int = protocol.charCodeAt(i);
						var char:String = protocol.charAt(i);
						if (charCode < 0x21 || charCode > 0x7E || separators.indexOf(char) !== -1) {
							throw new WebSocketError("Illegal character '" + String.fromCharCode(char) + "' in subprotocol.");
						}
					}
				}
			}
		}
		
		public function connect(host:String, port:int):void {
			if (_readyState === WebSocketState.INIT || _readyState === WebSocketState.CLOSED) {
				_readyState = WebSocketState.CONNECTING;
				generateNonce();
				handshakeBytesReceived = 0;
				
				_host = host;
				_port = port;
				rawSocket.connect(_host, _port);
				if (debug) {
					logger("Connecting to " + _host + " on port " + _port);
				}
			}
		}
		
		private function parseUrl():void {
			_host = _uri.authority;
			var scheme:String = _uri.scheme.toLocaleLowerCase();
			if (scheme === 'wss') {
				_secure = true;
				_port = 443;
			}
			else if (scheme === 'ws') {
				_secure = false;
				_port = 80;
			}
			else {
				throw new Error("Unsupported scheme: " + scheme);
			}
			
			var tempPort:uint = parseInt(_uri.port, 10);
			if (!isNaN(tempPort) && tempPort !== 0) {
				_port = tempPort;
			}
			
			var path:String = URI.fastEscapeChars(_uri.path, URIpathExcludedBitmap);
			if (path.length === 0) {
				path = "/";
			}
			var query:String = _uri.queryRaw;
			if (query.length > 0) {
				query = "?" + query;
			}
			_resource = path + query;
		}
		
		/** 生成握手时用的密码键 */
		private function generateNonce():void {
			nonce = new ByteArray();
			for (var i:int = 0; i < 16; i++) {
				nonce.writeByte(Math.round(Math.random()*0xFF));
			}
			nonce.position = 0;
			base64nonce = Base64.encodeByteArray(nonce);
		}
		
		public function get readyState():int {
			return _readyState;
		}
		
		public function get bufferedAmount():int {
			return _bufferedAmount;
		}
		
		public function get uri():String {
			var uri:String;
			uri = _secure ? "wss://" : "ws://";
			uri += _host;
			if ((_secure && _port !== 443) || (!_secure && _port !== 80)) {
				uri += (":" + _port.toString());
			}
			uri += _resource;
			return uri;
		}
		
		public function get protocol():String {
			return _serverProtocol;
		}
		
		public function get extensions():Array {
			return [];
		}
		
		public function get host():String {
			return _host;
		}
		
		public function get port():uint {
			return _port;
		}
		
		public function get resource():String {
			return _resource;
		}
		
		public function get secure():Boolean {
			return _secure;
		}
		
		public function get connected():Boolean {
			return readyState === WebSocketState.OPEN;
		}
		
		// Pseudo masking is useful for speeding up wbesocket usage in a controlled environment,
		// such as a self-contained AIR app for mobile where the client can be resonably sure of
		// not intending to screw up proxies by confusing them with HTTP commands in the frame body
		// Probably not a good idea to enable if being used on the web in general cases.
		public function set useNullMask(val:Boolean):void {
			_useNullMask = val;
		}
		
		public function get useNullMask():Boolean {
			return _useNullMask;
		}
		
		private function verifyConnectionForSend():void {
			if (_readyState === WebSocketState.CONNECTING) {
				throw new WebSocketError("Invalid State: Cannot send data before connected.");
			}
		}
		
		/** 以字符串发送WebSocket协议 */
		public function sendUTF(data:String):void {
			verifyConnectionForSend();
			var frame:WebSocketFrame = new WebSocketFrame();
			frame.opcode = WebSocketOpcode.TEXT_FRAME;
			frame.binaryPayload = new ByteArray();
			frame.binaryPayload.writeMultiByte(data, 'utf-8');
			fragmentAndSend(frame);
		}
		
		/** 以二进制发送WebSocket协议 */
		public function sendBytes(data:ByteArray):void {
			verifyConnectionForSend();
			var frame:WebSocketFrame = new WebSocketFrame();
			frame.opcode = WebSocketOpcode.BINARY_FRAME;
			frame.binaryPayload = data;
			fragmentAndSend(frame);
		}
		
		/** 直接发送ByteArray数据，用于自定义协议编码之间的通信。<br>
		 * 协议开头被加上了wsl三个字符，方便服务器解析。 */
		public function sendByteArray(ba:ByteArray):void{
			var tBa:ByteArray = new ByteArray();
			tBa.writeMultiByte("wsl", "utf-8");
			ba.position = 0;
			tBa.writeBytes(ba);
			sendData(tBa);
		}
		
		/** 主动给服务器送发ping，以免服务器断开连接。<br>
		 * 不会自动发送，必须在程序中调用才会发送 */
		public function ping(payload:ByteArray = null):void {
			verifyConnectionForSend();
			var frame:WebSocketFrame = new WebSocketFrame();
			frame.fin = true;
			frame.opcode = WebSocketOpcode.PING;
			if (payload) {
				frame.binaryPayload = payload;
			}
			sendFrame(frame);
		}
		
		private function pong(binaryPayload:ByteArray = null):void {
			verifyConnectionForSend();
			var frame:WebSocketFrame = new WebSocketFrame();
			frame.fin = true;
			frame.opcode = WebSocketOpcode.PONG;
			frame.binaryPayload = binaryPayload;
			sendFrame(frame);
		}
		
		private function fragmentAndSend(frame:WebSocketFrame):void {
			if (frame.opcode > 0x07) {
				throw new WebSocketError("You cannot fragment control frames.");
			}
			
			var threshold:uint = config.fragmentationThreshold;
			if (config.fragmentOutgoingMessages && frame.binaryPayload && frame.binaryPayload.length > threshold) {
				frame.binaryPayload.position = 0;
				var length:int = frame.binaryPayload.length;
				var numFragments:int = Math.ceil(length / threshold);
				for (var i:int = 1; i <= numFragments; i++) {
					var currentFrame:WebSocketFrame = new WebSocketFrame();
					
					// continuation opcode except for first frame.
					currentFrame.opcode = (i === 1) ? frame.opcode : 0x00;
					
					// fin set on last frame only
					currentFrame.fin = (i === numFragments);
					
					// length is likely to be shorter on the last fragment
					var currentLength:int = (i === numFragments) ? length - (threshold * (i-1)) : threshold;
					frame.binaryPayload.position  = threshold * (i-1);
					
					// Slice the right portion of the original payload
					currentFrame.binaryPayload = new ByteArray();
					frame.binaryPayload.readBytes(currentFrame.binaryPayload, 0, currentLength);
					
					sendFrame(currentFrame);
				}
			}
			else {
				frame.fin = true;
				sendFrame(frame);
			}
		}
		
		private function sendFrame(frame:WebSocketFrame, force:Boolean = false):void {
			frame.mask = true;
			frame.useNullMask = _useNullMask;
			var buffer:ByteArray = new ByteArray();
			frame.send(buffer);
			sendData(buffer);
		}
		
		private function sendData(data:ByteArray, fullFlush:Boolean = false):void {
			if (!connected) { return; }
			data.position = 0;
			socket.writeBytes(data, 0, data.bytesAvailable);
			socket.flush();
			data.clear();
		}
		
		public function close(waitForServer:Boolean = true):void {
			if (!socket.connected && _readyState === WebSocketState.CONNECTING) {
				_readyState = WebSocketState.CLOSED;
				try {
					socket.close();
				}
				catch(e:Error) { /* do nothing */ }
			}
			if (socket.connected) {
				var frame:WebSocketFrame = new WebSocketFrame();
				frame.rsv1 = frame.rsv2 = frame.rsv3 = frame.mask = false;
				frame.fin = true;
				frame.opcode = WebSocketOpcode.CONNECTION_CLOSE;
				frame.closeStatus = WebSocketCloseStatus.NORMAL;
				var buffer:ByteArray = new ByteArray();
				frame.mask = true;
				frame.send(buffer);
				sendData(buffer, true);
				
				if (waitForServer) {
					waitingForServerClose = true;
					closeTimer.stop();
					closeTimer.reset();
					closeTimer.start();
				}
				dispatchClosedEvent("以服务的连接已经被断开!");
			}
		}
		
		private function handleCloseTimer(event:TimerEvent):void {
			if (waitingForServerClose) {
				// server hasn't responded to our request to close the
				// connection, so we'll just close it.
				if (socket.connected) {
					socket.close();
				}
			}
		}
		
		private function handleSocketConnect(event:Event):void {
			if (debug) {
				logger("Socket Connected");
			}
			if (secure) {
				if (debug) {
					logger("starting SSL/TLS");
				}
				tlsSocket.startTLS(rawSocket, _host, tlsConfig);
			}
			socket.endian = Endian.BIG_ENDIAN;
			sendHandshake();
		}
		
		private function handleSocketClose(e:Event):void {
			if (debug) {
				logger("Socket Disconnected");
			}
			dispatchClosedEvent("服务器关闭了连接！");
		}
		
		private var isWslFinal:Boolean = false;
		private var len:int = 0;
		private function handleSocketData(event:ProgressEvent=null):void {
			if (_readyState === WebSocketState.CONNECTING) {
				readServerHandshake(); 
				return;
			}
			
			if(isOpenInput){
				initSize += socket.bytesAvailable;
				var n:Number = int(initSize/totalSize*100);
				if(n > 100) n = 100;
				this.dispatchEvent(new WslEvent("receiveBytes", n));
			}
			
			socket.readBytes(buf, buf.position+buf.bytesAvailable);
			
			if(buf.bytesAvailable < 2) return;
			
			//假如为pong或非wsl开头的协议，交给用WebSocket定义来解析，否则发送一个事件，由自定义协议解析器来解析
			if(buf.bytesAvailable == 2 && buf[buf.position] == 0x8A){
			}else if(buf.readMultiByte(3, "utf-8") == "wsl" || isWslFinal){
				isWslFinal = true;
				if(len == 0){
					len = buf.readInt();
					buf.position -= 4;
				}else{
					buf.position -= 3;
				}
				if(buf.bytesAvailable >= len){
					var ba:ByteArray = new ByteArray();
					buf.readBytes(ba,0, len);
					var e:WebSocketEvent = new WebSocketEvent(WebSocketEvent.RECEIVE_BYTE_ARRAY);
					e.ba = ba;
					e.ba.position = 0;
					this.dispatchEvent(e);
					isWslFinal = false;
					len = 0;
					buf.clear();
				}
				return;
			}else{
				buf.position -= 3;
			}
			
			// addData returns true if the frame is complete, and false
			// if more data is needed.
			while (socket.connected && curFrame.addData(buf, fragmentationOpcode, config) && !fatalError) {
				if (curFrame.protocolError) {
					drop(WebSocketCloseStatus.PROTOCOL_ERROR, curFrame.dropReason);
					return;
				}else if (curFrame.frameTooLarge) {
					drop(WebSocketCloseStatus.MESSAGE_TOO_LARGE, curFrame.dropReason);
					return;
				}
				if (!config.assembleFragments) {
					var frameEvent:WebSocketEvent = new WebSocketEvent(WebSocketEvent.FRAME);
					frameEvent.frame = curFrame;
					dispatchEvent(frameEvent);
				}
				processFrame(curFrame);
				curFrame = new WebSocketFrame();
			}
		}
		
		
		/** 处理服务器返回的一帧的协议 */
		private function processFrame(frame:WebSocketFrame):void {
			var event:WebSocketEvent;
			var i:int;
			var currentFrame:WebSocketFrame;
			
			if (frame.rsv1 || frame.rsv2 || frame.rsv3) {
				drop(WebSocketCloseStatus.PROTOCOL_ERROR,
					 "Received frame with reserved bit set without a negotiated extension.");
				return;
			}

			switch (frame.opcode) {
				case WebSocketOpcode.BINARY_FRAME:
					if (config.assembleFragments) {
						if (frameQueue.length === 0) {
							if (frame.fin) {
								event = new WebSocketEvent(WebSocketEvent.MESSAGE);
								event.message = new WebSocketMessage();
								event.message.type = WebSocketMessage.TYPE_BINARY;
								event.message.binaryData = frame.binaryPayload;
								dispatchEvent(event);
							}
							else if (frameQueue.length === 0) {
								// beginning of a fragmented message
								frameQueue.push(frame);
								fragmentationOpcode = frame.opcode;
							}
						}
						else {
							drop(WebSocketCloseStatus.PROTOCOL_ERROR,
								 "Illegal BINARY_FRAME received in the middle of a fragmented message.  Expected a continuation or control frame.");
							return;
						}						
					}
					break;
				case WebSocketOpcode.TEXT_FRAME:
					if (config.assembleFragments) {
						if (frameQueue.length === 0) {
							if (frame.fin) {
								event = new WebSocketEvent(WebSocketEvent.MESSAGE);
								event.message = new WebSocketMessage();
								event.message.type = WebSocketMessage.TYPE_UTF8;
								event.message.utf8Data = frame.binaryPayload.readMultiByte(frame.length, 'utf-8');
								dispatchEvent(event);
							}
							else {
								// beginning of a fragmented message
								frameQueue.push(frame);
								fragmentationOpcode = frame.opcode;
							}
						}
						else {
							drop(WebSocketCloseStatus.PROTOCOL_ERROR,
								 "Illegal TEXT_FRAME received in the middle of a fragmented message.  Expected a continuation or control frame.");
							return;
						}
					}
					break;
				case WebSocketOpcode.CONTINUATION:
					if (config.assembleFragments) {
						if (fragmentationOpcode === WebSocketOpcode.CONTINUATION &&
							frame.opcode        === WebSocketOpcode.CONTINUATION)
						{
							drop(WebSocketCloseStatus.PROTOCOL_ERROR,
									"Unexpected continuation frame.");
							return;
						}
						
						fragmentationSize += frame.length;
						
						if (fragmentationSize > config.maxMessageSize) {
							drop(WebSocketCloseStatus.MESSAGE_TOO_LARGE, "Maximum message size exceeded.");
							return;
						}
						
						frameQueue.push(frame);
						
						if (frame.fin) {
							// end of fragmented message, so we process the whole
							// message now.  We also have to decode the utf-8 data
							// for text frames after combining all the fragments.
							event = new WebSocketEvent(WebSocketEvent.MESSAGE);
							event.message = new WebSocketMessage();
							var messageOpcode:int = frameQueue[0].opcode;
							var binaryData:ByteArray = new ByteArray();
							var totalLength:int = 0;
							for (i=0; i < frameQueue.length; i++) {
								totalLength += frameQueue[i].length;
							}
							if (totalLength > config.maxMessageSize) {
								drop(WebSocketCloseStatus.MESSAGE_TOO_LARGE,
									"Message size of " + totalLength +
									" bytes exceeds maximum accepted message size of " +
									config.maxMessageSize + " bytes.");
								return;
							}
							for (i=0; i < frameQueue.length; i++) {
								currentFrame = frameQueue[i];
								binaryData.writeBytes(
									currentFrame.binaryPayload,
									0,
									currentFrame.binaryPayload.length
								);
								currentFrame.binaryPayload.clear();
							}
							binaryData.position = 0;
							switch (messageOpcode) {
								case WebSocketOpcode.BINARY_FRAME:
									event.message.type = WebSocketMessage.TYPE_BINARY;
									event.message.binaryData = binaryData;
									break;
								case WebSocketOpcode.TEXT_FRAME:
									event.message.type = WebSocketMessage.TYPE_UTF8;
									event.message.utf8Data = binaryData.readMultiByte(binaryData.length, 'utf-8');
									break;
								default:
									drop(WebSocketCloseStatus.PROTOCOL_ERROR,
										 "Unexpected first opcode in fragmentation sequence: 0x" + messageOpcode.toString(16));
									return;
							}
							frameQueue = new Vector.<WebSocketFrame>();
							fragmentationOpcode = 0x00;
							fragmentationSize = 0;
							dispatchEvent(event);
						}
					}
					break;
				case WebSocketOpcode.PING:
					if (debug) {
						logger("Received Ping");
					}
					var pingEvent:WebSocketEvent = new WebSocketEvent(WebSocketEvent.PING, false, true);
					pingEvent.frame = frame;
					if (dispatchEvent(pingEvent)) {
						pong(frame.binaryPayload);
					}
					break;
				case WebSocketOpcode.PONG:
					if (debug) {
						logger("Received Pong");
					}
					var pongEvent:WebSocketEvent = new WebSocketEvent(WebSocketEvent.PONG);
					pongEvent.frame = frame;
					dispatchEvent(pongEvent);
					break;
				case WebSocketOpcode.CONNECTION_CLOSE:
					if (debug) {
						logger("Received close frame");
					}
					if (waitingForServerClose) {
						// got confirmation from server, finish closing connection
						if (debug) {
							logger("Got close confirmation from server.");
						}
						closeTimer.stop();
						waitingForServerClose = false;
						socket.close();
					}
					else {
						if (debug) {
							logger("Sending close response to server.");
						}
						close(false);
						socket.close();
					}
					break;
				default:
					if (debug) {
						logger("Unrecognized Opcode: 0x" + frame.opcode.toString(16));
					}
					drop(WebSocketCloseStatus.PROTOCOL_ERROR, "Unrecognized Opcode: 0x" + frame.opcode.toString(16));
					break;
			}
		}
		
		private function handleSocketIOError(e:IOErrorEvent):void {
			if (debug) {
				logger("IO Error: " + e);
			}
			dispatchEvent(e);
			dispatchClosedEvent("服务器找不到或网络故障！"+e.text);
		}
		
		private function handleSocketSecurityError(e:SecurityErrorEvent):void {
			if (debug) {
				logger("Security Error: " + e);
			}
			dispatchEvent(e.clone());
			dispatchClosedEvent("不在安全沙箱内，或服务器拒绝了你的连接，请查看安全配置或连接端口是否正确！"+e.text);
		}
		
		
		/** 向服务器发送握手协议 */
		private function sendHandshake():void {
			serverHandshakeResponse = "";
			
			var hostValue:String = host;
			if ((_secure && _port !== 443) || (!_secure && _port !== 80)) {
				hostValue += (":" + _port.toString());
			}
			
			var text:String = "";
			text += "GET " + resource + " HTTP/1.1\r\n";
			text += "Host: " + hostValue + "\r\n";
			text += "Upgrade: websocket\r\n";
			text += "Connection: Upgrade\r\n";
			text += "Sec-WebSocket-Key: " + base64nonce + "\r\n";
			if (_origin) {
				text += "Origin: " + _origin + "\r\n";
			}
			text += "Sec-WebSocket-Version: 13\r\n";
			if (_protocols) {
				var protosList:String = _protocols.join(", ");
				text += "Sec-WebSocket-Protocol: " + protosList + "\r\n";
			}
			// TODO: Handle Extensions
			text += "\r\n";
			
			if (debug) {
				logger(text);
			}
			
			socket.writeMultiByte(text, 'us-ascii');
			
			handshakeTimer.stop();
			handshakeTimer.reset();
			handshakeTimer.start();
		}
		
		private function failHandshake(message:String = "Unable to complete websocket handshake."):void {
			if (debug) {
				logger(message);
			}
			_readyState = WebSocketState.CLOSED;
			if (socket.connected) {
				socket.close();
			}
			
			handshakeTimer.stop();
			handshakeTimer.reset();
			
			var errorEvent:WebSocketErrorEvent = new WebSocketErrorEvent(WebSocketErrorEvent.CONNECTION_FAIL);
			errorEvent.text = message;
			dispatchEvent(errorEvent);
			
			var event:WebSocketEvent = new WebSocketEvent(WebSocketEvent.CLOSED);
			dispatchEvent(event);
		}
		
		private function failConnection(message:String):void {
			_readyState = WebSocketState.CLOSED;
			if (socket.connected) {
				socket.close();
			}
			
			var errorEvent:WebSocketErrorEvent = new WebSocketErrorEvent(WebSocketErrorEvent.CONNECTION_FAIL);
			errorEvent.text = message;
			dispatchEvent(errorEvent);
			
			var event:WebSocketEvent = new WebSocketEvent(WebSocketEvent.CLOSED);
			dispatchEvent(event);
		}
		
		private function drop(closeReason:uint = WebSocketCloseStatus.PROTOCOL_ERROR, reasonText:String = null):void {
			if (!connected) {
				return;
			}
			fatalError = true;
			var logText:String = "WebSocket: Dropping Connection. Code: " + closeReason.toString(10);
			if (reasonText) {
				logText += (" - " + reasonText);;
			}
			logger(logText);
			
			frameQueue = new Vector.<WebSocketFrame>();
			fragmentationSize = 0;
			if (closeReason !== WebSocketCloseStatus.NORMAL) {
				var errorEvent:WebSocketErrorEvent = new WebSocketErrorEvent(WebSocketErrorEvent.ABNORMAL_CLOSE);
				errorEvent.text = "Close reason: " + closeReason;
				dispatchEvent(errorEvent);
			}
			sendCloseFrame(closeReason, reasonText, true);
			dispatchClosedEvent("关闭理由："+reasonText);
			socket.close();				
		}
		
		private function sendCloseFrame(reasonCode:uint = WebSocketCloseStatus.NORMAL, reasonText:String = null, force:Boolean = false):void {
			var frame:WebSocketFrame = new WebSocketFrame();
			frame.fin = true;
			frame.opcode = WebSocketOpcode.CONNECTION_CLOSE;
			frame.closeStatus = reasonCode;
			if (reasonText) {
				frame.binaryPayload = new ByteArray();
				frame.binaryPayload.writeUTFBytes(reasonText);
			}
			sendFrame(frame, force);
		}
		
		/** 服务器返回了握手数据，验证握手是否成功 */
		private function readServerHandshake():void {
			var upgradeHeader:Boolean = false;
			var connectionHeader:Boolean = false;
			var serverProtocolHeaderMatch:Boolean = false;
			var keyValidated:Boolean = false;
			var headersTerminatorIndex:int = -1;
			
			// Load in HTTP Header lines until we encounter a double-newline.
			while (headersTerminatorIndex === -1 && readHandshakeLine()) {
				if (handshakeBytesReceived > MAX_HANDSHAKE_BYTES) {
					//假如握手数据大于10KB，扬失败
					failHandshake("Received more than " + MAX_HANDSHAKE_BYTES + " bytes during handshake.");
					return;
				}

				headersTerminatorIndex = serverHandshakeResponse.search(/\r?\n\r?\n/);
			}
			if (headersTerminatorIndex === -1) {
				return;
			}

			if (debug) {
				logger("Server Response Headers:\n" + serverHandshakeResponse);
			}
			
			// Slice off the trailing \r\n\r\n from the handshake data
			serverHandshakeResponse = serverHandshakeResponse.slice(0, headersTerminatorIndex);
			
			var lines:Array = serverHandshakeResponse.split(/\r?\n/);

			// Validate status line
			var responseLine:String = lines.shift();
			var responseLineMatch:Array = responseLine.match(/^(HTTP\/\d\.\d) (\d{3}) ?(.*)$/i); 
			if (responseLineMatch.length === 0) {
				failHandshake("Unable to find correctly-formed HTTP status line.");
				return;
			}
			var httpVersion:String = responseLineMatch[1];
			var statusCode:int = parseInt(responseLineMatch[2], 10);
			var statusDescription:String = responseLineMatch[3];
			if (debug) {
				logger("HTTP Status Received: " + statusCode + " " + statusDescription);
			}
			
			// Verify correct status code received
			if (statusCode !== 101) {
				failHandshake("An HTTP response code other than 101 was received.  Actual Response Code: " + statusCode + " " + statusDescription);
				return;
			}

			// Interpret HTTP Response Headers
			serverExtensions = [];
			try {
				while (lines.length > 0) {
					responseLine = lines.shift();
					var header:Object = parseHTTPHeader(responseLine);
					var lcName:String = header.name.toLocaleLowerCase();
					var lcValue:String = header.value.toLocaleLowerCase();
					if (lcName === 'upgrade' && lcValue === 'websocket') {
						upgradeHeader = true;
					}
					else if (lcName === 'connection' && lcValue === 'upgrade') {
						connectionHeader = true;
					}
					else if (lcName === 'sec-websocket-extensions' && header.value) {
						var extensionsThisLine:Array = header.value.split(',');
						serverExtensions = serverExtensions.concat(extensionsThisLine);
					}
					else if (lcName === 'sec-websocket-accept') {
						var byteArray:ByteArray = new ByteArray();
						byteArray.writeUTFBytes(base64nonce + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11");
						var expectedKey:String = Base64.encodeByteArray(new SHA1().hash(byteArray));
						if (debug) {
							logger("Expected Sec-WebSocket-Accept value: " + expectedKey);
						}
						if (header.value === expectedKey) {
							keyValidated = true;
						}
					}
					else if(lcName === 'sec-websocket-protocol') {
						if (_protocols) {
							for each (var protocol:String in _protocols) {
								if (protocol == header.value) {
									_serverProtocol = protocol;
								}
							}
						}
					}
				}
			}catch(e:Error) {
				failHandshake("There was an error while parsing the following HTTP Header line:\n" + responseLine);
				return;
			}
			
			if (!upgradeHeader) {
				failHandshake("The server response did not include a valid Upgrade: websocket header.");
				return;
			}
			if (!connectionHeader) {
				failHandshake("The server response did not include a valid Connection: upgrade header.");
				return;
			}
			if (!keyValidated) {
				failHandshake("Unable to validate server response for Sec-Websocket-Accept header.");
				return;
			}

			if (_protocols && !_serverProtocol) {
				failHandshake("The server can not respond in any of our requested protocols");
				return;
			}
			
			if (debug) {
				logger("Server Extensions: " + serverExtensions.join(' | '));
			}
			
			// The connection is validated!!
			handshakeTimer.stop();
			handshakeTimer.reset();
			
			serverHandshakeResponse = null;
			_readyState = WebSocketState.OPEN;
			
			// prepare for first frame
			curFrame = new WebSocketFrame();
			frameQueue = new Vector.<WebSocketFrame>();
			
			dispatchEvent(new WebSocketEvent(WebSocketEvent.OPEN));
			
			// Start reading data
			handleSocketData();
			return;
		}
		
		/** 握手等待超时，默认10秒 */
		private function handleHandshakeTimer(event:TimerEvent):void {
			failHandshake("Timed out waiting for server response.");
		}
		
		private function parseHTTPHeader(line:String):Object {
			var header:Array = line.split(/\: +/);
			return header.length === 2 ? {
				name: header[0],
				value: header[1]
			} : null;
		}
		
		// Return true if the header is completely read
		private function readHandshakeLine():Boolean {
			var char:String;
			while (socket.bytesAvailable) {
				char = socket.readMultiByte(1, 'us-ascii');
				handshakeBytesReceived ++;
				serverHandshakeResponse += char;
				if (char == "\n") {
					return true;
				}
			}
			return false;
		}
		
		private function dispatchClosedEvent(msg:String):void {
			if (handshakeTimer.running) {
				handshakeTimer.stop();
			}
			if (_readyState !== WebSocketState.CLOSED) {
				_readyState = WebSocketState.CLOSED;
				var e:WebSocketEvent = new WebSocketEvent(WebSocketEvent.CLOSED);
				e.message = new WebSocketMessage();
				e.message.utf8Data = msg;
				dispatchEvent(e);
			}
		}
				
	}
}
