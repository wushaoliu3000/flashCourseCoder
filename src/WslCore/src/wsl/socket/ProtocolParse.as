package wsl.socket{
	import flash.display.Sprite;
	import flash.events.EventDispatcher;
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	
	import wsl.protocols.IProtocolDef;
	import wsl.protocols.PreProtocolDef;
	
	public class ProtocolParse extends EventDispatcher{
		private var  PROTOCOL_PACKAGE:String;
		private var protocolDic:Dictionary;
		
		/** root 被加载swf的根对象,以用获取loaderInfo以便获取协议定义*/
		private var root:Sprite;
		
		/** socket协议解析 socket对象的封包、解包、打印格式化的对象文本
		 * packagePath 协议对象定义的包路径，此包中包含所有与protocolJsonPath文档中定义对应的所有协议对象
		 * protocolJson  协议定义的Json文档类,必须继承IProtocolDef接口
		 * root 被加载swf的根对象,以用获取loaderInfo以便获取协议定义*/
		public function ProtocolParse(packagePath:String, protocolJson:IProtocolDef, root:Sprite){
			PROTOCOL_PACKAGE = packagePath;
			this.root = root;
			protocolDic = new Dictionary();
			
			parseJSON(protocolJson);
		}
		
		/** 解析协议定义的JSON字符串 */
		private function parseJSON(protocolDef:IProtocolDef):void{
			var arr:Array = (new PreProtocolDef()).getProtocols();
			if(protocolDef != null){
				var a:Array = protocolDef.getProtocols();
				for(var i:uint=0; i< a.length; i++){
					arr.push(a[i]);
				}
			}
			
			var protocolsArr:Array = arr;
			var protocolName:String;
			var propertyArr:Array;
			var proDef:ProDef;
			var ProDefVec:Vector.<ProDef>;
			var name:String;
			var type:String;
			var isVec:Boolean;
			for (i = 0; i < protocolsArr.length; i++) {
				protocolName = protocolsArr[i].name;
				propertyArr = protocolsArr[i].pro;
				ProDefVec = new Vector.<ProDef>;
				for(var j:uint=0; j<propertyArr.length; j++){
					name = propertyArr[j].name;
					type = propertyArr[j].type;
					isVec = propertyArr[j].isVec == "1";
					proDef = new ProDef(name, type, isVec);
					ProDefVec[j] = proDef;
				}
				protocolDic[protocolName] = ProDefVec;
			}
		}
		
		/** 把一个协议对象编码为一个字节数组。<br> 
		 * protocolName 协议名。<br>
		 * inst 协议对象。<br> 
		 * syncType 表示要转发的范围，5送发给某一个人   6送发给部分选择的人  7送发给所有人  8送发给服务控制程序   9同步给一个分组。<br>  
		 * data 当 客户端-->服务器 时：表示要转发的一个或一组id; 当 服务器-->客户端 时：表示协议发送者名称。<br>
		 * toGroup 协议要发送到的分组。<br>
		 * group 用此值来为服务器提供分组依据。<br>
		 * senderId 协议发送者的Id。<br>
		 * senderName 协议发送者的名称。<br>
		 * socketSessionId 每一个包函SocketSession对象的swf模块都有一个socketSessionId，这样在SocketConnect.handSocketSession中
		 * 转发消息时，可以只转发给与socketSessionId对应的SocketSession对象。socketSessionId=0为主模块所用。
		 * socketSessionId=0为MessageTip所用,在SocketConnect.handSocketSessio中处理<br>*/
		public function encodeProtocol(protocolName:String, inst:*, syncType:int, data:String, 
				        toGroup:int, group:int, senderId:int, senderName:String, sessionId:int):ByteArray{
			if(inst == null){
				throw new Error("要编码的"+protocolName+"实例为null，但是要编码的实例不能为null!");
			}
			
			//编码协议头
			var protocolTotalBytes:ByteArray = encodeProtocolHead(protocolName, syncType, data, toGroup, group, senderId, senderName, sessionId);
			
			//编码协议体
			var protocolBytes:ByteArray = new ByteArray();
			writeProtocol(protocolName, inst, protocolBytes);
			protocolTotalBytes.writeBytes(protocolBytes, 0, protocolBytes.length);
			
			//改写协议总长度
			protocolTotalBytes.position = 0;
			protocolTotalBytes.writeInt(protocolTotalBytes.length);
			protocolTotalBytes.position = protocolTotalBytes.length;
			protocolTotalBytes.position = 0;
			
			return protocolTotalBytes;
		}
		
		
		
		private function writeProtocol(protocolName:String, inst:*, bytes:ByteArray):void{
			var protocol:Vector.<ProDef> = getPro(protocolName);
			var proDef:ProDef;
			var vec:*;
			
			for (var i:uint = 0; i < protocol.length; i++) {
				proDef = protocol[i];
				if (proDef.isVec) {
					vec = inst[proDef.name];
					if(vec == null){
						bytes.writeShort(-1);
						continue;
					}
					bytes.writeShort(vec.length);
					if (proDef.type == "short") {
						for(var j:uint=0; j<vec.length; j++){
							bytes.writeShort(vec[j]);
						}
					}else if (proDef.type == "int") {
						for(j=0; j<vec.length; j++){
							bytes.writeInt(vec[j]);
						}
					}else if (proDef.type == "number") {
						for(j=0; j<vec.length; j++){
							bytes.writeDouble(vec[j]);
						}
					}else if (proDef.type == "boolean") {
						for(j=0; j<vec.length; j++){
							bytes.writeBoolean(vec[j]);
						}
					}else if(proDef.type == "string"){
						for(j=0; j<vec.length; j++){
							if(!vec[j] && vec[j] != ""){
								bytes.writeShort(-1);
							}else{
								bytes.writeUTF(vec[j]);
							}
						}
					} else{
						for(j=0; j<vec.length; j++){
							writeProtocol(proDef.type, vec[j], bytes);
						}
					}
				} else if (proDef.type == "short") {
					bytes.writeShort(inst[proDef.name]);
				} else if (proDef.type == "int") {
					bytes.writeInt(inst[proDef.name]);
				} else if (proDef.type == "number") {
					bytes.writeDouble(inst[proDef.name]);
				}  else if(proDef.type == "boolean"){
					bytes.writeBoolean(inst[proDef.name]);
				} else if (proDef.type == "string") {
					if(!inst[proDef.name] && inst[proDef.name] != ""){
						bytes.writeShort(-1);
					}else{
						bytes.writeUTF(inst[proDef.name]);
					}
				} else if (proDef.type == "bytes") {
					var ba:ByteArray = inst[proDef.name];
					if(ba == null){
						bytes.writeInt(-1);
					}else{
						bytes.writeInt(ba.length);
						bytes.writeBytes(ba, 0, ba.length);
					}
				}else{
					if(inst[proDef.name] == null){
						bytes.writeShort(-886);
					}else{
						writeProtocol(proDef.type, inst[proDef.name], bytes);
					}
				}
			}
		}
		
		/** 把一个协议的字节数组编码为一个协议对象 */
		public function decodeProtocol(bytes:ByteArray):Protocol{
			bytes.position = 0;
			var protocol:Protocol = new Protocol();
			
			var protocolHead:ProtocolHead = decodeProtocolHead(bytes);
			protocol.name = protocolHead.name;
			protocol.group = protocolHead.group;
			protocol.toGroup = protocolHead.toGroup;
			protocol.sessionId = protocolHead.sessionId;
			protocol.syncType = protocolHead.syncType;
			protocol.data = protocolHead.data;
			protocol.senderId = protocolHead.senderId;
			protocol.senderName = protocolHead.senderName;
			
			var protocolBody:* = getProtocolInstance(protocolHead.name);
			readProtocol(protocolHead.name, bytes, protocolBody);
			protocol.body = protocolBody;
			
			return protocol;
		}
		
		private function readProtocol(protocolName:String, bytes:ByteArray, inst:*):void{
			var protocol:Vector.<ProDef> = getPro(protocolName);
			var proDef:ProDef;
			var protocolObj:*;
			var vec:*;
			var len:int;
			for (var i:uint = 0; i < protocol.length; i++) {
				proDef = protocol[i];
				if (proDef.isVec) {
					len = bytes.readShort();
					if(len < 0){
						inst[proDef.name] = null;
						continue;
					}
					vec = getVector(proDef.type);
					if(proDef.type == "short") {
						for(var j:uint=0; j<len; j++){
							vec[j] = bytes.readShort();
						}
						inst[proDef.name] = vec;
					}else if(proDef.type == "int") {
						for(j=0; j<len; j++){
							vec[j] = bytes.readInt();
						}
						inst[proDef.name] = vec;
					}else if(proDef.type == "number") {
						for(j=0; j<len; j++){
							vec[j] = bytes.readDouble();
						}
						inst[proDef.name] = vec;
					}else if(proDef.type == "boolean"){
						for(j=0; j<len; j++){
							vec[j] = bytes.readBoolean();
						}
						inst[proDef.name] = vec;
					}else if (proDef.type == "string") {
						var l:int;
						for(j=0; j<len; j++){
							l = bytes.readShort();
							if(l < 0){
								vec[j] = null;
							}else{
								bytes.position -= 2;
								vec[j] = bytes.readUTF();
							}
						}
						inst[proDef.name] = vec;
					}else{
						for(j=0; j<len; j++){
							protocolObj = getProtocolInstance(proDef.type);
							readProtocol(proDef.type, bytes, protocolObj);
							vec[j] = protocolObj;
						}
						inst[proDef.name] = vec;
					}
				} else if (proDef.type == "short") {
					inst[proDef.name] = bytes.readShort();
				} else if (proDef.type == "int") {
					inst[proDef.name] = bytes.readInt();
				} else if (proDef.type == "number") {
					inst[proDef.name] = bytes.readDouble();
				} else if(proDef.type == "boolean"){
					inst[proDef.name] = bytes.readBoolean();
				}else if (proDef.type == "string") {
					len = bytes.readShort();
					if(len < 0){
						inst[proDef.name] = null;
					}else{
						bytes.position -= 2;
						inst[proDef.name] = bytes.readUTF();
					}
				} else if (proDef.type == "bytes") {
					var baLen:int = bytes.readInt();
					if(baLen < 0) {
						inst[proDef.name] = null;
					}else{
						var ba:ByteArray = new ByteArray();
						bytes.readBytes(ba, 0, baLen);
						inst[proDef.name] = ba;
					}
				}else{
					if(bytes.readShort() == -886){
					}else{
						bytes.position -= 2;
						protocolObj = getProtocolInstance(proDef.type);
						readProtocol(proDef.type, bytes, protocolObj);
						inst[proDef.name] = protocolObj;
					}
				}
			}
		}
		
		/** 获取一个用于存放协议组的Vector。<br>
		 * type Vector要存放的类型。 */
		private function getVector(type:String):*{
			var Cls:Class;
			var path1:String;
			var path2:String;
			if(type == "boolean"){
				path1 = path2 = "__AS3__.vec.Vector.<Boolean>";
			}else if(type == "int"){
				path1 = path2 = "__AS3__.vec.Vector.<int>";
			}else if(type == "string"){
				path1 = path2 = "__AS3__.vec.Vector.<String>";
			}else{
				path1 = "__AS3__.vec.Vector.<" + "wsl.protocols."+type + ">";
				path2 = "__AS3__.vec.Vector.<" + PROTOCOL_PACKAGE+"."+type + ">";
			}
			
			if(root && root.loaderInfo.applicationDomain.hasDefinition(path1)){
				Cls = root.loaderInfo.applicationDomain.getDefinition(path1) as Class;
			}else if( root && root.loaderInfo.applicationDomain.hasDefinition(path2)){
				Cls = root.loaderInfo.applicationDomain.getDefinition(path2) as Class;
			}else if(ApplicationDomain.currentDomain.hasDefinition(path1)){
				Cls = ApplicationDomain.currentDomain.getDefinition(path1) as Class;
			}else if(ApplicationDomain.currentDomain.hasDefinition(path2)){
				Cls = ApplicationDomain.currentDomain.getDefinition(path2) as Class;
			}else{
				throw new Error(" Vector.<"+"wsl.protocols."+type+"> 或者 Vector.<"+PROTOCOL_PACKAGE+"."+type +">没有找到!");
			}
			
			return new Cls();
		}
		
		/** 编码协议头<br>
		 * protocolName 协议名<br>
		 * syncType 表示要转发的范围，5送发给某一个人   6送发给部分选择的人  7送发给所有人  8送发给服务控制程序   9同步给一个分组。<br>
		 * data 当 客户端-->服务器 时：表示要转发的一个或一组id。<br>
		 * toGroup 要同步到的组<br>。
		 * group (自己所在的分组)用此值来为服务器提供分组依据<br>。
		 * senderId 协议发送者的Id。<br>
		 * senderName 协议发送者的名称。<br>
		 * sessionId 每一个包函SocketSession对象的swf模块都有一个sessionId，这样在SocketConnect.handSocketSession中
		 * 转发消息时，可以只转发给与sessionId对应的SocketSession对象。sessionId=0为主模块所用。
		 * socketSessionId=0为MessageTip所用,在SocketConnect.handSocketSessio中处理。 */
		private function encodeProtocolHead(protocolName:String, syncType:int, data:String, toGroup:int, 
				group:int, senderId:int, senderName:String, sessionId:int):ByteArray{
			var bytes:ByteArray = new ByteArray();
			//先写一个协议总长度的占位
			bytes.writeInt(0);
			//写分组ID
			bytes.writeShort(group);
			//写协议同步类型  在SyncType中定义
			bytes.writeShort(syncType);
			//写协议发送者的Id
			bytes.writeInt(senderId);
			//写SessionId
			bytes.writeShort(sessionId);
			//写协议名
			bytes.writeUTF(protocolName);
			//写data(字符串)
			bytes.writeUTF(data);
			//写协议发送者的名称
			bytes.writeUTF(senderName);
			//写toGroup
			bytes.writeShort(toGroup);
			//改写协议总长度
			bytes.position = 0;
			bytes.writeInt(bytes.length);
			//设置position到尾部
			bytes.position = bytes.length;
			return bytes;
		}
		
		/** 读取协议头<br> 
		 * bytes 协议字节数组。<br>
		 * position 从协议的第几个字节开始读取。<br>
		 * 返回ProtocolHead对象。*/
		static public function decodeProtocolHead(bytes:ByteArray, position:int=0):ProtocolHead{
			bytes.position = position;
			var protocolHead:ProtocolHead = new ProtocolHead();
			//读协议总长度
			protocolHead.length = bytes.readInt();
			//读分组ID
			protocolHead.group = bytes.readShort();
			//读协议同步类型  在SyncType中定义
			protocolHead.syncType = bytes.readShort();
			//读协议发送者的Id
			protocolHead.senderId = bytes.readInt();
			//读socketSessionId
			protocolHead.sessionId = bytes.readShort();
			//读协议名
			protocolHead.name = bytes.readUTF();
			//读协议头data
			protocolHead.data = bytes.readUTF();
			//读协议发送者的名称
			protocolHead.senderName = bytes.readUTF();
			//读取toGroup
			protocolHead.toGroup = bytes.readShort();
			return protocolHead;
		}
		
		/** 打印SocketProtocol协议对象的格式化字体串 */
		public function printSocketProtocol(sp:Protocol):void{
			trace("--------------------------" + sp.name + "--------------------------------");
			printObjectLog(sp.name, sp.body, "");
			trace("-------------------------------------------------------------------------");
		}
		
		/** 打印一个协议对象的格式化字体串 */
		public function printProtocolFromObject(protocolName:String, inst:*):void{
			trace("--------------------------" + protocolName + "--------------------------------");
			printObjectLog(protocolName, inst, "");
			trace("-------------------------------------------------------------------------------");
		}
		
		private function printObjectLog(protocolName:String, inst:*, indent:String):void{
			var protocol:Vector.<ProDef> = getPro(protocolName);
			var proDef:ProDef;
			var arr:*;
			
			for (var i:uint = 0; i < protocol.length; i++) {
				proDef = protocol[i];
				if (proDef.isVec) {
					if (proDef.type == "short" || proDef.type == "int" || proDef.type == "number" || proDef.type == "boolean") {
						arr = inst[proDef.name];
						if(arr){
							var str:String = "";
							for(var j:uint=0; j<arr.length; j++){
								str += arr[j] + (j == arr.length - 1 ? "" : ",");
							}
							trace("    "+indent+proDef.name + ": [" + str + "]");
						}else{
							trace("    "+indent+proDef.name+":null");
						}
					} else if (proDef.type == "string") {
						arr = inst[proDef.name];
						if(arr){
							str = "";
							for(j=0; j<arr.length; j++){
								str += "\"" + arr[j] + "\"" + (j == arr.length - 1 ? "" : ",");
							}
							trace("    "+indent+proDef.name + ": [" + str + "]");
						}else{
							trace("    "+indent+proDef.name+":null");
						}
					} else{
						arr = inst[proDef.name];
						if(arr){
							trace(indent+proDef.name +": [");
							for(j=0; j<arr.length; j++){
								trace("    "+indent+proDef.type +": {");
								printObjectLog(proDef.type, arr[j], indent+"        ");
								trace("    "+indent+"}");
							}
							trace(indent+"]");
						}else{
							trace(indent+proDef.name+":null");
						}
					}
				} else if (proDef.type == "short" || proDef.type == "int" || proDef.type == "number" || proDef.type == "boolean") {
					trace(indent+proDef.name + ": " + inst[proDef.name]);
				} else if (proDef.type == "string") {
					trace(indent+proDef.name + ": \"" + inst[proDef.name]+"\"");
				} else if (proDef.type == "bytes") {
					var ba:ByteArray = inst[proDef.name];
					trace(indent+proDef.name + ": {bytes byteLength="+ ba.length + "}");
				}else{
					if(inst[proDef.name] == null){
						trace(indent+proDef.name+": "+null);
					}else{
						trace(proDef.name +": {");
						printObjectLog(proDef.type, inst[proDef.name], indent+"    ");
						trace("}");
					}
				}
			}
		}
		
		/** 打印一个字节数组协议对象的格式化字符串 */
		public function printProtocolFromBytes(bytes:ByteArray):void {
			var sp:Protocol = decodeProtocol(bytes);
			printProtocolFromObject(sp.name, sp.body);
		}
		
		/** 取得XML协议文档中的定义的协议属性 */
		private  function getPro(protocolName:String):Vector.<ProDef>{
			var protocol:Vector.<ProDef> = protocolDic[protocolName];
			if(protocol == null){
				throw new Error(protocolName+"协议没有在协议定义的Json中找到!");
			}
			return protocol;
		}
		
		/** 取得协议实例，先在用户指定的包中找，如果找不到再在默认包中找，再找不到报错 */
		private function getProtocolInstance(name:String):*{
			var Cls:Class = getProtocol(name);
			return new Cls;
		}
		
		/** 取得协议，先在用户指定的包中找，如果找不到再在默认包中找，再找不到报错 */
		private function getProtocol(name:String):Class{
			var Cls:Class;
			try{
				if(root == null){
					Cls = getDefinitionByName(PROTOCOL_PACKAGE+"."+ name) as Class;
				}else{
					Cls = root.loaderInfo.applicationDomain.getDefinition(PROTOCOL_PACKAGE+"."+ name) as Class;
				}
			}catch(err:Error){
				try{
					if(root == null){
						Cls = getDefinitionByName("wsl.protocols." + name) as Class;
					}else{
						Cls = root.loaderInfo.applicationDomain.getDefinition("wsl.protocols." + name) as Class;
					}
				}catch(err:Error){
					throw new Error(name+" 协议没有找到，你确定在"+PROTOCOL_PACKAGE+"包中定义了此类");
				}
			}
			return Cls;
		}
	}
}

/** 协议属性 */
 final class ProDef {
	private var _name:String;
	private var _type:String;
	private var _isVec:Boolean;
	
	public function ProDef(name:String, type:String, isVec:Boolean) {
		_name = name;
		_type = type;
		_isVec = isVec;
	}

	public function get name():String{
		return _name;
	}
	
	public function get type():String{
		return _type;
	}
	
	public function get isVec():Boolean{
		return _isVec;
	}
}