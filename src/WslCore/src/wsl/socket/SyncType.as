package wsl.socket{
	/** 枚举定义 要同步协议的范围，用在socketSession的sync、syncToGroup、syncToAll、syncToServer方法中<br>
	 * SEND开头的是用WebSocket协议发送<br>
	 * SYNC开头的是用AS3协议发送 */
	public class SyncType{
		/** 送发给某一个人，包括自己 1 */
		static public const SEND_SIGNLE_SELF:int = 1;
		/** 送发给部分选择的人，包括自己 2 */
		static public const SEND_SELECTED_SELF:int = 2;
		/** 送发给所有人，包括自己 3 */
		static public const SEND_ALL_SELF:int = 3;
		/** 送发给服务控制程序，包括自己 4 */
		static public const SEND_SERVER_SELF:int = 4;
		
		/** 送发给某一个人 5 */
		static public const SEND_SIGNLE:int = 5;
		/** 送发给部分选择的人  6 */
		static public const SEND_SELECTED:int = 6;
		/** 送发给所有人 7 */
		static public const SEND_ALL:int = 7;
		/** 送发给服务控制程序 8 */
		static public const SEND_SERVER:int = 8;
		
		/** 同步给一个分组。 9  <br>不同步给自己。<br>
		 * 每一个用户连接服务器时都有一个分组ID，在此服务器分组ID类同步 */
		static public const SEND_GROUP:int = 9;
		/** 同步给一个分组。 10  <br>同步给自己。<br> 
		 * 每一个用户连接服务器时都有一个分组ID，在此服务器分组ID类同步*/
		static public const SEND_GROUP_SELF:int = 10;
		
		/** 移动设备与PC电脑之间的同步， 只同步给PC电脑，教师不同步。同步的是WebSocket协议。  11 <br>不同步给自己。*/
		static public const SEND_PC:int = 11;
		/** 移动设备与PC电脑之间的同步， 只同步给PC电脑，教师不同步。同步的是WebSocket协议。  12 <br>同步给自己。*/
		static public const SEND_PC_SELF:int = 12;
		
		/** 送发一个协议给所有的服务员 19 */
		static public const SEND_WAITER:int = 19;
		/** 送发一个协议给所有的服务员，包括自己 20 */
		static public const SEND_WAITER_SELF:int = 20;
		
		/** 送发一个协议给对应的厨师 21 */
		static public const SEND_CHEF:int = 21;
		/** 送发一个协议给对应的厨师 ，包括自己 22 */
		static public const SEND_CHEF_SELF:int = 22;
		
		
		/** 用AS3协议，同步给一个分组。 13  <br>不同步给自己。<br>
		 * 每一个用户连接服务器时都有一个分组ID，在此分组ID类同步 */
		static public const SYNC_GROUP:int = 13;
		/** 用AS3协议，同步给一个分组。 14  <br>同步给自己。<br> 
		 * 每一个用户连接服务器时都有一个分组ID，在此分组ID类同步*/
		static public const SYNC_GROUP_SELF:int = 14;
		
		/** 用AS3协议，向服务器控制器同步一个协议。 15  <br>不同步给自己。<br>
		 * 协议只同步给服务器控制器，指它任何用户都收不能此协议 */
		static public const SYNC_SERVER:int = 15;
		/** 用AS3协议，向服务器控制器同步一个协议。 15  <br>同步给自己。<br>
		 * 协议只同步给服务器控制器，指它任何用户都收不能此协议 */
		static public const SYNC_SERVER_SELF:int = 16;
		
		/** 同步给某一个人，不包括自己 17 */
		static public const SYNC_SIGNLE:int = 17;
		/** 同步给某一个人，包括自己 18 */
		static public const SYNC_SIGNLE_SELF:int = 18;
		
		
		
		/** 根据一个同步类型，来判断是否是同步给自己 */
		static public function isSelf(syncType:int):Boolean{
			var b:Boolean = false;
			switch(syncType){
				case SEND_SIGNLE_SELF:
				case SEND_SELECTED_SELF:
				case SEND_ALL_SELF:
				case SEND_SERVER_SELF:
				case SEND_GROUP_SELF:
				case SEND_PC_SELF:
				case SYNC_GROUP_SELF:
				case SYNC_SERVER_SELF:
				case SYNC_SIGNLE_SELF:
				case SEND_WAITER_SELF:
				case SEND_CHEF_SELF:
					b = true;
					break;
			}
			return b;
		}
	}
}