package wsl.socket{
	import flash.utils.ByteArray;

	/** 为WebSocketServer类实例提供一个同步到服务器是时的处理类。 */
	public interface ISyncServer{
		/** 处理同步到服务器是的协议。<br>
		 * ba 要处理协议的字节数组。 */
		function handProtocol(ba:ByteArray):void;
		/** 设置服务器实例，方便在此实例中直接调用服务器方法（向客户端发送文件时，直接调用服务器方法） */
		function setServer(server:SocketServer):void;
	}
}