package wsl.core{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import wsl.protocols.IProtocolDef;
	import wsl.protocols.MessageTipSP;
	import wsl.protocols.SyncOnlineUserSP;
	import wsl.protocols.VerifyInfoSP;
	import wsl.socket.Protocol;
	import wsl.socket.SocketConnect;
	import wsl.socket.SocketSession;
	import wsl.view.onlineuser.OnlineUserView;
	
	/** 这是一个辅助开发类，用于在swf模块中连接WebSocket服务器，以便swf模块可单独调试。<br>
	 * 功能：连接服务器，发送验证信息。 */
	public class ConnectWebSocketServer extends EventDispatcher{
		/** socket服务器连接成功并且通过身份验证 */
		static public const CONNECT_FINISH:String = "connect_finish";
		private var isLocal:Boolean;
		private var protocolXML:IProtocolDef;
		private var root:Sprite;
		private var packagePath:String;
		
		/** 这是一个辅助开发类，用于在swf模块中连接WebSocketServer服务器，以便swf模块可单独调试。 <br>
		 * isLocal 是否是连接本地集成的WebSocketServer服务器。<br>
		 * protocolXML 包函会话协议的XML定义。<br>
		 * root 被加载swf模块的根对象,用以获取loaderInfo以便获取协议定义。<br>
		 * packagePath 协议所在的包路径。*/
		public function ConnectWebSocketServer(isLocal:Boolean=false, protocolXML=null, root:Sprite=null, packagePath:String=""){
			this.isLocal = isLocal;
			this.protocolXML = protocolXML;
			this.root = root;
			this.packagePath = packagePath;
			
			Global.socketConnect = new SocketConnect();
			Global.socketConnect.addEventListener(Event.CONNECT, connectedHandler);
		}
		
		public function connect(host:String, port:int):void{
			Global.socketConnect.connect(host, port);
		}
		
		public function get connected():Boolean{
			return Global.socketConnect.connected;
		}
		
		/** SocketConnect与服务器对接成功，创建会话对象 */
		private function connectedHandler(e:Event):void{
			if(Global.session == null){
				//创建一个SocketSession对象
				Global.session = new SocketSession(packagePath, protocolXML, root, 0, Global.socketConnect);
				//侦听服务器返回的消息提示协议
				Global.session.addProtocolListener(MessageTipSP.NAME, msgTipHandler);
				if(Global.netModule == Global.LOCAL_CONNECT){
					//侦听服务器发送的同步在线用户协议
					Global.session.addProtocolListener(SyncOnlineUserSP.NAME, syncOnlineUserHandler);
				}
			}
			//发送验证信息，等待服务器的验证结果
			verifyInfo();
		}
		
		/** 发送验证信息，等待服务器的验证结果 */
		private function verifyInfo():void{
			var verifyInfo:VerifyInfoSP = new VerifyInfoSP();
			verifyInfo.name = Global.loginName;
			verifyInfo.password = Global.password;
			verifyInfo.group = Global.group;
			verifyInfo.serverId = "";
			
			Global.session.addProtocolListener(VerifyInfoSP.NAME, verifySuccessHandler);
			Global.session.sendToServer(VerifyInfoSP.NAME, verifyInfo);
			Global.setLoadingTitle("验证本地连接");
		}
		
		/** 用户信息身份验证成功 */
		private function verifySuccessHandler(sp:Protocol):void{
			Global.session.removeProtocolListener(VerifyInfoSP.NAME, verifySuccessHandler);
			
			//身份验证通过，保存验证信息
			var verifyInfo:VerifyInfoSP = sp.body as VerifyInfoSP;
			Global.myId = parseInt(verifyInfo.password);
			Global.myName = verifyInfo.name;
			Global.type = verifyInfo.type;
			Global.group = verifyInfo.group;
			Global.serverId = verifyInfo.serverId;
			
			//发送Socket连接完成
			dispatchEvent(new Event(CONNECT_FINISH));
		}
		
		/** 同步在线的所有玩家，当服务器端有玩家上线或下线时处发此方法 */
		private function syncOnlineUserHandler(sp:Protocol):void{
			var syncOnlineUser:SyncOnlineUserSP = sp.body as SyncOnlineUserSP;
			//当服务器在线人数变化时，重新保存
			OnlineUserView.getInstance().addUsers(syncOnlineUser.allOnlineUser);
		}
		
		/** 服务器返回的信息提示侦听器，type == 1的情况直接在SocketConnect中处理了 */
		private function msgTipHandler(sp:Protocol):void{
			var msg:MessageTipSP = sp.body as MessageTipSP;
			if(msg.type == 2){
			}else if(msg.type == 3){
			}
		}
	}
}