package wsl.protocols{
	
	/** 信息提示类 用于传送错误信息、提示信息等 */
	public class MessageTipSP{
		static public const NAME:String = "MessageTipSP";
		
		private var _id:String;
		private var _message:String;
		private var _type:int;
		
		/** 消息提示类 用于传送错误消息、提示消息等 */
		public function MessageTipSP(){
		}
		
		/** 消息的ID编号 <br>
		 * 以下是服务器向客户端发送的消息ID编号与内容：<br>
		 * 0  服务器的Socket连接已满,你不能在连接了。<br>
		 * 1 socket连接被服务器关闭，因为你没有发送身份验证协议。<br> 
		 * 2  服务器没有通过你的身份验证信息！连接已经被关闭。<br>
		 * 3  服务控制者(server)已经登陆！<br>
		 * 4 请先登陆电脑上的“讲课宝” 程序！<br>
		 * 5 你连接的教室不存在！<br>
		 * 6 老师下线了，你的连接已被断开！<br> */
		public function get id():String{
			return _id;
		}

		public function set id(value:String):void{
			_id = value;
		}
		
		/** 消息的类型，1为错误消息，2为系统提示消息，3为客户端定义的消息。<br> 
		 * 在发送内型为1的消息后，服务器会断开客户端的连接。*/
		public function get type():int{
			return _type;
		}
		
		public function set type(value:int):void{
			_type = value;
		}

		/** 消息的内容 */
		public function get message():String{
			return _message;
		}

		public function set message(value:String):void{
			_message = value;
		}

		

	}
}