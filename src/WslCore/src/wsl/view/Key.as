package wsl.view{
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.TimerEvent;
	import flash.events.TouchEvent;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import wsl.core.View;
	import wsl.utils.Utils;

	public class Key extends View{
		/** 方向键 左  keyCode=37 */
		static public const LEFT:uint = 37;
		/** 方向键 上  keyCode=38 */
		static public const UP:uint = 38;
		/** 方向键 右  keyCode=39 */
		static public const RIGHT:uint = 39;
		/** 方向键 下  keyCode=40 */
		static public const DOWN:uint = 40;
		/** 空格键  keyCode=32 */
		static public const SPACE:uint = 32;
		/** 回车键  keyCode=13 */
		static public const ENTER:uint = 13;
		/** Home键 == 菜单键 */
		static public const HOME:uint = 36;
		/** 退格键 == 返回键 */
		static public const BACK_SPACE:uint = 8;
		
		/** 虚拟按键是否显示 */
		static public var isShowKeyboard:Boolean;
		
		/** 方向左键是否按下 */
		static public var isLeft:Boolean;
		/** 方向上键是否按下 */
		static public var isUp:Boolean;
		/** 方向右键是否按下 */
		static public var isRight:Boolean;
		/** 方向下键是否按下 */
		static public var isDown:Boolean;
		/** 空格键是否按下 */
		static public var isSpace:Boolean;
		/** 回车键是否按下 */
		static public var isEnter:Boolean;
		
		private var isDownKey:Boolean;
		private var timer:Timer;
		private var keyEvent:KeyboardEvent;
		private var timeoutID:uint;
		
		public function Key(){
			this.initView("ArrowKeyUI");
			this.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
		}
		
		private function addedToStageHandler(e:Event):void{
			this.removeEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			
			for(var i:uint=0; i<6; i++){
				view["key"+i].addEventListener(TouchEvent.TOUCH_BEGIN, touchHandler);
				view["key"+i].addEventListener(TouchEvent.TOUCH_END, touchHandler);
				view["key"+i].addEventListener(TouchEvent.TOUCH_OUT, touchHandler);
				view["key"+i].alpha = 0.5;
			}
			
			filters = [Utils.getDropShadowFilter(4, 4, 1, 3)];
			x = 0;
			y = stage.stageHeight - height;
			
			view["key5"].x = stage.stageWidth - view["key5"].width;
			view["key4"].x = view["key5"].x - view["key4"].width - 30;
			
			timer = new Timer(100);
			timer.addEventListener(TimerEvent.TIMER, timerHandler);
		}
		
		private function timerHandler(e:TimerEvent):void{
			stage.dispatchEvent(keyEvent);
		}
		
		private function touchHandler(e:TouchEvent):void{
			var keyCode:uint = parseInt((e.target.name as String).charAt(3));
			if(keyCode == 4){
				keyCode = 32;
			}else if(keyCode == 5){
				keyCode = 13;
			}else{
				keyCode = 37+keyCode;
			}
			
			if(e.type == TouchEvent.TOUCH_BEGIN){
				keyEvent = new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, keyCode);
				stage.dispatchEvent(keyEvent);
				
				e.target.gotoAndStop(2);
				clearTimeout(timeoutID);
				if(timer.running) timer.stop();
				timeoutID = setTimeout(timer.start, 500);
			}else{
				if(e.target.currentFrame == 1) return; 
				
				e.target.gotoAndStop(1);
				clearTimeout(timeoutID);
				if(timer.running) timer.stop();
				
				keyEvent = new KeyboardEvent(KeyboardEvent.KEY_UP, true, false, 0, keyCode);
				stage.dispatchEvent(keyEvent);
			}
		}
		
		static public function setKeyDown(keyCode:int):void{
			if(keyCode == LEFT){
				isLeft = true;
			}else if(keyCode == UP){
				isUp = true;
			}else if(keyCode == RIGHT){
				isRight = true;
			}else if(keyCode == DOWN){
				isDown = true;
			}else if(keyCode == SPACE){
				isSpace = true;
			}else if(keyCode == ENTER){
				isEnter = true;
			}
		}
		
		static public function setKeyUp(keyCode:int):void{
			if(keyCode == LEFT){
				isLeft = false;
			}else if(keyCode == UP){
				isUp = false;
			}else if(keyCode == RIGHT){
				isRight = false;
			}else if(keyCode == DOWN){
				isDown = false;
			}else if(keyCode == SPACE){
				isSpace = false;
			}else if(keyCode == ENTER){
				isEnter = false;
			}
		}
	}
}