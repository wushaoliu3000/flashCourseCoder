package wsl.protocols{
	
	/** 实现IProtocolXML接口为SocketProtocolParse类提供协议定义的XML文档<br> 
	 * 此类必须与协议定义在同一包中<br>
	 * 此类中定义的所有协议都是向客户端主模块中发送的 */
	public class PreProtocolDef implements IProtocolDef {
		private var pros:Array = [
			{
				name:"MessageTipSP",
				pro:[
					{name:"id",       type:"string",   isVec:"0"},
					{name:"type",     type:"int",      isVec:"0"},
					{name:"message",  type:"string",   isVec:"0"}
				]
			},
			{
				name:"VerifyInfoSP",
				pro:[
					{name:"name",       type:"string",   isVec:"0"},
					{name:"password",   type:"string",   isVec:"0"},
					{name:"group",      type:"int",      isVec:"0"},
					{name:"type",       type:"string",   isVec:"0"},
					{name:"serverId",   type:"string",   isVec:"0"}
				]
			},
			{
				name:"OnlineUserSP",
				pro:[
					{name:"userName",  type:"string",  isVec:"0"},
					{name:"userId",    type:"int",     isVec:"0"},
					{name:"group",     type:"int",     isVec:"0"}
				]
			},
			{
				name:"SyncOnlineUserSP",
				pro:[
					{name:"allOnlineUser", type:"OnlineUserSP", isVec:"1"}
				]
			},
			{
				name:"LoadModuleSP",
				pro:[
					{name:"id",  type:"int",     isVec:"0"},
					{name:"uri", type:"string",  isVec:"0"}
				]
			},
			{
				name:"SpeechSP",
				pro:[
					{name:"operate",  type:"int",     isVec:"0"},
					{name:"data",     type:"string",  isVec:"0"}
				]
			},
			{
				name:"SyncFileSP",
				pro:[
					{name:"name",   type:"string",  isVec:"0"},
					{name:"path",   type:"string",  isVec:"0"},
					{name:"opcode", type:"int",     isVec:"0"},
					{name:"size",   type:"int",   isVec:"0"},
					{name:"data",   type:"bytes",   isVec:"0"}
				]
			},
			{
				name:"BaseReturnSP",
				pro:[
					{name:"data", type:"string", isVec:"0"}
				]
			}
		];
		
		
		/** 实现IProtocolXML接口为SocketProtocolParse类提供协议定义的XML文档<br> 
		 * 此类必须与协议定义在同一包中*/
		public function PreProtocolDef(){
		}
		
		/** 返回SocketProtocolParse类所需要的协议定义的XML文档 */
		public function getProtocols():Array{
			return pros;
		}
	}
	
	
}