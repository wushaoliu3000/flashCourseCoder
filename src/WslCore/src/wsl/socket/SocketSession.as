package wsl.socket{
	import flash.display.Sprite;
	import flash.events.EventDispatcher;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import wsl.core.Global;
	import wsl.protocols.IProtocolDef;
	
	/** 功能：维护多组协议侦听器，把自己添加到WebSocketConnect连接中并在此连接上发送与接收协议，把协议转发到对应的侦听器中。<br> 
	 * socket协议解析 socket对象的封包、解包、打印<br>
	 * protocolsPath 协议对象定义的包路径，此包中包含所有与protocolXMLPath文档中定义对应的所有协议对象<br>
	 * protocolXML  协议定义的XML文档类,必须继承IProtocolXML接口<br>
	 * root 被加载swf的根对象,以用获取loaderInfo以便获取协议定义<br>
	 * socketSessionId 包函SocketSession对象的swf模块的Id<br>
	 * connect WebSocketConnect的实例， 默认为Global.connect所指向的实例 */
	public class SocketSession extends EventDispatcher {
		/** 存储已经注册的协议侦听器 */
		private var protocolList:Dictionary = new Dictionary();
		/** 协议解析类 */
		private var pp:ProtocolParse;
		/** 添加到此Session上的协议侦听都通过此联接传到服务器  */
		private var connect:SocketConnect;
		
		/** 每一个包函SocketSession对象的swf模块都有一个socketSessionId，这样在SocketConnect.handSocketSession中
		 * 转发消息时，只转发给与socketSessionId对应的SocketSession对象，即只有与与socketSessionId对应swf模块能收到消息<br>
		 *  socketSessionId=0为服务器端发送MessageTip协议所用,因此socketSessionId为0的模块必须处理MessageTip协议，
		 * 一般设置主模块中的SocketSession的socketSessionId=0*/
		public var socketSessionId:int;
		
		/** 功能：维护多组协议侦听器，把自己添加到WebSocketConnect连接中并在此连接上发送与接收协议，把协议转发到对应的侦听器中。<br> 
		 * socket协议解析 socket对象的封包、解包、打印<br>
		 * protocolsPath 协议对象定义的包路径，此包中包含所有与protocolXMLPath文档中定义对应的所有协议对象<br>
		 * protocolXML  协议定义的XML文档类,必须继承IProtocolXML接口<br>
		 * root 被加载swf的根对象,以用获取loaderInfo以便获取协议定义<br>
		 * socketSessionId 包函SocketSession对象的swf模块的Id<br>
		 * connect WebSocketConnect的实例， 默认为Global.connect所指向的实例 */
		public function SocketSession(protocolPath:String, protocolXML:IProtocolDef, root:Sprite, socketSessionId:uint, connect:SocketConnect){
			this.socketSessionId = socketSessionId;
			this.connect = connect;
			if(connect != null){
				//将SocketSession实例及ProtocolParse实例添加到WebSocketConnect中，以便接收并解析socket数据
				pp = new ProtocolParse(protocolPath, protocolXML, root);
				connect.setProtocolParse(pp);
				connect.addSocketSession(this);
			}else{
				throw Error("请提供有效的SocketConnect实例！");
			}
		}
		
		/** 返回协议解析器 */
		public function getProtocolParse():ProtocolParse{
			return pp;
		}
		
		
		//-------------------------------------Websocket二进制协议同步------------------------------------------------
		/**发送数据到一个特定的socket连接。<br> 
		 * protocolName 要同步协议的名称。<br>
		 * inst 要同步协议的对象。<br>
		 * socketId 要同步已经连接的socket对象的id。<br>
		 * self 是否同步给自己, 默认值是false。<br>
		 * toGroup 消息要发送到的组。<br>
		 * sessionId 另一方接收消息的sessionId，每一个sessionId对应一个Swf模块，
		 * 也就是说sessionId指定了要把消息发送到那个Swf模块，主模块的sessionId=0。 默认值-1表示同步到当前发送消息的模块。*/
		public function sendToSingle(protocolName:String, inst:*, socketId:int, toGroup:int=-1, self:Boolean=false, sessionId:int=-1):void{
			toGroup = toGroup == -1 ? Global.group : toGroup;
			sessionId = sessionId == -1 ? socketSessionId : sessionId;
			var type:int = self ? SyncType.SEND_SIGNLE_SELF : SyncType.SEND_SIGNLE;
			var ba:ByteArray = pp.encodeProtocol(protocolName, inst, type, ""+socketId, toGroup, Global.group, Global.myId, Global.myName, sessionId);
			connect.sendProtocol(ba);
		}
		
		/** 发送数据到一组已经连接的socket对象 。只能在自己所在的分组中选择要发送消息的人<br>
		 * protocolName 要同步协议的名称。<br>
		 * inst 要同步协议的对象。<br>
		 * vec 要同步已经连接的socket对象的一组id。<br>
		 * self 是否同步给自己, 默认值是false。<br>
		 * toGroup 消息要发送到的组。<br>
		 * sessionId 另一方接收消息的sessionId，每一个sessionId对应一个Swf模块，
		 * 也就是说sessionId指定了要把消息发送到那个Swf模块，主模块的sessionId=0。
		 * 默认值-1表示同步到当前发送消息的模块。*/
		public function sendToSelected(protocolName:String, inst:*, vec:Vector.<int>, toGroup:int=-1, self:Boolean=false, sessionId:int=-1):void{
			var data:String = "";
			for(var i:uint=0; i<vec.length; i++){
				data +=  i == vec.length-1 ? ""+ vec[i] : vec[i]+"::";
			}
			toGroup = toGroup == -1 ? Global.group : toGroup;
			sessionId = sessionId == -1 ? socketSessionId : sessionId;
			var type:int = self ? SyncType.SEND_SELECTED_SELF : SyncType.SEND_SELECTED;
			var ba:ByteArray = pp.encodeProtocol(protocolName, inst, type, data, toGroup, Global.group, Global.myId, Global.myName, sessionId);
			connect.sendProtocol(ba);
		}
		
		/** 在一个组中同步。<br>
		 * protocolName 要同步协议的名称。<br>
		 * inst 要同步协议的对象。<br>
		 * self 是否同步给自己, 默认值是false。<br>
		 * toGroup 消息要发送到的组。 默认值-1表示自己所在的组<br>
		 * sessionId 另一方接收消息的sessionId，每一个sessionId对应一个Swf模块，
		 * 也就是说sessionId指定了要把消息发送到那个Swf模块，主模块的sessionId=0。
		 * 默认值-1表示同步到当前发送消息的模块。*/
		public function sendToGroup(protocolName:String, inst:*, toGroup:int=-1, senderId:int=-1, self:Boolean=false, sessionId:int=-1):void{
			toGroup = toGroup == -1 ? Global.group : toGroup;
			sessionId = sessionId == -1 ? socketSessionId : sessionId;
			var type:int = self ? SyncType.SEND_GROUP_SELF : SyncType.SEND_GROUP;
			var ba:ByteArray = pp.encodeProtocol(protocolName, inst, type, "", toGroup, Global.group, senderId, Global.myName, sessionId);
			connect.sendProtocol(ba);
		}
		
		/** 发送数据到所有已经连接的socket对象。<br>
		 * protocolName 要同步协议的名称。<br>
		 * inst 要同步协议的对象。<br>
		 * self 是否同步给自己, 默认值是false。<br>
		 * sessionId 另一方接收消息的sessionId，每一个sessionId对应一个Swf模块，
		 * 也就是说sessionId指定了要把消息发送到那个Swf模块，主模块的sessionId=0。
		 * 默认值-1表示同步到当前发送消息的模块。 */
		public function sendToAll(protocolName:String, inst:*, self:Boolean=false, sessionId:int=-1):void{
			sessionId = sessionId == -1 ? socketSessionId : sessionId;
			var type:int = self ? SyncType.SEND_ALL_SELF : SyncType.SEND_ALL;
			var ba:ByteArray = pp.encodeProtocol(protocolName, inst, type, "", Global.group, Global.group, Global.myId, Global.myName, sessionId);
			connect.sendProtocol(ba);
		}
		
		/** 发送数据给服务器端的socket连接对象。<br>
		 * protocolName 要同步协议的名称。<br>
		 * inst 要同步协议的对象。<br>
		 * self 是否同步给自己, 默认值是false。<br>
		 * sessionId 另一方接收消息的sessionId，每一个sessionId对应一个Swf模块，
		 * 也就是说sessionId指定了要把消息发送到那个Swf模块，主模块的sessionId=0。
		 * 默认值-1表示同步到当前发送消息的模块。*/
		public function sendToServer(protocolName:String, inst:*, self:Boolean=false, sessionId:int=-1):void{
			sessionId = sessionId == -1 ? socketSessionId : sessionId;
			var type:int = self ? SyncType.SEND_SERVER_SELF : SyncType.SEND_SERVER;
			var ba:ByteArray = pp.encodeProtocol(protocolName, inst, type, "", Global.group, Global.group, Global.myId, Global.myName, sessionId);
			connect.sendProtocol(ba);
		}
		
		/** 发送一个协议给所有的服务员。<br>
		 * protocolName 要同步协议的名称。<br>
		 * inst 要同步协议的对象。<br>
		 * self 是否同步给自己, 默认值是false。 */
		public function sendToWaiter(protocolName:String, inst:*, self:Boolean=false):void{
			var type:int = self ? SyncType.SEND_WAITER_SELF : SyncType.SEND_WAITER;
			var ba:ByteArray = pp.encodeProtocol(protocolName, inst, type, "", Global.group, Global.group, Global.myId, Global.myName, socketSessionId);
			connect.sendProtocol(ba);
		}
		
		/** 发送一个协议给指定的厨师。<br>
		 * protocolName 要同步协议的名称。<br>
		 * inst 要同步协议的对象。<br>
		 * chefName 要接收协议的厨师的名字。
		 * self 是否同步给自己, 默认值是false。 */
		public function sendToChef(protocolName:String, inst:*, chefName:String, self:Boolean=false):void{
			var type:int = self ? SyncType.SEND_CHEF_SELF : SyncType.SEND_CHEF;
			var ba:ByteArray = pp.encodeProtocol(protocolName, inst, type, chefName, Global.group, Global.group, Global.myId, Global.myName, socketSessionId);
			connect.sendProtocol(ba);
		}
		//----------------------------------------------------------------------------------------------
		
		
		
		//-----------------------------------二进制协议同步-------------------------------------------------
		/** 向指定的socket连接发送一个as3协议<br> 
		 * protocolName 要同步协议的名称。<br>
		 * inst 要同步协议的对象。<br>
		 * socketId 要同步已经连接的socket对象的id。<br>
		 * group 协议发送者所在的组。
		 * self 是否同步给自己, 默认值是false。<br>
		 * sessionId 另一方接收消息的sessionId，每一个sessionId对应一个Swf模块，
		 * 也就是说sessionId指定了要把消息发送到那个Swf模块，主模块的sessionId=0。
		 * 默认值-1表示同步到当前发送消息的模块。*/
		public function syncToSingle(protocolName:String, inst:Object, socketId:int=-1, toGroup:int=-1, self:Boolean=false, sessionId:int=-1):void{
			toGroup = toGroup == -1 ? Global.group : toGroup;
			sessionId = sessionId == -1 ? socketSessionId : sessionId;
			var type:int = self ? SyncType.SYNC_SIGNLE_SELF : SyncType.SYNC_SIGNLE;
			var bytes:ByteArray = pp.encodeProtocol(protocolName, inst, type, ""+socketId, toGroup, Global.group, Global.myId, Global.myName, sessionId);
			connect.sendByteArray(bytes);
		}
		
		/** 在一个分组中同步As3Socket协议<br>
		 * protocolName 要同步协议的名称。<br>
		 * inst 要同步协议的对象。<br>
		 * self 是否同步给自己, 默认值是false。<br>
		 * toGroup 服务器边的分组标识。<br>
		 * sessionId 另一方接收消息的sessionId，每一个sessionId对应一个Swf模块，
		 * 也就是说sessionId指定了要把消息发送到那个Swf模块，主模块的sessionId=0。默认值-1表示同步到当前发送消息的模块。<br>*/
		public function syncToGroup(protocolName:String, inst:Object, toGroup:int=-1, self:Boolean=false, sessionId:int=-1):void{
			toGroup = toGroup == -1 ? Global.group : toGroup;
			sessionId = sessionId == -1 ? socketSessionId : sessionId;
			var type:int = self?SyncType.SYNC_GROUP_SELF : SyncType.SYNC_GROUP;
			var bytes:ByteArray = pp.encodeProtocol(protocolName, inst, type, "", toGroup, Global.group, Global.myId, Global.myName, sessionId);
			connect.sendByteArray(bytes);
		}
		
		/** 向服务器控制器同步As3Socket协议<br>
		 * protocolName 要同步协议的名称。<br>
		 * inst 要同步协议的对象。<br>
		 * self 是否同步给自己, 默认值是false。<br>
		 * sessionId 另一方接收消息的sessionId，每一个sessionId对应一个Swf模块，
		 * 也就是说sessionId指定了要把消息发送到那个Swf模块，主模块的sessionId=0。默认值-1表示同步到当前发送消息的模块。<br>*/
		public function syncToServer(protocolName:String, inst:Object, self:Boolean=false, sessionId:int=-1):void{
			sessionId = sessionId == -1 ? socketSessionId : sessionId;
			var type:int = self ? SyncType.SYNC_SERVER_SELF : SyncType.SYNC_SERVER;
			var bytes:ByteArray = pp.encodeProtocol(protocolName, inst, type, "", Global.group, Global.group, Global.myId, Global.myName, sessionId);
			connect.sendByteArray(bytes);
		}
		//-----------------------------------------------------------------------------------------------
		
		
		
		//------------------------------------------协议注册与侦听--------------------------------------------
		/** 向SocketSession对象上添加协议侦听器 */
		public function addProtocolListener(protocolName:String, listener:Function):Boolean{
			if(hasProtocolListener(protocolName, listener) == true) return false;
			
			var listenerList:Vector.<Function> =  protocolList[protocolName] as Vector.<Function>;
			
			if(listenerList == null){
				listenerList = new Vector.<Function>();
				protocolList[protocolName] = listenerList;
			}
			listenerList.push(listener);
			
			return true;
		}
		
		/** 删除SocketSession对象上注册的协议侦听器 */
		public function removeProtocolListener(protocolName:String, listener:Function):Boolean{
			if(hasProtocolListener(protocolName, listener) == false) return false;
			
			var listenerList:Vector.<Function> =  protocolList[protocolName];
			for(var i:uint=0; i<listenerList.length; i++){
				if(listenerList[i] == listener){
					listenerList.splice(i, 1);
					break;
				}
			}
			
			if(listenerList.length == 0){
				protocolList[protocolName] = null;
				delete protocolList[protocolName];
			}
			
			return true;
		}
		
		/** 检察SocketSession对象上是否注册过某个协议侦听器 */
		public function hasProtocolListener(protocolName:String, listener:Function):Boolean{
			var has:Boolean = false;
			
			var listenerList:Vector.<Function> =  protocolList[protocolName];
			if(listenerList == null) return false;
			
			for(var i:uint=0; i<listenerList.length; i++){
				if(listenerList[i] == listener){
					has = true;
					break;
				}
			}
			
			return has;
		}
		
		/** 检察SocketSession对象上是否注册过protocolName协议 */
		public function hasProtocol(protocolName:String):Boolean{
			return protocolList[protocolName] == null ? false : true;
		}
		
		/** 触发SocketSession对象上的某类协议侦听器 */
		public function dispatchProtocolListener(protocolName:String, protocolObj:*):void{
			var listenerList:Vector.<Function> =  protocolList[protocolName];
			if(listenerList == null) return;
			
			for(var i:uint=0; i<listenerList.length; i++){
				listenerList[i](protocolObj);
			}
		}
		
		/** 删除SocketSession上所注册的所有侦听器 */
		public function removeAllProtocolListener():void{
			for each(var listenerList:Vector.<Function> in protocolList){
				listenerList = null;
			}
			protocolList = new Dictionary();
		}
		
		/** 解析并执行协议，在SocketConnect中调用<br>
		 * 当包函此SocketSession的swf模块被加载时，SocketSession将被添加到SocketConnect中 */
		public function handProtocol(protocol:Protocol):void{
			dispatchProtocolListener(protocol.name, protocol);
		}
		
		/** 销毁，以免存在占用 */
		public function destroy():void{
			removeAllProtocolListener();
			protocolList = null;
			pp = null;
			connect.removeSocketSession(this);
		}
	}
}