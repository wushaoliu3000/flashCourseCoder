package wsl.utils{
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import wsl.core.Debug;

	public class MyLoader{
		static private var currentUrl:String;
		static private var reserveUri:String;
		static private var isError:Boolean;
		static private var backFun:Function;
		static private var isLoadText:Boolean;
		
		public function MyLoader(){
		}
		
		/**加载文本文件，可以通过一个备用地址<br>
		 * uri 文件地址<br>
		 * reserveUri 备用地址<br>
		 * backFun 加载完成后要回调的函数，此函数接收一个字符串做为参数*/
		static public function loadTextByReserveUri(uri:String, reserveUri:String, backFun:Function):void{
			MyLoader.currentUrl = uri;
			MyLoader.reserveUri = reserveUri;
			MyLoader.backFun = backFun;
			isLoadText = true;
			loadConfig(MyLoader.currentUrl);
		}
		
		/**加载图片或swf文件，可以通过一个备用地址<br>
		 * uri 文件地址<br>
		 * reserveUri 备用地址<br>
		 * backFun 加载完成后要回调的函数，此函数的参数为加载的内容*/
		static public function loadByReserveUri(uri:String, reserveUri:String, backFun:Function):void{
			MyLoader.currentUrl = uri;
			MyLoader.reserveUri = reserveUri;
			MyLoader.backFun = backFun;
			isLoadText = false;
			loadConfig(MyLoader.currentUrl);
		}
		
		static private function loadConfig(uri:String):void{
			if(isLoadText == true){
				var urlLd:URLLoader = new URLLoader();
				urlLd.addEventListener(Event.COMPLETE, loadConfigCompleteHandler);
				urlLd.addEventListener(IOErrorEvent.IO_ERROR, loadConfigErrorHandler);
				urlLd.load(new URLRequest(uri));
			}else{
				var ld:Loader = new Loader();
				ld.contentLoaderInfo.addEventListener(Event.COMPLETE, loadConfigCompleteHandler);
				ld.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loadConfigErrorHandler);
				ld.load(new URLRequest(uri));
			}
		} 
		
		static private function loadConfigErrorHandler(e:IOErrorEvent):void{
			if(isError == true){
				Debug.alert(currentUrl+"或"+reserveUri+"没有找到");
			}else{
				loadConfig(reserveUri);
				isError = true;
			}
		}
		
		static private function loadConfigCompleteHandler(e:Event):void{
			if(isLoadText == true){
				backFun(e.target.data);
			}else{
				backFun(e.target.content);
			}
			backFun = null;
		}
	}
}