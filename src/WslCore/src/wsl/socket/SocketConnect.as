package wsl.socket{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import wsl.core.Debug;
	import wsl.events.WslEvent;
	import wsl.protocols.MessageTipSP;
	import wsl.socket.websocket.WebSocket;
	import wsl.socket.websocket.WebSocketErrorEvent;
	import wsl.socket.websocket.WebSocketEvent;
	import wsl.socket.websocket.WebSocketMessage;
	
	/** 此类为单例<br>
	 * 功能：1、连接Socket服务器,接收与发送socket协议字节数组到socket服务器。2、管理各个模块会话对象SocketSession的注册与删除。<br>
	 * 一个协议只对应到一个模块中执行，当此类收到协议数据时，先解析协议头，在协议头找到协议执行的模块ID，如果此模块存在就执行。<br>
	 * 解析协议头，如果是MessageTip协议与MessageTip.type=1(错误提示)，直接输出，不在像swf模块转发。
	 * 否则，则转发到ProtocolHead.sessionId指定的SocketSession对象中。<br> */
	public class SocketConnect extends EventDispatcher{
		/** 服务器连接失败或身份验证没有通过 */ 
		static public const CONNECT_FAIL:String = "connect_fail";
		
		/** WebSocket服务器的IP或域名 */
		private var host:String;
		/** WebSocket服务器的侦听端口 */
		private var port:int;
		/** WebSocket实例，连接WebSocket服务器 */
		private var websocket:WebSocket;
		/** WebSocket协议解析类SocketProtocolParse */
		private var pp:ProtocolParse;
		/** 一个Dictionary词典对象,用于保存当前所有的SocketSession对象，每一个SocketSession都是一个游戏子模块的会话通信对象，
		 * 也就是说，每一个游戏子模块都有一个SocketSession实例。*/
		private var socketSessionDir:Dictionary;
		/** 每隔5分钟向服务器送发一个ping，以免服务器断开连接 */
		private var timer:Timer;
		
		private var isDispatch:Boolean;
		
		/** 此类为单例<br>
		 * 功能：1、连接Socket服务器,接收与发送socket协议字节数组到socket服务器。2、管理各个模块会话对象SocketSession的添加与删除。
		 * 处理MessageTipSP.type=1的消息。<br>
		 * 一个协议只对应到一个模块中执行，当此类收到协议数据时，先解析协议头，在协议头找到协议执行的模块ID，如果此模块存在就执行。<br>
		 * 解析协议头，如果是MessageTip协议与MessageTip.type=1(错误提示)，直接输出，不在像swf模块转发。
		 * 否则，则转发到ProtocolHead.sessionId指定的SocketSession对象中。<br> */
		public function SocketConnect(){
			socketSessionDir = new Dictionary();
		} 
		
		public function connect(host:String, port:int):void{
			this.host = host;
			this.port = port;
			if(websocket == null){
				websocket = new WebSocket("ws://"+host+":"+port+"?name=wsl", "*", "JSON");
				websocket.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
				websocket.addEventListener(WebSocketEvent.CLOSED, closedHandler);
				websocket.addEventListener(WebSocketEvent.OPEN, openHandler);
				websocket.addEventListener(WebSocketEvent.MESSAGE, msgHandler);
				websocket.addEventListener(WebSocketEvent.RECEIVE_BYTE_ARRAY, receiveByteArrayHandler);
				websocket.addEventListener(WebSocketErrorEvent.CONNECTION_FAIL, errorEventHandler);
			}
			isDispatch = false;
			websocket.connect(host, port);
		}
		
		private function timerHandler(e:TimerEvent):void{
			websocket.ping();
		}
		
		private function delTiemr():void{
			if(timer){
				timer.stop();
				timer.removeEventListener(TimerEvent.TIMER, timerHandler);
				timer = null;
			}
		}
		
		public function get connected():Boolean{
			if(websocket == null) return false;
			return websocket.connected;
		}
		
		public function close():void{
			websocket.close(false);
		} 
		
		private function openHandler(e:WebSocketEvent):void{
			this.dispatchEvent(new Event(Event.CONNECT));
			//每隔5分钟向服务器发送一个ping
			timer = new Timer(300000);
			timer.addEventListener(TimerEvent.TIMER, timerHandler);
			timer.start();
		}
		
		private function closedHandler(e:WebSocketEvent):void{
			dispatchFailEvent("连接被断开");
			delTiemr();
		}
		
		private function errorEventHandler(e:WebSocketErrorEvent):void{
			dispatchFailEvent("网速太慢，连接失败");
			delTiemr();
		}
		
		private function ioErrorHandler(e:IOErrorEvent):void{
			dispatchFailEvent("网络故障");
			delTiemr();
		}
		
		private function dispatchFailEvent(tipStr:String):void{
			if(isDispatch == false){
				isDispatch = true;
				dispatchEvent(new WslEvent(CONNECT_FAIL, tipStr));
			}
		}
		
		/** 获取webWocket实例 */
		public function getWebSokcet():WebSocket{
			return websocket;
		}
		
		/** 收到的是WebSocket协议 。 */
		private function msgHandler(e:WebSocketEvent):void {
			if (e.message.type === WebSocketMessage.TYPE_UTF8) {
				//handWebSocketSession(e.message.utf8Data);
			}else if (e.message.type === WebSocketMessage.TYPE_BINARY) {
				handleProtocol(e.message.binaryData);
			}
		}
		
		/** 收到的是As3Socket协议 */
		private function receiveByteArrayHandler(e:WebSocketEvent):void{
			handleProtocol(e.ba);
		}
		
		/** 发送WebSocket协议二进制到服务器 */
		public function sendProtocol(ba:ByteArray):void {
			if(websocket.connected == false){
				return;
			}
			websocket.sendBytes(ba);
		}
		
		/** 发送ByteArray数据 */
		public function sendByteArray(ba:ByteArray):void{
			if(websocket.connected == false){
				return;
			}
			websocket.sendByteArray(ba);
		}
		
		/** 设置协议解析实例 */
		public function setProtocolParse(pp:ProtocolParse):void{
			this.pp = pp;
		}
		
		/** 添加一个SocketSession对象，以便当接收到服务器信息时，能触发与SocketSession对象关联的swf模块中
		 *  添加到SocketSession上的协议侦听器<br>
		 *  一个SocketSession对象的添加，一般在swf模块被加载时<br>
		 * 一个要与服务器有Socket通信的模块，要包函一个SocketSession */
		public function addSocketSession(socketSession:SocketSession):void{
			if(socketSessionDir[socketSession.socketSessionId] != null){
				Debug.alert("socketSessionId = "+socketSession.socketSessionId+"已经存在！");
				return;
			}
			socketSessionDir[socketSession.socketSessionId] = socketSession;
		}
		
		/** 删除指定的SocketSession对象<br>
		 *  移除一个SocketSession对象,一般在swf模块被卸载<br>
		 * 一个要与服务器有Socket通信的模块，要包函一个SocketSession */
		public function removeSocketSession(socketSession:SocketSession):void{
			socketSessionDir[socketSession.socketSessionId] = null;
			delete socketSessionDir[socketSession.socketSessionId];
		}
		
		
		/** 处理收到的WebSocket数据<br>
		 * 解析协议头，如果是MessageTip协议与MessageTip.type=1(错误提示)，直接输出，不在像swf模块转发。
		 * 否则，则转发到ProtocolHead.socketSessionId指定的SocketSession对象中*/
		public function handleProtocol(ba:ByteArray):void{
			var head:ProtocolHead = ProtocolParse.decodeProtocolHead(ba);
			var p:Protocol;
			//假如是错误信息，直接提示，不向各个SocketSession模块转发
			if(head.name == MessageTipSP.NAME){
				ba.position = 0;
				p = pp.decodeProtocol(ba);
				var msg:MessageTipSP = p.body as MessageTipSP;
				//假如是错误类型消息，关闭socket连接，显示错误提示。
				if(msg.type == 1){
					dispatchFailEvent(msg.message);
					websocket.close();
					return;
				}
			}
			//检察是否注册过protocolName对应的侦听，如果没有就没有必要执行handProtocol
			var socketSession:SocketSession = socketSessionDir[head.sessionId] as SocketSession;
			if(socketSession && socketSession.hasProtocol(head.name)){
				p = pp.decodeProtocol(ba);
				socketSession.handProtocol(p);
			}
		}
	}
}

