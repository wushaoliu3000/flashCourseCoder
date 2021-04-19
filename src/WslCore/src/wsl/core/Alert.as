package wsl.core{
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import wsl.utils.McToBtn;

	public class Alert extends View{
		private var modeBg:Sprite;
		public var bg:MovieClip;
		private var titleTf:TextField;
		private var tipTf:TextField;
		private var tipCB:MovieClip;
		private var tipCBStr:String;
		private var okBtn:MovieClip;
		private var cancelBtn:MovieClip;
		private var closeBtn:MovieClip;
		private var okBackFun:Function;
		private var okParam:Object;
		private var cancelBackFun:Function;
		private var cancelParam:Object;
		
		public function Alert(){
			this.initView("SystemAlertPanel");
			bg = view["bg"];
			titleTf = view["titleTf"];
			tipTf = view["tipTf"];
			tipCB = view["tipCB"];
			closeBtn = view["closeBtn"];
			okBtn = view["okBtn"];
			cancelBtn = view["cancelBtn"];
			McToBtn.setBtn(closeBtn);
			McToBtn.setBtn(okBtn);
			McToBtn.setBtn(cancelBtn); 
			okBtn.labelTf.mouseEnabled = false;
			tipCB.labelTf.mouseEnabled = false;
			
			createModeBg();
			okBtn.visible = false;
			cancelBtn.visible = false;
			closeBtn.addEventListener(MouseEvent.CLICK, closeBtnHandler);
			okBtn.addEventListener(MouseEvent.CLICK, okBtnHandler);
			cancelBtn.addEventListener(MouseEvent.CLICK, cancelBtnHandler);
			tipCB.addEventListener(MouseEvent.CLICK, tipCBHandler);
			
			Global.stage.addEventListener(Event.RESIZE, resizeHandler);
		}
		
		private function createModeBg():void{
			if(modeBg == null){
				modeBg = new Sprite();
			}
			modeBg.graphics.clear();
			modeBg.graphics.beginFill(0x0, 0.5);
			modeBg.graphics.drawRect(0, 0, Global.stageWidth, Global.stageHeight);
			modeBg.graphics.endFill();
			modeBg.x = 0;
			modeBg.y = 0;
		}
		
		public function setBlank(r:Rectangle):void{
			var g:Graphics = modeBg.graphics;
			g.clear();
			var x:int = int(r.x*Global.ration);
			var y:int = int(r.y*Global.ration);
			var w:int = int(r.width*Global.ration);
			var h:int = int(r.height*Global.ration);
			g.beginFill(0x333333, 0.7);
			g.drawRect(0, 0, Global.stageWidth, Global.stageHeight);
			g.drawRect(x, y, w, h);
			g.beginFill(0xFFFFFF, 0.01);
			g.drawRect(x, y, w, h);
			g.endFill();
		}
		
		public function setMessage(msg:String, title:String="", okBackFun:Function=null, okParam:Object=null, okLabel:String="确定", cancelBackFun:Function=null, cancelParam:Object=null, cancelLabel:String="取消", hideColseBtn:Boolean=false, tipCBStr:String=""):void{
			this.okBackFun = okBackFun;
			this.okParam = okParam;
			this.cancelBackFun = cancelBackFun;
			this.cancelParam = cancelParam;
			this.tipTf.htmlText = msg;
			this.tipCBStr = tipCBStr;
			okBtn.labelTf.text = okLabel;
			cancelBtn.labelTf.text = cancelLabel;
			closeBtn.visible = hideColseBtn == false
			titleTf.text = title == ""? "系统提示:" : title;
			okBtn.visible = okBackFun != null;
			cancelBtn.visible = cancelBackFun!== null;
			
			tipTf.height = tipTf.textHeight+20;
			tipTf.x = 20;
			tipTf.y = 80;
			
			tipCB.gotoAndStop(1);
			tipCB.labelTf.text = tipCBStr;
			tipCB.visible = tipCBStr == "" ? false : true;
			tipCB.y = tipCB.visible ? tipTf.y +tipTf.height+10 : tipTf.y+tipTf.height - tipCB.height;
			
			okBtn.y = cancelBtn.y = tipCB.y + tipCB.height+10;
			
			if(okBtn.visible && cancelBtn.visible){
				okBtn.x = 80;
				cancelBtn.x = 370;
			}else  if(okBtn.visible){
				okBtn.x = 220;
			}else if(cancelBtn.visible){
				cancelBtn.x = 220;
			}
			
			if(okBtn.visible || cancelBtn.visible){
				bg.height = okBtn.y + okBtn.height + 20;
			}else{
				bg.height = okBtn.y;
			}
			
			resizeHandler(null);
			Global.stage.addChild(modeBg);
			Global.stage.addChild(this);
		}
		
		private function okBtnHandler(e:MouseEvent):void{
			if(okBackFun != null){
				if(okParam != null){
					if(tipCBStr == ""){
						okBackFun(okParam);
					}else{
						okBackFun(okParam, tipCB.currentFrame == 2);
					}
				}else{
					if(tipCBStr == ""){
						okBackFun();
					}else{
						okBackFun(tipCB.currentFrame == 2);
					}
				}
			}
			clear();
			e.stopImmediatePropagation();
		}
		
		private function cancelBtnHandler(e:MouseEvent):void{
			if(cancelBackFun != null){
				if(cancelParam != null){
					cancelBackFun(cancelParam);
				}else{
					cancelBackFun();
				}
			}
			clear();
			e.stopImmediatePropagation();
		}
		
		private function clear():void{
			okBackFun = null;
			okParam = null;
			cancelBackFun = null;
			cancelParam = null;
			tipCB.gotoAndStop(1);
			tipCBStr = null;
			closeBtnHandler(null);
		}
		
		private function tipCBHandler(e:MouseEvent):void{
			tipCB.gotoAndStop(tipCB.currentFrame == 1 ? 2 : 1);
		}
		
		private function closeBtnHandler(e:MouseEvent):void{
			stage.removeChild(modeBg);
			stage.removeChild(this);
			Debug.isAlt = true;
			if(e == null) return;
			e.stopImmediatePropagation();
		}
		
		private function resizeHandler(e:Event):void{
			var w:Number = Global.stage.stageWidth;
			var h:Number = Global.stage.stageHeight;
			this.scaleX = this.scaleY = Global.ration;
			x = int((w - bg.width*scaleX)/2);
			y = int((h - bg.height*scaleX)/2);
			createModeBg();
		}
	}
}