package wsl.core{
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import wsl.manager.ConfigManager;
	import wsl.protocols.IProtocolDef;
	import wsl.socket.SocketSession;
	import wsl.view.LoadingCD;
	
	/** 一个可以自己运行的独立模块<br>
	 * 加载配置文件，加载资源文件<br>
	 * 配置文件、资源文件都加载完成后如果没有登陆调用login方法、否则服务器连接完成后调用init方法,子类覆盖login、init方法。 */
	public class BaseModule extends Sprite{
		private var uriVec:Vector.<String> = new Vector.<String>;
		private var urlVec:Vector.<String> = new Vector.<String>;
		private var currentUrl:String;
		private var numRes:int = 0;
		private var isResUrl:Boolean = false;
		private var isConUrl:Boolean = false;
		private var loading:LoadingCD;
		private var tipTf:TextField;
		
		/** 会话对象，用于添加、删除协议侦听，接收、同步协议内容 */
		private var socketSession:SocketSession;
		
		private var protocolXML:IProtocolDef;
		private var remoteSocketConnect:ConnectWebSocketServer;
		
		/** 游戏模块类，每一个独立的游戏继承此类。<br>
		 * host 服务器的IP或域名。<br>
		 * port 服务器的端口。<br>
		 * type 传输协议的类型，默认值为0。 0为WebSocketProtocolParse;  1为AS3SocketProtocolParse */
		public function BaseModule(protocolXML:IProtocolDef){
			this.protocolXML = protocolXML;
			this.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
		}
		
		public function addedToStageHandler(e:Event):void{
			stage.addEventListener(Event.RESIZE, resizeHandler);
			resizeHandler(null);
			//当此模块被卸载时调用
			this.loaderInfo.addEventListener(Event.UNLOAD, unLoadHandler);
			if(Global.isMainModule == false){
				//单独调试
				trace("单独调试");
				Global.init(this);
				Global.isMainModule = true;
				Debug.stage = this.stage;
				addTip();
				loadConfig("res/flash_config.xml");
			}else{
				//做为swf模块被加载
				trace("做为swf模块被加载");
				init();
			}
		}
		
		private function resizeHandler(e:Event):void{
			Global.stageWidth = stage.stageWidth;
			Global.stageHeight = stage.stageHeight;
		}
		
		/**加载配置文件*/
		private function loadConfig(uri:String):void{
			var ld:URLLoader = new URLLoader();
			ld.addEventListener(Event.COMPLETE, loadConfigCompleteHandler);
			ld.addEventListener(IOErrorEvent.IO_ERROR, loadConfigErrorHandler);
			currentUrl = uri;
			ld.load(new URLRequest(currentUrl));
			showTip("加载配置："+currentUrl);
		}
		
		private function loadConfigErrorHandler(e:IOErrorEvent):void{
			loadConfig("../../res/flash_config.xml");
			if(isResUrl == true){
				showTip("配置文件：res/flash_config.xml与"+currentUrl+" 没有找到!");
			}else{
				isResUrl = true;
			}
		}
		
		private function loadConfigCompleteHandler(e:Event):void{
			var xml:XML = XML(e.target.data);
			Global.host = xml.socket.@host; 
			Global.port = xml.socket.@port;
			
			for(var i:uint=0; i<xml.res.children().length(); i++){
				uriVec.push(xml.res.children()[i].@uri);
				urlVec.push(xml.res.children()[i].@url);
			}
			
			loadResource();
		}
		
		/**加载界面资源*/
		private function loadResource():void{
			load(uriVec[numRes]);
		}
		
		private function load(url:String):void{
			currentUrl = url;
			showTip("加载："+currentUrl);
			var ld:Loader = new Loader();
			
			ld.load(new URLRequest(url), new LoaderContext(true, ApplicationDomain.currentDomain));
			ld.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadCompleteFun);
			ld.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onLoadProgressFun);
			ld.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
		}
		
		private function onLoadProgressFun(e:ProgressEvent):void{
			var percent:uint = uint(e.bytesLoaded / e.bytesTotal*100);
		}
		
		private function ioErrorHandler(e:IOErrorEvent):void{
			load(urlVec[numRes]);
			if(isResUrl == true){
				showTip("资源文件："+uriVec[numRes]+"与"+urlVec[numRes]+" 没有找到!");
			}else{
				isResUrl = true;
			}
		}
		
		/** 资源加载完成 */
		private function onLoadCompleteFun(e:Event):void{
			e.target.removeEventListener(Event.COMPLETE, onLoadCompleteFun);
			e.target.removeEventListener(ProgressEvent.PROGRESS, onLoadProgressFun);
			e.target.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			numRes++;
			if(numRes < uriVec.length-1){
				load(uriVec[numRes]);
				return;
			}
			uriVec = null;
			urlVec = null;
			delTip();
			
			if(Global.myName == "server" || Global.netModule == Global.NONE_CONNECT){
				init();
				return;
			}
			
			if(ConfigManager.getAutoLoging() == 1){
				Global.netModule = ConfigManager.getNetModule();
				if(Global.netModule == Global.REMOTE_CONNECT){
					var vec:Vector.<Object> = ConfigManager.getUserInfo();
					var info:Object = vec[vec.length-1];
				}else if(Global.netModule == Global.LOCAL_CONNECT){
					var ipVec:Vector.<String> = ConfigManager.getLoginIPVec();
					var userVec:Vector.<Object> = ConfigManager.getUserInfo();
					if(ipVec == null || ipVec.length < 1 || userVec == null || userVec.length < 1){
						login();
					}else{
						Global.host = ipVec[ipVec.length-1];
						Global.loginName = userVec[userVec.length-1].name;
						Global.password = userVec[userVec.length-1].pwd;
						init();
					}
				}
			}else{
				login();
			}
		}
		
		
		/** 登陆面板，此方法被子类覆盖 */
		public function login():void{
		}
		
		
		/** 此方法将被子类覆盖，当此模块连接服务器成功或被主模块加载时调用 */
		public function init():void{
		}
		
		private function addTip():void{
			tipTf = new TextField();
			tipTf.wordWrap = true;
			tipTf.multiline = true;
			tipTf.width = 400;
			tipTf.x = (stage.stageWidth - tipTf.width)/2;
			tipTf.y = (stage.stageHeight - tipTf.height)/2;
			//addChild(tipTf);
		}
		
		private function showTip(msg:String):void{
			tipTf.text = msg;
			tipTf.setTextFormat(new TextFormat(null, 20, 0xFFFFFF));
		}
		
		private function delTip():void{
			//removeChild(tipTf);
			tipTf = null;
		}
		
		/** 当此模块被卸载时调用 */
		private function unLoadHandler(e:Event):void{
			destroy();
		}
		
		/**此方法可被子类覆盖， 在此模块被删除时执行一些清理工作 */
		public function destroy():void{
			if(socketSession == null) return;
			trace("我被卸载啦！ 我的模块ID = "+socketSession.socketSessionId);
			socketSession.destroy();
			socketSession = null;
		}
	}
}