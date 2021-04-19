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
	
	public class LoadingCD extends View{
		/** 加载等待超时 */
		static public const CANCEL:String = "cancel";
		
		private var modeBg:Sprite;
		private var setTimeoutId:int;
		private var tipTf:TextField;
		private var tip:MovieClip;
		
		public function LoadingCD(titleStr:String){
			
			this.initView("LoadingCDUI");
			tipTf = view["tipTf"];
			tip = view["tip"];
			tipTf.text = titleStr;
			tip.visible = false;
			tip.tf.mouseEnabled = false;
			Global.stage.addEventListener(Event.RESIZE, resizeHandler);
			this.addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
			resizeHandler(null);
		}
		
		public function setTitle(str:String):void{
			tipTf.text = str;
		}
		
		/** 设置操作超时<br>超时后提示一行文本，点击文本后发送取消事件。<br>
		 * timeout 等待超时的时间 秒 */
		public function setTimout(timeout:int):void{
			clearTimeout(setTimeoutId);
			setTimeoutId = setTimeout(timeoutHandler, timeout*1000); 
		}
		
		private function timeoutHandler():void{
			tip.visible = true;
			tip.tf.text = "网络情况不好，点击取消“"+tipTf.text+"”";
			tip.addEventListener(MouseEvent.CLICK, cancelHandler);
		}
		
		private function cancelHandler(e:MouseEvent):void{
			this.dispatchEvent(new Event(CANCEL));
		}
		
		private function createBg():void{
			if(modeBg == null){
				modeBg = new Sprite();
			}
			modeBg.graphics.clear();
			modeBg.graphics.beginFill(0x0, 0.5);
			modeBg.graphics.drawRect(0, 0, Global.stageWidth, Global.stageHeight);
			modeBg.graphics.endFill();
			modeBg.x = -x;
			modeBg.y = -y;
			addChildAt(modeBg, 0);
		}
		
		private function removedFromStageHandler(e:Event):void{
			clearTimeout(setTimeoutId);
			Global.stage.removeEventListener(Event.RESIZE, resizeHandler);
			this.removeEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
		}
		
		private function resizeHandler(e:Event):void{
			var w:Number = Global.stage.stageWidth;
			var h:Number = Global.stage.stageHeight;
			if(modeBg){
				removeChild(modeBg);
			}
			Global.setScale(this);
			view.scaleX = view.scaleY = Global.ration;
			x = int((w - this.width)/2);
			y = int((h - this.height)/2);
			createBg();
		}
	}
}