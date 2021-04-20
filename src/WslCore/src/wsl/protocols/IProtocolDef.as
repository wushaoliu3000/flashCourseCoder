package wsl.protocols{
	
	/** 接口 实现此接口为SocketProtocolParse类提供协议定义的XML文档<br> 
	 * 此接口的实现类最好与协议定义在同一包中*/
	public interface IProtocolDef{
		
		/** 返回SocketProtocolParse类所需要的协议定义的XML文档 */
		function getProtocols():Array;
	}
}