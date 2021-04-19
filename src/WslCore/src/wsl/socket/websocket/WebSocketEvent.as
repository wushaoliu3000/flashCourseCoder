package wsl.socket.websocket{
	import flash.events.Event;
	import flash.utils.ByteArray;
	
	public class WebSocketEvent extends Event{
		public static const OPEN:String = "open";
		public static const CLOSED:String = "closed";
		public static const MESSAGE:String = "message";
		public static const FRAME:String = "frame";
		public static const PING:String = "ping";
		public static const PONG:String = "pong";
		static public const RECEIVE_BYTE_ARRAY:String = "receiveByteArray";
		
		public var message:WebSocketMessage;
		public var frame:WebSocketFrame;
		public var ba:ByteArray; 
		
		public function WebSocketEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false){
			super(type, bubbles, cancelable);
		}
	}
}