package wsl.view{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import wsl.core.Global;
	import wsl.core.View;
	
	public class LoadingProgress extends View{
		/** 加载等待超时 */
		static public const CANCEL:String = "loadTimeout";
		
		private var modeBg:Sprite;
		private var setTimeoutId:int;
		/** 等待超时的时间 秒*/
		private var timeout:int;
		
		private var titleTf:TextField;
		private var tipTf:TextField;
		private var progressBar:MovieClip;
		private var tip:MovieClip;
		
		/** titleStr 操作的标题<br>
		 * timeout 等待超时的时间 秒, 默认为30秒。超时后提示一行文本，点击文本后发送取消事件。<br>
		 * tiemout = 0 表示不需要设置超时。*/
		public function LoadingProgress(title:String, timeout:int=30){
			this.timeout = timeout;
			this.initView("LoadingProgressUI");
			titleTf = view["titleTf"];
			tipTf = view["tipTf"];
			progressBar = view["progressBar"];
			tip = view["tip"];
			titleTf.text = title;
			tip.visible = false;
			tip.tf.mouseEnabled = false;
			this.addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
			initUI();
		}
		
		private function initUI():void{
			var w:Number = Global.stage.stageWidth;
			var h:Number = Global.stage.stageHeight;
			if(modeBg){
				removeChild(modeBg);
			}
			
			view.scaleX = view.scaleY = Global.ration;
			x = int((w - this.width)/2);
			y = int((h - this.height)/2);
			createBg();
		}
		
		/** 设置加载进度<br>
		 * n 已经加载的百分比 */
		public function setProgress(n:Number):void{
			progressBar.scaleX = n;
		}
		
		/** 设置提示文本 */
		public function setTip(tipStr:String):void{
			tipTf.text = tipStr;
			if(timeout != 0){
				setTimout();
			}
		}
		
		public function setTitle(str:String):void{
			titleTf.text = str;
			if(timeout != 0){
				setTimout();
			}
		}
		
		public function getTitle():String{
			return titleTf.text;
		}
		
		private function setTimout():void{
			clearTimeout(setTimeoutId);
			setTimeoutId = setTimeout(timeoutHandler, timeout*1000); 
		}
		
		private function timeoutHandler():void{
			tip.visible = true;
			tip.tf.text = "网络情况不好，点击取消“"+titleTf.text+"”";
			tip.addEventListener(MouseEvent.CLICK, cancelHandler);
		}
		
		private function cancelHandler(e:MouseEvent):void{
			Global.socketConnectFailHandler(null);
			this.dispatchEvent(new Event(CANCEL));
		}
		
		private function createBg():void{
			if(modeBg == null){
				modeBg = new Sprite();
			}
			modeBg.graphics.clear();
			modeBg.graphics.beginFill(0x0, 0.7);
			modeBg.graphics.drawRect(0, 0, Global.stageWidth, Global.stageHeight);
			modeBg.graphics.endFill();
			modeBg.x = -x;
			modeBg.y = -y;
			addChildAt(modeBg, 0);
		}
		
		private function removedFromStageHandler(e:Event):void{
			clearTimeout(setTimeoutId);
			this.removeEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
		}
	}
}