package wsl.socket{
	import com.hurlant.crypto.hash.SHA1;
	import com.hurlant.util.Base64;
	
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.events.ServerSocketConnectEvent;
	import flash.net.ServerSocket;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import wsl.core.UserType;
	import wsl.protocols.MessageTipSP;
	import wsl.protocols.OnlineUserSP;
	import wsl.protocols.SyncOnlineUserSP;
	import wsl.protocols.VerifyInfoSP;
	
	/** 此类仅适用于Air项目 */
	public class SocketServer{
		/** socket连接不活动的最大时间 10分钟，如果超过此时间不活动，此连接将被断开<br>
		 * 收协议与发协议时都会归零此时间 */
		static private const DEACTIVATE_TIME:int = 600000;
		/** 清理不活动连接的时间间隔 2分钟 */
		static private const CLEAR_TIME:int = 120000;
		
		/** 散客所在的分组id(0)，所有不通过桌台（组id=0）连上来的食客，都分配到分组0中 */
		static public const FIT_GROUP_ID:int = 0;
		/** 工作人员(需要登录的人员)登录后返回的组id(30000)，所有的工作人员在同一个组中 */
		static public const SERVER_GROUP_ID:int = 30000;
		
		/** WebSocket协议解析类 */
		private var spp:ProtocolParse;
		/** SHA1编码 */
		private var sha1:SHA1;
		/** 最大用户连接数 */
		private var maxUser:int = 255;
		/** 递增值，每当一个客户连接就加1 */
		private var socketId:uint = 1;
		/** socket服务类 */
		private var serverSocket:ServerSocket;
		/** 保存服务器控制器的Socket连接，方便调用 */
		private var server:Socket;
		/** 存放一帧的字节数据 */
		private var ba:ByteArray;
		
		/** 保存当前连接的Socketer的每一个分组 */
		private var socketerDir:Dictionary;
		/** 验证Socket连接上来的用户，保存超级管理员修改过的用户配置 */
		private var userVerify:IVerify;
		/** 处理同步到服务器的协议，假如提供了此类，则收到同步到服务器的协议时不在转发，直接调用此类来处理。 */
		private var syncServer:ISyncServer;
		
		/** socket所连接服务器的ID，每一个机顶盒有一个唯一的serverId */
		private var serverId:String;
		/** 指向登录管理员的socket */
		private var admin:Socket;
		/** 服务员所在的分组，当食客提交订单时，向该组中的服务员发送向食客确认订单的提示消息。<br>
		 *  食客提交订单，所有服务员都能收到消息。*/
		private var waiterVec:Vector.<Socket>;
		/** 厨师所在的分组，当服务员向食客确认定单并提交后，服务器向对应的厨师转发制作提示 */
		private var chefVec:Vector.<Socket>;
		
		/** 存储服务员所进入到分组的列表 */
		private var appendWaitList:Array;
		
		/** port 服务器的侦听端口。<br>
		 * packagePath 协议对象定义的包路径，此包中包含所有与protocolXMLPath文档中定义对应的所有协议对象。<br>
		 * userVerify 实现了IUserVerify接口的用户验证类实例，用户连接的验证过程在UserVerify类实例中完成。<br> */
		public function SocketServer(port:uint, packagePath:String="", userVerify:IVerify=null, syncServer:ISyncServer=null, serverId:String=""){
			this.userVerify = userVerify;
			this.syncServer = syncServer;
			this.serverId = serverId;
			syncServer.setServer(this);
			
			ba = new ByteArray();
			sha1 = new SHA1();
			spp = new ProtocolParse(packagePath, null, null);
			
			socketerDir = new Dictionary();
			waiterVec = new Vector.<Socket>();
			chefVec = new Vector.<Socket>();
			appendWaitList = new Array();
			
			serverSocket = new ServerSocket();
			serverSocket.bind(port);
			serverSocket.addEventListener(ServerSocketConnectEvent.CONNECT, onConnect);
			serverSocket.listen();
			
			//每隔2分钟清理一次不活动的Socketer
			setTimeout(clearSocketer, CLEAR_TIME);
		}
		
		/** 当有socket连接时执行 */
		private function onConnect(e:ServerSocketConnectEvent):void {
			var socket:Socket = e.socket;
			
			//验证IP的来源
			if(userVerify && userVerify.verifyIP() == false){ socket.close(); return; }
			//验证最大连接数
			if(verifyMaxConnect(socket) == false) return;
			
			//等待客户端的验证信息,待验证通过后，再执行acceptUserConnect方法接收用户连接
			socket.addEventListener(ProgressEvent.SOCKET_DATA, verifyInfoData);
			//如果客户端2秒内没有验证信息上来，关闭此socket连接 
			setTimeout(closeTempSocketConnect, 2000, socket);
		}
		
		/** 关闭临时的Socket连接 */
		private function closeTempSocketConnect(socket:Socket):void{
			var socketerVec:Vector.<Socketer>;
			for(var nm:String in socketerDir){
				socketerVec = socketerDir[nm];
				for(var i:uint=0; i<socketerVec.length; i++){
					if(socketerVec[i].socket == socket){
						return;
					}
				}
			}
			socket.removeEventListener(ProgressEvent.SOCKET_DATA, verifyInfoData);
			sendTipMessage(socket, "socket连接被服务器关闭，因为你没有发送身份验证协议v_v", 1);
		}
		
		/** 验证当前用户连接数是否超过最大设置 */
		private function verifyMaxConnect(socket:Socket):Boolean{
			if(getOnlineUserNum() >= maxUser){
				sendTipMessage(socket, "服务器的Socket连接已满,你不能在连接了！" , 0);
				return false;
			}
			return true;
		}
		
		private function verifyInfoData(e:ProgressEvent):void{
			var socket:Socket = e.target as Socket;
			ba.clear();
			socket.readBytes(ba, 0, socket.bytesAvailable);
			ba.position = 0;
			
			var str:String = ba.readUTFBytes(ba.length);
			if(str.search("Sec-WebSocket-Version:") != -1){
				socket.writeUTFBytes(getHandShakeString(str));
				socket.flush();
				return;
			}else if(str == "<policy-file-request/>"){
				socket.writeUTFBytes(getSecurityString());
				socket.writeByte(0);
				socket.flush();
				return;
			}
			
			var p:String = parseProtocolData(socket, ba);
			if(p != "binary"){
				if(p == "error format" || p == "ping" || p == "pong"){
					return;
				}else if(p == "close socket"){
					//删除临时等待验证信息的侦听
					socket.removeEventListener(ProgressEvent.SOCKET_DATA, verifyInfoData);
					return;
				}
			}else{
				socket.removeEventListener(ProgressEvent.SOCKET_DATA, verifyInfoData);
				var sp:Protocol = spp.decodeProtocol(ba);
			}
			
			if(socket.remoteAddress == "127.0.0.1"){
				//假如是同一程序中的连接(用于服务器控制器的连接)，直接通过
				if(server == null){
					approved(socket, SERVER_GROUP_ID, UserType.ADMIN, "Server");
					server = socket;
				}else{
					refusalUserConnect(socket, UserType.NOW_ONLINE);
					//approved(socket, SERVER_GROUP_ID, UserType.ADMIN, "admin");
				}
			}else if(sp.name != VerifyInfoSP.NAME){
				//假如连接后收到的第一个信息不是用户验证信息，直接关闭此socket连接
				closeSocketConnect(socket);
			}else{
				/**用户连接的验证过程在实现了IUserVerify类的实例中完成。*/
				if(userVerify == null){
					//假如不需要验证，直接通过
					approved(socket, sp.group, UserType.GUEST);
				}else{
					var vInfo:VerifyInfoSP = sp.body as VerifyInfoSP;
					if(vInfo.name == "" && vInfo.password == ""){//假如是食客连接
						if(vInfo.group == FIT_GROUP_ID){
							//散客点餐
							approved(socket, FIT_GROUP_ID, UserType.GUEST);
						}else{
							//桌台点餐
							approved(socket, sp.group, UserType.GUEST);
						}
					}else{//假如是管理人员连接
						var type:String = userVerify.verifyUser(vInfo.name, vInfo.password);
						if(type.indexOf(UserType.ADMIN) != -1){
							//一次只能一个管理员登录
							if(admin != null){
								refusalUserConnect(admin, UserType.ADMIN_EXSIT);
							}
							admin = socket;
							approved(socket, SERVER_GROUP_ID, UserType.ADMIN, vInfo.name);
							return;
						}
						if(type == UserType.PWD_WRONG || type == UserType.NO_USER){
							//拒绝用户连接
							refusalUserConnect(socket, type);
						}else{
							if(type.indexOf(UserType.NOW_ONLINE) != -1){
								downSocketByName(vInfo.name, SERVER_GROUP_ID);
								approved(socket, SERVER_GROUP_ID, type.split("|")[1], vInfo.name);
							}else{
								approved(socket, SERVER_GROUP_ID, type, vInfo.name);
							}
							
							//假如是服务员或厨师
							if(type.indexOf(UserType.WAITER) != -1){
								waiterVec.push(socket);
							}else if(type.indexOf(UserType.CHEF) != -1){
								 chefVec.push(socket);
							}
						}
					}
				}
			}
		}
		
		/** 在指定的分组中添加一个用户，向连接用户发送通过验证的信息 */
		private function approved(socket:Socket, group:int, type:String, nm:String=""):void{
			var verifyInfo:VerifyInfoSP = new VerifyInfoSP();
			//验证通过
			verifyInfo.name = nm == "" ? UserType.GUEST+"_"+socketId : nm;
			verifyInfo.password = ""+socketId;
			verifyInfo.group = group;
			verifyInfo.type = type;
			verifyInfo.serverId = serverId;
			//向连接用户发送难通过的协议
			sendProtocolToMainModule(socket, VerifyInfoSP.NAME, verifyInfo, group);
			//接收用户连接
			acceptUserConnect(socket, verifyInfo.name, socketId, group);
		}
		
		/** 验证不通过，关闭连接<br>
		*  延时，如果不延时客户端可能收不能发送的信息 */
		private function refusalUserConnect(socket:Socket, type:String):void{
			var str:String;
			if(type == UserType.PWD_WRONG){
				str = "密码错误！连接已经被关闭。";
			}else if(type == UserType.NO_USER){
				str = "用户不存在！连接已经被关闭。";
			}else if(type == UserType.NOW_ONLINE){
				str = "服务器控制器已经存在。";
			}else if(type == UserType.ADMIN_EXSIT){
				str = "另一个管理员已经登录，你已经被断开连接，一次只能有一个管理员登录。";
			}
			sendTipMessage(socket, str, 2);
			socket.removeEventListener(ProgressEvent.SOCKET_DATA, verifyInfoData);
		}
		
		/** 接收socket连接 */
		private function acceptUserConnect(socket:Socket, userName:String, userId:int, group:int):void{
			var socketerVec:Vector.<Socketer> = socketerDir["g"+group];
			if(!socketerVec) socketerDir["g"+group] = socketerVec = new Vector.<Socketer>;
			
			socket.addEventListener(ProgressEvent.SOCKET_DATA, onClientSocketData);
			socket.addEventListener(Event.CLOSE, onClientSocketClose);
			
			var socketer:Socketer = new Socketer();
			socketer.userId = userId;
			socketer.userName = userName;
			socketer.socket = socket;
			socketer.group = group;
			
			socketerVec.push(socketer);
			socketId > uint.MAX_VALUE - 1 ? socketId = 1 : socketId++;
			
			//重执活动时间
			resetActivateTiem(socket)
			
			//在一个组中同步在线用户到所有客户端，包括当前连接上来用户
			/*var user:OnlineUserSP = new OnlineUserSP();
			user.userId = userId;
			user.userName = userName;
			user.group = group;
			syncOnlineUser(user, group);*/
		}
		
		/** 同步一个分组的在线用户<br>
		 * 在用户上线、下线时同步在线用户到客户端，包括当前连接上来的用户。<br>
		 * user 当前上线或下线的用户。<br>
		 * group 要同步的分组。 */
		private function syncOnlineUser(user:OnlineUserSP, group:int):void{
			var syncOnlineUser:SyncOnlineUserSP = new SyncOnlineUserSP();
			var onlineUser:OnlineUserSP;
			
			var socketerVec:Vector.<Socketer> = socketerDir["g"+group];
			if(socketerVec == null)	return;
			
			for(var i:uint=0; i<socketerVec.length; i++){
				onlineUser = new OnlineUserSP();
				onlineUser.userName = socketerVec[i].userName;
				onlineUser.userId = socketerVec[i].userId;
				onlineUser.group = socketerVec[i].group;
				syncOnlineUser.allOnlineUser.push(onlineUser);
			}
			
			for(i=0; i<socketerVec.length; i++){
				sendProtocolToMainModule(socketerVec[i].socket, SyncOnlineUserSP.NAME, syncOnlineUser, group);
			}
		}
		
		
		/** 每当收到客户端数据时 */
		private function onClientSocketData(e:ProgressEvent):void {
			var socket:Socket = e.target as Socket;
			var socketer:Socketer = getSocketer(socket);
			var data:SocketData = socketer.getSocketData();
			if(data == null) return;
			
			//重置非服务器控制器的活动时间
			resetActivateTiem(socket);
			
			if(data.type == 1){
				//转发WebSocket协议
				var p:String = parseProtocolData(socket, data.ba);
				if(p != "binary"){
					//webSocket协议是JSON格式
					if(p == "error format" || p == "close socket" || p == "ping" || p == "pong"){
						return;
					}
				}else{
					//webSocket协议是二进制
					syncWebProtocol(socket, data.ba);
				}
			}else if(data.type == 0){
				//同步as3协议，as3协议的前三个字节是"wsl"
				syncAS3Procotol(socket, data.ba);
			}
		}
		
		/** 转发WebSocket协议 */
		private function syncWebProtocol(socket:Socket, protocol:ByteArray):void{
			var group:int;
			var socketer:Socketer;
			var p:ProtocolHead = ProtocolParse.decodeProtocolHead(protocol, 0);
			protocol.position = 0;
			group = p.group;
			
			if(group != SERVER_GROUP_ID && (p.toGroup < 0)){
				sendTipMessage(socket, "服务器返回：错误，请正确指定要接收消息的分组ID！", -1, 2);
				return;
			}
			if(group == SERVER_GROUP_ID && p.toGroup == -1){
				p.toGroup = group;
			}else{
				group = p.toGroup;
			}
			
			switch(p.syncType){
				case SyncType.SEND_SIGNLE :
					sendToSignle(socket, protocol, parseInt(p.data), false, group);
					break;
				case SyncType.SEND_SELECTED :
					sendToSelected(socket, protocol, p.data, false ,group);
					break;
				case SyncType.SEND_ALL :
					sendToAll(socket, protocol, false);
					break;
				case SyncType.SEND_SERVER :
					sendToServer(socket, protocol, false, group);
					break;
				case SyncType.SEND_SIGNLE_SELF :
					sendToSignle(socket, protocol, parseInt(p.data), true, group);
					break;
				case SyncType.SEND_SELECTED_SELF :
					sendToSelected(socket, protocol, p.data, true, group);
					break;
				case SyncType.SEND_ALL_SELF :
					sendToAll(socket, protocol, true);
					break;
				case SyncType.SEND_SERVER_SELF :
					sendToServer(socket, protocol, true, group);
					break;
				case SyncType.SEND_GROUP :
					sendToGroup(socket, protocol, false, group, p.senderId);
					break;
				case SyncType.SEND_GROUP_SELF :
					sendToGroup(socket, protocol, true, group, p.senderId);
					break;
				case SyncType.SEND_WAITER :
					sendToWaiter(protocol, socket, false);
					break;
				case SyncType.SEND_WAITER_SELF :
					sendToWaiter(protocol, socket, true);
					break;
				case SyncType.SEND_CHEF :
					sendToChef(socket, protocol, p.data, false);
					break;
				case SyncType.SEND_CHEF_SELF :
					sendToChef(socket, protocol, p.data, true);
					break;
			}
		}
		
		/**同步娄据到一个已经连接的socket对象<br> 
		 * socket  消息发出者的socket对象<br>
		 * ba 要同步内容的字节数组<br>
		 * id 要同步已经连接的socket对象的id<br>
		 * self 是否同步给自己, 默认值是false 
		 * group 分组ID*/
		private function sendToSignle(socket:Socket, ba:ByteArray, id:int, self:Boolean=false, group:int=-1):void{
			var toSocket:Socket = getSocketById(id, group, socket);
			if(toSocket == null) return;
			if(self && toSocket != socket){
				sendWebSocketBtyes(socket, ba);
			}
			sendWebSocketBtyes(toSocket, ba);
		}
		
		/** 在一个组中，发送协议到部份选定的用户连接 <br>
		 * socket  消息发出者的socket对象<br>
		 * ba 要同步内容的字节数组<br>
		 * data 要收到协议的部分Id<br>
		 * self 是否同步给自己, 默认值是false <br>
		 * group 分组ID */
		private function sendToSelected(socket:Socket, ba:ByteArray, data:String, self:Boolean=false, group:int=-1):void{
			var arr:Array = data.split("::");
			var toSocket:Socket;
			for(var i:uint=0; i<arr.length; i++){
				toSocket = getSocketById(arr[i] ,group, socket);
				if(toSocket == null) continue;
				if(socket == toSocket && self == false){
				}else{
					sendWebSocketBtyes(toSocket, ba);
				}
			}
		}
		
		/** 在一个组中发送协议到所有已经连接的socket对象<br>
		 * socket  消息发出者的socket对象<br>
		 * ba 要同步内容的字节数组<br>
		 * self 是否同步给自己, 默认值是false <br>
		 * group 分组ID */
		private function sendToGroup(socket:Socket, ba:ByteArray, self:Boolean=false, group:int=-1, senderId=-1):void{
			var vec:Vector.<Socketer> = socketerDir["g"+group];
			if(!vec) {sendTipMessage(socket, "服务器返回：错误，你要发送消息的分组不存在，组Id="+group+"!"); return;}
			for(var i:uint=0; i<vec.length; i++){
				if(self == false && (socket == vec[i].socket || senderId == vec[i].userId)){
				}else{
					sendWebSocketBtyes(vec[i].socket, ba);
				}
			}
		}
		
		/** 发送数据到所有已经连接的socket对象，所有组中的连接都能收到。<br>
		 * socket  消息发出者的socket对象<br>
		 * ba 要同步内容的字节数组<br>
		 * self 是否同步给自己, 默认值是false */
		private function sendToAll(socket:Socket, ba:ByteArray, self:Boolean=false):void{
			for each(var vec:Vector.<Socketer> in socketerDir){
				for(var i:uint=0; i<vec.length; i++){
					if(vec[i].socket == socket && self == false){
					}else{
						sendWebSocketBtyes(vec[i].socket, ba);
					}
				}
			}
		}
		
		/** 发送一个协议给服务器控制器<br>
		 * socket  消息发出者的socket对象<br>
		 * ba 要同步内容的字节数组<br>
		 * self 是否同步给自己, 默认值是false <br>
		 * group 分组ID */
		private function sendToServer(socket:Socket, ba:ByteArray, self:Boolean=false, group:int=-1):void{
			if(server == null) { sendTipMessage(socket, "服务器返回：服务器控制器不存在。"); return;}
			sendWebSocketBtyes(server, ba);
		}
		
		/** 发送一个协议给所有的服务员。<br>
		 * socket  消息发出者的socket对象<br>
		 * ba 要同步内容的字节数组<br>
		 * self 是否同步给自己, 默认值是false */
		public function sendToWaiter(ba:ByteArray, socket:Socket=null, self:Boolean=false):void{
			for(var i:uint=0; i<waiterVec.length; i++){
				if(socket != null && self == false && (socket == waiterVec[i])){
				}else{
					sendWebSocketBtyes(waiterVec[i], ba);
				}
			}
		}
		
		/** 发送一个协议给对应的厨师。<br>
		 * socket  消息发出者的socket对象<br>
		 * ba 要同步内容的字节数组<br>
		 * self 是否同步给自己, 默认值是false。<br>
		 * chefName 要接收消息的厨师的名字。 */
		public function sendToChef(socket:Socket, ba:ByteArray, chefName:String, self:Boolean=false):void{
			var vec:Vector.<Socketer> = socketerDir[SERVER_GROUP_ID];
			if(vec == null) return;
			var toSocket:Socket;
			for(var i:uint=0; i<vec.length; i++){
				if(vec[i].userName == chefName){
					toSocket = vec[i].socket;
				}
			}
			if(toSocket == null) return;
			sendWebSocketBtyes(toSocket, ba);
			if(self == true) sendWebSocketBtyes(socket, ba);
		}
		
		
		
		/**同步as3协议给一个组<br> 
		 * 平板与PC电脑服务器之间的操作同步，同步的二进制数据。<br>
		 * 同一组中的Server与所有Teacher都被同步到。 不同步到发送者。*/
		private function syncAS3Procotol(socket:Socket, ba:ByteArray):void{
			var protocolHead:ProtocolHead = ProtocolParse.decodeProtocolHead(ba, 3);
			ba.position = 0;
			var type:int = protocolHead.syncType;
			var group:int = protocolHead.group;
			
			var self:Boolean;
			if(type == SyncType.SYNC_SERVER || type == SyncType.SYNC_SERVER_SELF){
				//假如提供了服务器协议处理类，则直接调用此类来处理as3协议，否则转发
				if(syncServer == null){
					sendBytes(server, ba);
				}else{
					syncServer.handProtocol(ba);
				}
			}else if(type == SyncType.SYNC_GROUP || type == SyncType.SYNC_GROUP_SELF){
				self = type == SyncType.SYNC_GROUP_SELF;
				var vec:Vector.<Socketer> = socketerDir["g"+group];
				if(vec){
					for(var i:uint=0; i<vec.length; i++){
						if(socket == vec[i].socket && self == false){
						}else{
							sendBytes(vec[i].socket, ba);
						}
					}
				}else{
					sendTipMessage(socket, "服务器返回：你要发送消息的组不存在，组Id="+group);
				}
			}else if(type == SyncType.SYNC_SIGNLE || SyncType.SYNC_SIGNLE_SELF){
				var toId:int = parseInt(protocolHead.data);
				var toSocket:Socket = getSocketById(toId, group, socket);
				if(toSocket){
					sendBytes(toSocket, ba);
					self = type == SyncType.SYNC_SIGNLE_SELF;
					if(self) sendBytes(socket, ba);
				}
			}
		}
		
		
		/** 在实现了ISyncServer接口的类实例中，直接调用此方法来向单个客户端发送文件 */
		public function sendAdmin(ba:ByteArray):void{
			sendBytes(admin, ba);
		}
		
		
		/** 把一个特定的服务员，添加到一个分组中。<br>
		 * 当服务员与桌客确认订单时，把服务员加到该桌客所在的分组中，让服务员成为此桌台唯一能点菜的人，
		 * 同时禁用此桌台的其它人点菜，防止提交时错乱。<br>
		 * waiterName 服务员的名字。<br>
		 * toGroup 要添加到的分组。<br>
		 * socket 服务员的socket。 */
		public function appendWaiterToGroup(waiterName:String, toGroup:int, socket:Socket):void{
			if(socket != null) return;
				
			for(var i:uint=0; i<appendWaitList.length; i++){
				if(appendWaitList[i].name == waiterName){
					sendTipMessage(socket, "你已经在一个桌客分组中了， 请先退出，再加入。", -1, 2);
					return;
				}
			}
			
			appendWaitList.push({name:waiterName, group:toGroup});
			var vec:Vector.<Socketer> = socketerDir[toGroup];
			var socketer:Socketer = getSocketer(socket, SERVER_GROUP_ID);
			if(socketer) vec.push(socketer);
		}
		
		/** 把服务员从一个特定的分组中删除。<br>
		 * 当服务员与桌客确认订单并提交订单后，从桌客所在的组退出。<br>
		 * waiterName 服务员的名字。<br>
		 * toGroup 要添加到的分组。<br> */
		public function removeWaiterFromGroup(waiterName:String, toGroup:int):void{
			for(var i:uint=0; i<appendWaitList.length; i++){
				if(appendWaitList[i].name == waiterName){
					appendWaitList.removeAt(i);
				}
			}
			var vec:Vector.<Socketer> = socketerDir[toGroup];
			if(vec){
				for(i=0; i<vec.length; i++){
					if(vec[i].userName == waiterName){
						vec.removeAt(i);
						break;
					}
				}
			}
		}
		
		/** 当客户端socket断开时 */
		private function onClientSocketClose(e:Event):void{
			var socket:Socket = e.target as Socket;
			clearAndSync(socket);
		}
		
		/** 清理保存的socketer对象，并同步其它连接。 */
		private function clearAndSync(socket:Socket):void{
			var socketer:Socketer = getSocketer(socket);
			if(socketer == null) return;
			
			//如果是服务员，并且已经加入到了一个桌台分组中，从该组中删除。
			var vec:Vector.<Socketer>;
			var name:String = socketer.userName;
			var isBreak:Boolean;
			if(name && name != ""){
				for(var i:uint=0; i<appendWaitList.length; i++){
					if(name == appendWaitList[i].name){
						vec = socketerDir[appendWaitList[i].group];
						if(vec != null){
							for(var j:uint=0; j<vec.length; j++){
								if(vec[j].userName == name){
									vec.removeAt(j);
									isBreak = true;
									break;
								}
							}
						}
					}
					if(isBreak == true) break;
				}
			}
			
			//从下线用户所在的分组中删除此用户
			if(socket != null){
				removeSocketer(socket, socketer.group);
			}
			
			//假如是工作人员下线设置下线状态
			if(socketer.group == SERVER_GROUP_ID && userVerify != null){
				userVerify.userDownline(socketer.userName);
			}
			
			//同步当前在线用户到所有客户端
			/*var user:OnlineUserSP = new OnlineUserSP();
			user.userId = socketer.userId;
			user.userName = socketer.userName;
			syncOnlineUser(user, socketer.group);*/
		}
		
		
		/** 关闭socket连接<br>
		 * 1、在服务器达到最大连接时<br>
		 * 2、在验证用户信息不通过时 */
		private function closeSocketConnect(socket:Socket):void{
			if(socket && socket.connected){
				socket.close();
			}
		}
		
		/** 在已经连接的socket对象中,关闭指定的socketer对象,并删除 */
		private function removeSocketer(socket:Socket, group:int):void{
			var vec:Vector.<Socketer> = socketerDir["g"+group];
			if(vec == false) return;
			for(var i:uint=0; i<vec.length; i++){
				if(vec[i].socket == socket){
					if(socket == admin) admin = null;
					vec[i].clear();
					downSocket(socket);
					vec.removeAt(i);
					break;
				}
			}
			
			for(i=0; i<waiterVec.length; i++){
				if(socket == waiterVec[i]){
					waiterVec.removeAt(i);
					break;
				}
			}
			
			for(i=0; i<chefVec.length; i++){
				if(socket == chefVec[i]){
					chefVec.removeAt(i);
					break;
				}
			}
		}
		
		/** 通过SocketId，在指定的组中查找socket对象<br>
		 * 如果找不到，返回null，并向发送者发送一个提示。 */
		private function getSocketById(id:int, group:int, sender:Socket):Socket{
			var vec:Vector.<Socketer> = socketerDir["g"+group];
			if(vec == false){
				if(sender) sendTipMessage(sender, "服务器返回：要发信息的用户不存在，用户ID="+id, -1, 2); 
				return null;
			}
			for(var i:uint=0; i<vec.length; i++){
				if(vec[i].userId == id) return vec[i].socket;
			}
			return null;
		}
		
		/** 从已经连接的socket对象中返回与指定的socket对应的socketer */
		private function getSocketer(socket:Socket, group:int=-1):Socketer{
			var vec:Vector.<Socketer>;
			var socketer:Socketer;
			if(group == -1){
				for each(vec in socketerDir){
					for(var i:uint=0; i<vec.length; i++){
						if(vec[i].socket == socket) return vec[i];
					}
				}
			}else{
				vec = socketerDir["g"+group];
				if(vec){
					for(i=0; i<vec.length; i++){
						if(vec[i].socket == socket) return vec[i];
					}
				}
			}
			return null;
		}
		
		/** 通过名称断开一个Socket连接  */
		private function downSocketByName(name:String, group:int):void{
			var vec:Vector.<Socketer> = socketerDir["g"+group];
			if(!vec) return;
			for(var i:uint=0; i<vec.length; i++){
				if(vec[i].userName == name){
					sendTipMessage(vec[i].socket, "账号在其它地方登录，连接被断开。");
					downSocket(vec[i].socket);
					vec.removeAt(i);
					break;
				}
			}
		}
		
		private function downSocket(socket:Socket):void{
			socket.removeEventListener(ProgressEvent.SOCKET_DATA, onClientSocketData);
			socket.removeEventListener(Event.CLOSE, onClientSocketClose);
			if(socket.connected) socket.close();
		}
		
		
		/** 向指定的Socket发送提示信息。 <br>
		 * socket 要发送消息的Socket实例。<br>
		 * msg 要发送的消息内容。 <br>
		 * msgId 要发送的消息编号。<br>
		 * msgType 要发送的消息类型，1为错误消息，2为系统提示消息，3为客户端定义的消息。<br>
		 * 如果类型为1,消息发送后，自动关闭此socket实例。*/
		private function sendTipMessage(socket:Socket, msg:String, msgId:int=-1, msgType:int=1):void{
			var msgTip:MessageTipSP = new MessageTipSP();
			msgTip.id = ""+msgId;
			msgTip.type = msgType;
			msgTip.message = msg; 
			sendProtocolToMainModule(socket, MessageTipSP.NAME, msgTip, -2);
			//假如是错误类型消息，关闭socket连接
			if(msgType==1){
				//延时，如果不延时客户端可能收不能发送的信息
				setTimeout(closeSocketConnect, 200, socket);
			}
		}
		
		/** 向指定客户端主模块(socketSessionId=0模块)发送信息。<br>
		 * socket 要发送协议的客户端。<br>
		 * protocolName 协议名。<br>
		 * protocolInstance 协议实例。
		 * group 分组 */
		private function sendProtocolToMainModule(socket:Socket, protocolName:String, inst:*, group:int):void{
			if(socket && socket.connected){
				var ba:ByteArray = spp.encodeProtocol(protocolName, inst, 5, "", group, group, 1, "server", 0);
				sendWebSocketBtyes(socket, ba);
			}
		}
		
		
		/** 向客户端发送WebSocket协议字符串数据 */
		private function sendWebSocketJSON(socket:Socket, protocolStr:String):void{
			if(!socket || socket.connected == false) return;
			//重置非服务器控制器的活动时间
			if(socket != server) resetActivateTiem(socket);
			
			socket.writeByte(0x81);
			var ba:ByteArray = new ByteArray();
			ba.writeMultiByte(protocolStr, "utf-8");
			if(ba.length <= 125){
				socket.writeByte(ba.length);
			}else if(ba.length < 65536){
				socket.writeByte(126);
				socket.writeShort(ba.length);
			}else{
				trace("要发送的数据太长，一帧发送的数据不能多于65536字节！");
				return;
			}
			socket.writeBytes(ba);
			socket.flush();
		}
		
		/** 向客户端发送WebSocket协议二进制数据 */
		private function sendWebSocketBtyes(socket:Socket, ba:ByteArray):void{
			if(!socket || socket.connected == false) return;
			//重置非服务器控制器的活动时间
			if(socket != server) resetActivateTiem(socket);
			
			socket.writeByte(0x82);
			ba.position = 0;
			if(ba.length <= 125){
				socket.writeByte(ba.length);
			}else if(ba.length < 65536){
				socket.writeByte(126);
				socket.writeShort(ba.length);
			}else{
				//trace("要发送的数据太长，一帧发送的数据不能多于65536字节！");
				return;
			}
			socket.writeBytes(ba);
			socket.flush();
		}
		
		/** 发送一个字节数组,同步as3协议时用 */
		private function sendBytes(socket:Socket, ba:ByteArray):void{
			if(!socket || socket.connected == false) return;
			socket.writeBytes(ba);
			socket.flush();
			//重置非服务器控制器的活动时间
			if(socket != server) resetActivateTiem(socket);
		}
		
		
		
		/** 设置最大用户连接数 */
		public function setMaxUser(n:int):void{
			maxUser = n < 1 ? n = 1 : n;
		}
		
		/** 返回当前在线的所有用户数 */
		public function getOnlineUserNum():int{
			var len:int = 0;
			var socketerVec:Vector.<Socketer>;
			for(var nm:String in socketerDir){
				socketerVec = socketerDir[nm];
				len += socketerVec.length
			}
			return len;
		}
		
		/** 返回此对象所关联的WebSocketProtocolParse对象 */
		public function get webSocketProtocolParse():ProtocolParse{
			return spp;
		}
		
		/** 关闭服务器并停止侦听连接。 */
		public function close():void{
			if(serverSocket != null){
				serverSocket.removeEventListener(ServerSocketConnectEvent.CONNECT, onConnect);
				serverSocket.close();
				serverSocket = null;
			}
		}
		
		/** 重置活动时间 */
		private function resetActivateTiem(socket:Socket):void{
			var vec:Vector.<Socketer>;
			var serverGroup:String = "g"+SERVER_GROUP_ID; 
			for(var group:String in socketerDir){
				if(group != serverGroup){
					vec = socketerDir[group];
					for(var i:uint=0; i<vec.length; i++){
						if(vec[i].socket == socket){
							vec[i].activateTiem = getTimer(); 
							return; 
						}
					}
				}
			}
		}
		
		/** 每隔2分钟清理一次不活动的Socketer */
		private function clearSocketer():void{
			var nowTime:int = getTimer();
			var time:int;
			var vec:Vector.<Socketer>;
			var serverGroup:String = "g"+SERVER_GROUP_ID; 
			for(var group:String in socketerDir){
				if(group != serverGroup){
					vec = socketerDir[group];
					for(var i:uint=0; i<vec.length; i++){
						time = nowTime - vec[i].activateTiem;
						if(time > DEACTIVATE_TIME){
							sendTipMessage(vec[i].socket, "服务器返回：因为你长时间不活动，连接被断开。", 3);
							setTimeout(downSocket, 100, vec[i].socket);
							vec.removeAt(i);
						}
					}
				}
			}
			setTimeout(clearSocketer, CLEAR_TIME);
		}
		
		
		
		/** 解析WebSocket客户端传来的数据 */
		private function parseProtocolData(socket:Socket, ba:ByteArray):String{
			ba.position = 0;
			
			//假如不是WebSocket协议书格式
			if(ba[0] != 0x81 && ba[0] != 0x82 && ba[0] != 0x88 && ba[0] != 0x89 && ba[0] != 0x8A){
				return "error format";
			}
			
			/** 后面是否还有连续的数据 */
			var isEof:Boolean = (ba[0] >> 7) > 0;
			/** 操作码或协议格式 <br> 
			 *  0x0:还有后内容， 0x1:文本， 0x2:二进制数据，0x3-7:暂时无定义为以后的非控制帧保留。<br>
			 *	0x8:表示连接关闭， 0x9:表示ping, 0xA:表示pong, 0xB-F:暂时无定义，为以后的控制帧保留。*/
			var msgType:int = ba[0] & 0xF;
			/** 是否有掩码 */
			var isMask:Boolean = (ba[1] >> 7) > 0;
			/** 消息长度 */
			var msgLen:uint = ba[1] & 0x7F;
			
			if(msgType == 0x8){
				//关闭帧
				clearAndSync(socket);
				closeSocketConnect(socket);
				return "close socket";
			}
			
			ba.position=2;
			if (msgLen == 126){
				msgLen = ba.readShort();
			}else if (msgLen == 127){
				msgLen = ba.readDouble();
			}
			
			/** 掩码字节数组 */
			var keyBa:ByteArray = new ByteArray();
			/** 协议数据字节数组 */
			var dataBa:ByteArray = new ByteArray();
			
			//如果有掩码，则处理掩码
			if(isMask == true){
				//读掩码
				ba.readBytes(keyBa, 0, 4);
				//读负载
				ba.readBytes(dataBa, 0, msgLen);
				//判断是否为空掩码，空掩码不需要处理负载掩码
				ba.position = 0;
				if(ba.readInt() != 0){
					for(var i:uint=0; i<dataBa.length; i++){
						dataBa[i] = dataBa[i] ^ keyBa[i%4];
					}
				}
			}else{
				ba.readBytes(dataBa, 0, msgLen);
			}
			dataBa.position = 0;
			
			if(msgType == 0x9){
				//回复Ping
				socket.writeByte(0x8A);
				socket.writeByte(dataBa.length);
				socket.writeBytes(dataBa);
				socket.flush();
				//trace("客户端有ping传来");
				return "ping";
			}else if(msgType == 0xA){
				return "pong";
			}
			
			if(msgType == 0x1){
				return dataBa.readMultiByte(dataBa.bytesAvailable,"utf-8");
			}else if(msgType == 0x2){
				ba.clear();
				ba.writeBytes(dataBa);
				return "binary";
			}else{
				return "error format";
			}
		}
		
		/** 当有WebSocket协议请求连接时，返回给客户端的握手字符串 */ 
		private function getHandShakeString(reqStr:String):String{
			var guid:String = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
			var i0:int = reqStr.search("Sec-WebSocket-Key:")+19;
			var i1:int = reqStr.indexOf("\r\n", i0);
			var secStr:String = reqStr.substring(i0, i1);
			var ba:ByteArray = new ByteArray();
			ba.writeMultiByte(secStr+guid, "utf-8");
			var secStr2:String = Base64.encodeByteArray(sha1.hash(ba));
			
			var str:String = "HTTP/1.1 101 Switching Protocols\r\n";
			str += "Sec-WebSocket-Accept: "+secStr2+"\r\n";
			
			i0 = reqStr.search("Sec-WebSocket-Protocol");
			if(i0 != -1){
				i0 += 24;
				i1 = reqStr.indexOf("\r\n", i0);
				secStr = reqStr.substring(i0, i1);
				str += "sec-websocket-protocol: " + secStr+"\r\n";
			}
			
			str += "Upgrade: websocket\r\n";
			str += "Connection: Upgrade\r\n\r\n";
			
			return str;
		}
		
		/** 要返回给客户端的socket安全策略文件 */
		private function getSecurityString():String{
			var str:String = "";
			str += '<?xml version="1.0"?>';
			str += '<cross-domain-policy>';
			str += '<site-control permitted-cross-domain-policies="all"/>';
			str += '<allow-access-from domain="*" to-ports="*" />';
			str += '</cross-domain-policy>';
			return str;
		}
	}
}