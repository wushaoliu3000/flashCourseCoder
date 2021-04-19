package wsl.core{
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	import wsl.manager.DefinitionManager;
	
	public class SubModule extends Sprite{
		private var ld:Loader;
		
		public function SubModule(){
		}
		
		public function loadSwf(swfUri:String):void{
			var f:File = new File(swfUri);
			if(f.exists == false){
				Debug.alert("游戏文件"+swfUri+"不存在！");
				return;
			}
			
			var fs:FileStream = new FileStream();
			fs.open(f, FileMode.READ);
			var ba:ByteArray = new ByteArray();
			fs.readBytes(ba);
			fs.close();
			
			ld = new Loader();
			DefinitionManager.loadInfo = ld.contentLoaderInfo;
			ld.contentLoaderInfo.addEventListener(Event.COMPLETE, ldHandler);
			var lc:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain, null);
			lc.allowCodeImport = true;
			//ld.load(new URLRequest(swfUri), lc);
			ld.loadBytes(ba, lc);
		}
		
		private function ldHandler(e:Event):void{
			init();
		}
		
		/** 必须被子类覆盖，实现子类的初始化 */
		public function init():void{
			
		}
		
		public function setSize(w:Number, h:Number):void{
			
		}
		
		/** 可以被子类覆盖， 但子类中必须调用此法于卸载加载的swf */
		public function clear():void{
			ld.unload();
			DefinitionManager.loadInfo = null;
		}
	}
}