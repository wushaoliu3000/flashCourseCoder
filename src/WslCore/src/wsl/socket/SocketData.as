package wsl.socket{
	import flash.utils.ByteArray;

	/** Socketer实例中，当每一个Socket连接接收完一个完整的协议后，返回此类的实例。 */
	public class SocketData{
		/** 协议类型 0为as3协议 ， 1为WebSocket协议。 */
		public var type:int = 0;
		/** 一个协议完整的字节数组 */
		public var ba:ByteArray;
		
		/** Socketer实例中，当每一个Socket连接接收完一个完整的协议后，返回此类的实例。
		 * type 协议类型 0为as3协议 ， 1为WebSocket协议。
		 * ba 一个协议完整的字节数组。*/
		public function SocketData(type:int, ba:ByteArray):void{
			this.type = type;
			this.ba = ba;
		}
	}
}