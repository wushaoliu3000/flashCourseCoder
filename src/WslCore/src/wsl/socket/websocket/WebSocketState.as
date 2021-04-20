package wsl.socket.websocket
{
	public final class WebSocketState
	{
		/** 第一次连接，请求握手 */
		public static const CONNECTING:int = 0;
		/** 连接的 */
		public static const OPEN:int = 1;
		public static const CLOSED:int = 2;
		public static const INIT:int = 3;
	}
}