package wsl.protocols{
	
	/** 当连接socket服务器时，用于验证用户的信息 */
	public class VerifyInfoSP{
		static public const NAME:String = "VerifyInfoSP";
		
		private var _name:String;
		private var _password:String;
		private var _group:int
		private var _type:String;
		private var _serverId:String;
		
		/** 当连接socket服务器时，用于验证用户的信息 */
		public function VerifyInfoSP(){
		}

		/** 用户名 */
		public function get name():String{
			return _name;
		}
		public function set name(value:String):void{
			_name = value;
		}

		/**
		 * 当 客户端--->服务器 用户密码<br>
		 * 当 服务器--->客户端 用户socket连接在服务器端的socketId，即用户的唯一标识 */
		public function get password():String{
			return _password;
		}
		public function set password(value:String):void{
			_password = value;
		}

		/** 特殊标识<br>
		 * 如：分组标识、验证码<br>*/
		public function get group():int{
			return _group;
		}
		public function set group(value:int):void{
			_group = value;
		}

		/** 用户类型，在UserType类中定义 */
		public function get type():String{
			return _type;
		}
		public function set type(value:String):void{
			_type = value;
		}

		/** 服务器ID，不同的机顶盒对应不同的餐厅，有不同的serverID。 */
		public function get serverId():String{
			return _serverId;
		}
		public function set serverId(value:String):void{
			_serverId = value;
		}

	}
}