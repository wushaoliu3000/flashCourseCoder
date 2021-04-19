package wsl.socket.websocket
{
	public final class WebSocketOpcode
	{
		// non-control opcodes
		/** 一个联系的消息 */
		public static const CONTINUATION:int = 0x00;
		/** 传输的内容是文本格式 */
		public static const TEXT_FRAME:int = 0x01;
		/** 传输的内容是二进制 */
		public static const BINARY_FRAME:int = 0x02;
		/** 用于以后的括展数据 */
		public static const EXT_DATA:int = 0x03;
		// 0x04 - 0x07 = Reserved for further control frames
		
		// Control opcodes 
		/** 通知服务器断开连接 */
		public static const CONNECTION_CLOSE:int = 0x08;
		/** ping用于保持与服务器的联接不断开 */
		public static const PING:int = 0x09;
		/** ping回复 */
		public static const PONG:int = 0x0A;
		/** 用于以后的括展控制 */
		public static const EXT_CONTROL:int = 0x0B;
		// 0x0C - 0x0F = Reserved for further control frames
	}
}