package wsl.core{
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	
	import wsl.events.WslEvent;
	import wsl.socket.ProtocolParse;
	import wsl.socket.SocketConnect;
	import wsl.socket.SocketServer;
	import wsl.socket.SocketSession;
	import wsl.socket.SyncType;
	import wsl.view.LoadingCD;

	/** 全局设置对象，此类将在主程序中加载，其它swf模块调用其的表态属性<br>
	 * */
	public class Global{
		/** 设计文档的宽 */
		static public const DOC_W:int = 640;
		
		/** 连接远程服务器  0 */
		static public const REMOTE_CONNECT:int = 0;
		/** 连接本地服务器  1 */
		static public const LOCAL_CONNECT:int = 1;
		/** 不连接服务器   2 */
		static public const NONE_CONNECT:int = 2;
		
		static public var stageWidth:int;
		static public var stageHeight:int;
		static public var ration:Number;
		
		/** 是否是主模块 */
		static public var isMainModule:Boolean = false;
		
		/** 自己的ID，方便其它swf模块中调用 */
		static public var myId:uint;
		/** 自己的名字，方便其它swf模块中调用 */
		static public var myName:String="";
		/** 用户类型  在UserType中定义 */
		static public var type:String;
		/** 用于对应服务器WebSocketServer的分组，当同步到组时，以此为依据<br> 
		 * 食客（无需登录）的group由手机扫二维码后得到(group=0表示散客点餐，group>0表示桌台点餐, 10000表示工作人员所在组)<br>
		 * 非食客（工作人员）的group，登录后由服务器返回。*/
		static public var group:int = 0;
		/** socket所连接服务器的ID，每一个机顶盒有一个唯一的serverId */
		static public var serverId:String;
		
		/** 舞台对象，在init方法中被设置 */
		static public var stage:Stage;
		/** 主类对象，在init方法中被设置 */
		static public var mainObj:Sprite;
		
		/** SocketConnect可以传输webSocket协议，也可以传输as3协议 */
		static public var socketConnect:SocketConnect; 
		/** 服务器所在的IP地址 */
		static public var host:String = "127.0.0.1"; 
		/** 服务器侦听的端口 */
		static public var port:uint = 8888;
		/** 协议发送与同步的会话类 */
		static public var session:SocketSession; 
		
		/** 本地服务器 */ 
		static public var socketServer:SocketServer;
		
		/** 网络联接模式<br>
		 * 0为广域网连接<br> 1为局域网连接<br> 2为无网络模式 */
		static public var netModule:int = 2;
		/** 是否用远程网络来同步PC与移动设备之间的操作。<br>
		 * 广域网连接模式下移动设备与PC不在同一局域网内时用到。 */
		static public var isRemoteSync:Boolean = false;
		
		static private var fs:FileStream;
		
		static private var loadingCD:LoadingCD;
		static public var loginName:String;
		static public var password:String;
		static public var keepPwd:Boolean;
		
		static public function setScale(m:Sprite):void{
			if(Global.stageWidth > 900){
				m.scaleX = m.scaleY = (Global.stageWidth/800)*0.9;
			}else{
				m.scaleX = m.scaleY = 1;
			}
		}
		
		/** 取得一个文件， 返回要取得的文件的字符串 */
		static public function getTextFile(path:String):String{
			var f:File = new File(path);
			var fs:FileStream = new FileStream();
			fs.open(f, FileMode.READ);
			var str:String = fs.readMultiByte(fs.bytesAvailable, "utf-8");
			fs.close();
			return str;
		}
		
		/** 判断一个文件是否存在 */
		static public function isExistFile(uri:String):Boolean{
			var f:File = new File(uri);
			return f.exists;
		}
		
		/** 获取大文件的分段信息数组，假如文件大于10M时，分段发送，每段10M，最后一段可能小于10M */
		static public function getBlockArr(path:String):Vector.<Array>{
			var size:int = 1024*1024;
			var vec:Vector.<Array>;
			var f:File = new File(path);
			var fs:FileStream = new FileStream();
			fs.open(f, FileMode.READ);
			var len:int = fs.bytesAvailable;
			var num:int = 0;
			if(len > size){
				vec = new Vector.<Array>;
				var n:int = int(len/size);
				for(var i:uint=0; i<n; i++){
					vec.push([i*size, size]);
					num += size;
				}
				if(len > num){
					vec.push([i*size, len-num]);
				}
			}
			return vec;
		}
		
		/** 取得一个文件或文件的一部分， 返回要取得的文件的字节数组。<br>
		 * path 文件路径。<br>
		 * sp 要获文件部份的起始字节数。<br>
		 * ep 要获取文件部份的结束字节数。 */
		static public function getFile(path:String, sp:int=-1, ep:int=-1):ByteArray{
			var f:File = new File(path);
			var ba:ByteArray = new ByteArray();
			var fs:FileStream = new FileStream();
			fs.open(f, FileMode.READ);
			if(sp != -1 && ep != -1){
				fs.position = sp;
				fs.readBytes(ba, 0, ep);
			}else if(sp != -1 && ep == -1){
				fs.position = sp;
				fs.readBytes(ba, 0, ba.bytesAvailable);
			}else if(sp == -1 && ep == -1){
				fs.readBytes(ba);
			}
			fs.close();
			ba.position = 0;
			return ba;
		}
		
		/** 保存字节数组或文本到一个文件中, 返回已保存文件的文件名。<br>
		 * path 文件路径。<br>
		 * ba 要保存文件的字节数组。<br>
		 * text 要保存文件的文本内容。<br>
		 * isAppend 是否是在已有的文件中追加内容。 */
		static public function saveFile(path:String, ba:ByteArray, text="", isAppend:Boolean=false):String{
			var f:File = new File(path);
			var fs:FileStream = new FileStream();
			if(isAppend){
				fs.open(f,FileMode.APPEND);
			}else{
				fs.open(f, FileMode.WRITE);
			}
			if(ba != null){
				if(isAppend){
					ba.position = 0;
					fs.writeBytes(ba);
				}else{
					fs.writeBytes(ba);
				}
			}else if(text != ""){
				fs.writeMultiByte(text, "utf-8");
			}
			fs.close();
			return f.name;
		}
		
		/** 取得一个文件或文件的一部分， 返回要取得的文件的字节数组。<br>
		 * path 文件路径。<br>
		 * sp 要获文件部份的起始字节数。<br>
		 * ep 要获取文件部份的结束字节数。 <br>
		 * opcode 操作码。 0为开始读取， 1为读取中间过程。 2为读取结束。*/
		static public function readFile(path:String, sp:int=-1, ep:int=-1, opcode:int=0):ByteArray{
			if(fs == null && opcode != 0) return null;
			
			if(fs == null && opcode == 0){
				var f:File = new File(path);
				fs = new FileStream();
				fs.open(f, FileMode.READ);
				if(socketConnect){
					socketConnect.addEventListener(SocketConnect.CONNECT_FAIL, socketConnectFailHandler);
				}
			}
			var ba:ByteArray = new ByteArray();
			if(sp != -1 && ep != -1){
				fs.position = sp;
				fs.readBytes(ba, 0, ep);
			}else if(sp != -1 && ep == -1){
				fs.position = sp;
				fs.readBytes(ba, 0, ba.bytesAvailable);
			}else if(sp == -1 && ep == -1){
				fs.readBytes(ba);
			}
			if(fs != null && opcode == 2){
				fs.close();
				fs = null;
			}
			ba.position = 0;
			return ba;
		}
		
		/** 保存字节数组或文本到一个文件中, 返回已保存文件的文件名。<br>
		 * path 文件路径。<br>
		 * ba 要保存文件的字节数组。<br>
		 * opcode 操作码。 0为开始写入， 1为写入中间过程。 2为写入结束。 */
		static public function writeFile(path:String, ba:ByteArray, opcode:int=0):void{
			if(fs == null && opcode != 0) return;
			
			if(fs == null && opcode == 0){
				var f:File = new File(path);
				fs = new FileStream();
				fs.open(f, FileMode.WRITE);
				if(socketConnect){
					socketConnect.addEventListener(SocketConnect.CONNECT_FAIL, socketConnectFailHandler);
				}
			}
			if(ba != null){
				fs.writeBytes(ba);
			}
			if(fs != null && opcode == 2){
				fs.close();
				fs = null;
			}
		}
		
		static public function socketConnectFailHandler(e:WslEvent):void{
			if(fs != null){
				fs.close();
				fs = null;
				socketConnect.removeEventListener(SocketConnect.CONNECT_FAIL, socketConnectFailHandler);
				socketConnect.getWebSokcet().closeOutputEvent();
			}
		}
		
		/** 这是一个辅助方法，用于向特定用户同步AS3Socket协议。<br> */
		static public function syncToSingle(protocolName:String, inst:*, socketId:int, toGroup:int=-1, self=false):void{
			Global.session.syncToSingle(protocolName, inst, socketId, toGroup, self);
		} 
		
		/** 这是一个辅助方法，用于在一个分组内同步AS3Socket协议。<br> */
		static public function syncToGroup(protocolName:String, inst:*, toGroup:int=-1, self=false):void{
			Global.session.syncToGroup(protocolName, inst, toGroup, self);
		}
		
		/** 这是一个辅助方法，用于向服务器同步AS3Socket协议。<br> */
		static public function syncToServer(protocolName:String, inst:*, self=false):void{
			Global.session.syncToServer(protocolName, inst, self);
		}
		
		
		/** 同步AS3Socket协议给管理员，一次只能有一个管理员登录。<br>
		 * 直接调用socketServer.sendAdmin方法，不通过socket传输。 */
		static public function syncToAdmin(protocolName:String, inst:*, senderId:int):void{
			var pp:ProtocolParse = Global.session.getProtocolParse();
			var type:int = SyncType.SYNC_SIGNLE;
			var group:int = SocketServer.SERVER_GROUP_ID;
			var bytes:ByteArray = pp.encodeProtocol(protocolName, inst, type, "", group, group, senderId, "", 0);
			var bs:ByteArray = new ByteArray();
			bs.writeMultiByte("wsl", "utf-8");
			bs.writeBytes(bytes);
			Global.socketServer.sendAdmin(bs);
		}
		
		
		/** 创建加载进度条 */
		static public function createLoading(str:String):void{
			if(loadingCD && loadingCD.stage){
				loadingCD.setTitle(str);
				return;
			}
			loadingCD = new LoadingCD(str);
			stage.addChild(loadingCD);
		}
		
		/** 删除加载进度条 */
		static public function removeLoading():void{
			if(loadingCD == null) return;
			stage.removeChild(loadingCD);
			loadingCD = null;
		}
		
		/** 设置加载进度条的提示 */
		static public function setLoadingTitle(str:String):void{
			if(loadingCD == null) return;
			loadingCD.setTitle(str);
		}
		
		/** 初始化一些舞台属性 */
		static public function init(obj:Sprite, isFullScreen:Boolean=false, stageAlign:String=StageAlign.TOP_LEFT,
									stageScaleMode:String=StageScaleMode.NO_SCALE, stageQuality:String=StageQuality.HIGH, showDefaultContextMenu:Boolean=false):void{
			mainObj = obj;
			stage = obj.stage;
			stageWidth = stage.stageWidth;
			stageHeight = stage.stageHeight;
			ration = stageWidth/DOC_W;
			Debug.stage = stage; 
			//Debug.registAlertStyle();
			
			//设置左上角对齐
			stage.align = stageAlign;
			//设置舞台缩放为:自适应屏幕大小
			stage.scaleMode = stageScaleMode;	
			//设置高质量渲染
			stage.quality = stageQuality;
			//不显示右键菜单
			stage.showDefaultContextMenu = showDefaultContextMenu;
		}
	}
}