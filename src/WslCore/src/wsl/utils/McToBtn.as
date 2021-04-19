package wsl.utils{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.Dictionary;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	public class McToBtn{
		static private var tip:Sprite;
		static private var tipDic:Dictionary = new Dictionary();
		static private var mc:MovieClip;
		static private var timeoutId:int;
		
		public function McToBtn(){
		}
		
		static public function setBtn(mc:MovieClip, tipStr:String="", useHandCursor:Boolean=false):void{
			mc.gotoAndStop(1);
			McToBtn.mc = mc;
			if(useHandCursor){
				mc.buttonMode = true;
				mc.useHandCursor = true;
			}
			mc.addEventListener(MouseEvent.MOUSE_OVER, overHandler);
			mc.addEventListener(MouseEvent.MOUSE_DOWN, overHandler);
			mc.addEventListener(MouseEvent.MOUSE_OUT, outHandler);
			mc.addEventListener(MouseEvent.MOUSE_UP, outHandler);
			if(tipStr != ""){
				tipDic[mc.name] = tipStr;
				mc.addFrameScript(11, tipFun);
			} 
		}
		
		static private function overHandler(e:MouseEvent):void{
			mc = e.currentTarget as MovieClip;
			if(mc["labelTf"]) mc["labelTf"].mouseEnabled = false;
			if(mc.mouseChildren && mc.mouseEnabled && mc.currentFrame != 25){
				e.currentTarget.gotoAndPlay(2);
			}
		}
		
		static private function outHandler(e:MouseEvent):void{
			if(mc == null) return;
			mc = e.currentTarget as MovieClip;
			if(mc.mouseChildren && mc.mouseEnabled  && mc.currentFrame != 25){
				e.currentTarget.gotoAndPlay(13);
				removeTip();
			}
			mc = null;
		}
		
		static private function tipFun():void{
			mc.stop();
			createTip(tipDic[mc.name]);
			timeoutId = setTimeout(removeTip, 2000);
		}
		
		static private function createTip(tipStr:String):void{
			if(tipStr == "" || tipStr == null || !mc || mc.stage == null) return;
			var tf:TextField;
			if(tip == null){
				tip = new Sprite();
				tf = new TextField();
				tf.name = "tipTf";
				tf.mouseEnabled = false;
				tf.x = 2;
				tip.addChild(tf);
				tip.mouseEnabled = false;
				tip.mouseChildren = false;
				tip.filters = [getGlowFilter()];
			}else{
				tf = tip.getChildByName("tipTf") as TextField;
			}
			tf.text = tipStr;
			tf.width = tf.textWidth+5;
			tf.height = tf.textHeight+3;
			
			tip.graphics.clear();
			tip.graphics.beginFill(0xFFF9E2, 1);
			tip.graphics.drawRoundRect(0, 0, tf.textWidth+6, tf.textHeight+4, 5, 5);
			tip.graphics.endFill();
			
			var p:Point = new Point(mc.x, mc.y);
			p = mc.parent.localToGlobal(p);
			
			tip.x = p.x-Math.abs(int((mc.width-tip.width)/2));
			tip.y = p.y - tip.height;
			
			if(tip.x < 3){
				tip.x = 3;
			}else if(tip.x+tip.width > mc.stage.stageWidth-3){
				tip.x = mc.stage.stageWidth-tip.width-3;
			}
			if(tip.y < 3){
				tip.y = tip.height+10;
			}
			
			mc.stage.addChild(tip);
		}
		
		static private function removeTip():void{
			if(tip && tip.stage){
				tip.stage.removeChild(tip);
			}
			clearTimeout(timeoutId);
		}
		
		static private function getGlowFilter():GlowFilter {
			var color:Number = 0x333333;
			var alpha:Number = 1;
			var blurX:Number = 3;
			var blurY:Number = 3;
			var strength:Number = 1.5;
			var inner:Boolean = false;
			var knockout:Boolean = false;
			var quality:Number = BitmapFilterQuality.HIGH;
			
			return new GlowFilter(color,alpha,blurX,blurY,strength,quality,inner,knockout);
		}
	}
}