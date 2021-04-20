package wsl.protocols{
	
	/** 同步在线用户，当用户上线或下线时处发 */
	public class SyncOnlineUserSP{
		static public const NAME:String = "SyncOnlineUserSP";
		
		/** 当前在线的所有用户 */
		private var _allOnlineUser:Vector.<OnlineUserSP> = new Vector.<OnlineUserSP>();
		
		/** 同步在线用户，当用户上线或下线时处发 */
		public function SyncOnlineUserSP(){}

		
		public function get allOnlineUser():Vector.<OnlineUserSP>{
			return _allOnlineUser;
		}

		public function set allOnlineUser(value:Vector.<OnlineUserSP>):void{
			_allOnlineUser = value;
		}

	}
}