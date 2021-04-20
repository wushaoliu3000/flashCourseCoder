/** 提供传输消息的类型，utf8文本或二进制，存储协议传输的消息内。 */
package wsl.socket.websocket{
	import flash.utils.ByteArray;
	
	/** 提供传输消息的类型，utf8文本或二进制，存储协议传输的消息内。 */
	public class WebSocketMessage{
		public static const TYPE_BINARY:String = "binary";
		public static const TYPE_UTF8:String = "utf8";
		
		public var type:String;
		public var utf8Data:String;
		public var binaryData:ByteArray;
	}
}