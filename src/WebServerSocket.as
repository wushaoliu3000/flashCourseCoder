package wsl.utils{
	import com.hurlant.crypto.hash.SHA1;
	import com.hurlant.util.Base64;
	
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.events.ServerSocketConnectEvent;
	import flash.net.ServerSocket;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	
	public class WebServerSocket extends EventDispatcher{
		/** 收到WebSocket协议数据时处发DataEvent事件。  */
		static public const RECEIVED_DATA:String = "receivedData";
		/** WebSocket初始化出错 */
		static public const INIT_ERROR:String = "initError";
		/** WebSocket启动完成 */
		static public const INIT:String = "init";
		
		private var socketServer:ServerSocket;
		private var socket:Socket;
		private var ba:ByteArray;
		private var isFirstRequest:Boolean = true;
		
		public function WebServerSocket(){
		}
		
		public function init():void{
			ba = new ByteArray();
			try{
				socketServer = new ServerSocket();
				socketServer.addEventListener(ServerSocketConnectEvent.CONNECT, clientConnectHandler);
				socketServer.bind(9527);
				socketServer.listen();
			}catch(err:Error){
				this.dispatchEvent(new Event(INIT_ERROR));
				return;
			}
			this.dispatchEvent(new Event(INIT));
		}
		
		private function clientConnectHandler(e:ServerSocketConnectEvent):void{
			socket = e.socket;
			socket.addEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
			socketServer.removeEventListener(ServerSocketConnectEvent.CONNECT, clientConnectHandler);
			socketServer.close();
		}
		
		private function socketDataHandler(e:ProgressEvent):void{
			ba.clear();
			socket.readBytes(ba, 0, socket.bytesAvailable);
			ba.position = 0;
			var str:String;
			if(isFirstRequest){
				isFirstRequest = false;
				str = ba.readMultiByte(ba.length, "utf-8");
				socket.writeUTFBytes(getHandShakeString(str));
				socket.flush();
			}else{
				str = parseProtocolData(socket, ba);
				this.dispatchEvent(new DataEvent(RECEIVED_DATA, false, false, str));
			}
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
			var secStr2:String = Base64.encodeByteArray((new SHA1()).hash(ba));
			
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

		public function destroy():void{
			ba = null;
			if(socket){
				if(socket.connected) socket.close();
				socket = null;
			}
			if(socketServer.bound){
				socketServer.removeEventListener(ServerSocketConnectEvent.CONNECT, clientConnectHandler);
				socketServer.close();
			}
			socketServer = null;
		}
	}
}