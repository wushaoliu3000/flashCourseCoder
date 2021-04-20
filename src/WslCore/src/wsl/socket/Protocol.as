package wsl.socket{
	public class Protocol{
		private var _protocolName:String;
		private var _protocolBody:*;
		private var _sessionId:int;
		private var _syncType:int;
		private var _data:String;
		private var _group:int;
		private var _toGroup:int;
		private var _senderId:int;
		private var _senderName:String;
		
		/** 通信协议类，包括协议名与协议体 */
		public function Protocol(){
		}
		
		/** 协议体 */
		public function get body():*{
			return _protocolBody;
		}
		public function set body(value:*):void{
			_protocolBody = value;
		}
     
		/** 协议名 */
		public function get name():String{
			return _protocolName;
		}
		public function set name(value:String):void{
			_protocolName = value;
		}
		
		/** 每一个swf模块的SocketSession对象都有一个socketSessionId，这样在SocketConnect.handSocketSession中
		 * 转发消息时，可以只转发给与socketSessionId对应的SocketSession对象<br>
		 *  socketSessionId=0为MessageTip所用,在SocketConnect.handSocketSessio中处理*/
		public function get sessionId():int{
			return _sessionId;
		}
		
		public function set sessionId(value:int):void{
			_sessionId = value;
		}

		/** 当 客户端-->服务器 时：表示要转发的范围，在SyncType中定义 。*/
		public function get syncType():int{
			return _syncType;
		}
		public function set syncType(value:int):void{
			_syncType = value;
		}

		/** 当 客户端-->服务器 时：表示要转发的一个或一组id。 */
		public function get data():String{
			return _data;
		}
		public function set data(value:String):void{
			_data = value;
		}

		/** 对应服务器上的一个分组 */
		public function get group():int{
			return _group;
		}
		public function set group(value:int):void{
			_group = value;
		}
		
		/** 要发消息到某个特定用户时，该用户所在的组 */
		public function get toGroup():int{
			return _toGroup;
		}
		public function set toGroup(value:int):void{
			_toGroup = value;
		}
		
		/** 协议发送者的id */
		public function get senderId():int{
			return _senderId;
		}
		public function set senderId(value:int):void{
			_senderId = value;
		}
		
		/** 协议发送都的名称 */
		public function get senderName():String{
			return _senderName;
		}
		public function set senderName(value:String):void{
			_senderName = value;
		}
	}
}