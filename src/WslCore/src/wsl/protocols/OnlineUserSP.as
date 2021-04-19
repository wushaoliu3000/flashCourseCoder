package wsl.protocols{
	
	/** 表示一个当前在线的用户信息, 在SyncOnlineUser类中使用 */
	public class OnlineUserSP{
		static public const NAME:String = "OnlineUserSP";
		
		private var _userId:uint;
		private var _userName:String;
		private var _group:int;
		
		
		/** 表示一个当前在线的用户信息, 在SyncOnlineUser类中使用 */
		public function OnlineUserSP(){}
		
		/** 用户名 */
		public function get userName():String{
			return _userName;
		}
		public function set userName(value:String):void{
			_userName = value;
		}
		
		/** 用户Id */
		public function get userId():uint{
			return _userId;
		}
		public function set userId(value:uint):void{
			_userId = value;
		}

		/** 用户所在的组 */
		public function get group():int{
			return _group;
		}
		public function set group(value:int):void{
			_group = value;
		}

	}
}