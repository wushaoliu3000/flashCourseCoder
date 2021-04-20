package wsl.socket{
	import flash.net.Socket;
	import flash.utils.ByteArray;

	public class Socketer{
		private var _id:int;
		private var _group:int;
		private var _userName:String;
		private var _socket:Socket;
		private var _activateTiem:int;
		private var _type:int;
		
		/** 客户端的Socket连接类型，0为FlashPlay, 1为浏览器(HTML5 WebSocket) */
		public function get type():int{
			return _type;
		}
		public function set type(value:int):void{
			_type = value;
		}
		
		/** 服务器分配给每一个客户端Socket连接的ID */
		public function get userId():int{
			return _id;
		}
		public function set userId(value:int):void{
			_id = value;
		}
		
		/** 客户端连接时传来的用户名 */
		public function get userName():String{
			return _userName;
		}
		public function set userName(value:String):void{
			_userName = value;
		}
		
		/** 客户端Socket连接 */
		public function get socket():Socket{
			return _socket;
		}
		public function set socket(value:Socket):void{
			_socket = value;
		}
		
		/** 上一次执行Ping距离现在的时间，用于清理长时间没有收到协议连接。<br>
		 * 每一个协议到达都会归零此时间，如果定时清理程序发现此时间大于设定时间，则关闭连接，清除此连接用户。<br>
		 * 此设置不仅可以清除不活动用户，还可以清除因网络慢或网络卡而没有关闭的连接。 */
		public function get activateTiem():int{
			return _activateTiem;
		}
		public function set activateTiem(value:int):void{
			_activateTiem = value;
		}
		
		/** 保存所在的分组 */
		public function get group():int{
			return _group;
		}
		public function set group(value:int):void{
			_group = value;
		}
		
		//协议读取相关
		private var len:int = 0;
		private var isWslFinal:Boolean = false;
		private var buf:ByteArray = new ByteArray();
		
		/** 用于在服务器端存储客户端的socket连接。
		 * 每一个Socketer都有一个缓存器（buf），用于读取此socket连接的协议数据。
		 * 调用getSocketData方法，可以读取并判断协议是否传输完成。如果完成则返回SocketData对象，否则返回null。 */
		public function Socketer(){
		}

		public function getSocketData():SocketData{
			var ba:ByteArray = new ByteArray();
			socket.readBytes(ba, 0, socket.bytesAvailable);
			
			if(isWslFinal == false && (ba[0] == 0x81 || ba[0] == 0x82 || ba[0] == 0x88 || ba[0] == 0x89 || ba[0] == 0x8A)){
				//同步WebSocket协议
				ba.position = 0;
				if(len == 0){
					len = ba[1] & 0x7F;
					if (len == 126){
						len = ba.readShort();
					}else if (len == 127){
						len = ba.readDouble();
					}
					ba.position = 0;
				}
				ba.readBytes(buf, buf.position+buf.bytesAvailable);
				if(buf.bytesAvailable > len){
					len = 0;
					ba.clear();
					buf.readBytes(ba);
					buf.clear();
					ba.position=0;
					return new SocketData(1, ba);
				}
			}else if(ba.readMultiByte(3, "utf-8") == "wsl" || isWslFinal){
				//同步as3协议，as3协议的前三个字节是"wsl"
				isWslFinal = true;
				if(len == 0){
					len = ba.readInt();
					ba.position -= 4;
					buf.clear();
				}
				ba.position -= 3;
				ba.readBytes(buf, buf.position+buf.bytesAvailable);
				if(buf.bytesAvailable >= len+3){
					isWslFinal = false;
					len = 0;
					ba.clear();
					buf.readBytes(ba);
					buf.clear();
					ba.position=0;
					return new SocketData(0, ba);
				}
			}
			return null;
		}
		
		public function clear():void{
			buf.clear();
			buf = null;
			_socket = null;
		}
	}
}