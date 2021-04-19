package wsl.view.listpanel {
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.DropShadowFilter;
	import flash.geom.Rectangle;
	
	import wsl.core.View;
	
	public class ScrollView extends Sprite{
		private var w:Number;
		private var h:Number;
		private var bg:Sprite;
		private var content:View;
		private var contentMask:Sprite;
		private var scrollThumb:MovieClip;
		private var isThumbHight:Boolean = true;
		
		private var cr:Number;
		private var speed:Number = 0.2;// 0.00 to 1.00
		private var isScroll:Boolean = false;
		private var mY:Number;
		private var contentH:int;
		
		private var isMove:Boolean;
		private var downY:Number;
		
		public function ScrollView(content:View, w:Number, h:Number){
			this.content = content;
			this.w = w;
			this.h = h;
			this.addChild(content);
			
			createBg();
			createContentMask();
			createScrollThumb();
			setSize(w, h);
			setScroll();
			
			this.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
			this.addEventListener(MouseEvent.MOUSE_WHEEL, wheelHandler);
			
			this.addEventListener(MouseEvent.MOUSE_DOWN, downHandler, true);
			this.addEventListener(MouseEvent.MOUSE_UP, upHandler, true);
			this.addEventListener(MouseEvent.CLICK, clickHandler, true);
		}
		
		private function downHandler(e:MouseEvent):void{
			if(h >= content.height) return;
			this.addEventListener(MouseEvent.MOUSE_MOVE, moveHandler, true);
			
			isMove = false;
			downY = mouseY;
		}
		
		private function moveHandler(e:MouseEvent):void{
			if(isMove == true){
				setScrollThumb(scrollThumb.y - (mouseY - downY));
				downY = mouseY;
				return;
			}
			if(Math.abs(mouseY - downY) > 6){
				isMove = true;
			}
		}
		
		private function upHandler(e:MouseEvent):void{
			this.removeEventListener(MouseEvent.MOUSE_MOVE, moveHandler, true);
			if(isMove == true){
				e.stopPropagation();
			}
		}
		
		private function clickHandler(e:MouseEvent):void{
			if(isMove == true){
				e.stopPropagation();
			}
		}
		
		private function createBg():void{
			bg = new Sprite();
			//bg.filters = [getDropShadowFilter()];
			bg.graphics.clear();
			bg.graphics.beginFill(0xcdcdcd, 1);
			bg.graphics.drawRect(0, 0, 100, 100);
			bg.graphics.endFill();
			addChildAt(bg, 0);
		}
		
		private function createContentMask():void{
			if(contentMask == null){
				contentMask = new Sprite();
				addChild(contentMask);
			}
			contentMask.graphics.clear();
			contentMask.graphics.beginFill(0xFFFFFF);
			contentMask.graphics.drawRect(0, 0, w, h);
			contentMask.graphics.endFill();
			content.mask = contentMask;
		}
		
		private function createScrollThumb():void{
			scrollThumb = new MovieClip();
			scrollThumb.graphics.beginFill(0x43B4FF);
			scrollThumb.graphics.drawRoundRect(0, 0, 8, 20, 5, 5);
			scrollThumb.scale9Grid = new Rectangle(1, 6, 5, 8);
			scrollThumb.graphics.endFill();
			
			scrollThumb.focusRect = false;
			//scrollThumb.buttonMode = true;
			//scrollThumb.useHandCursor = true;
			scrollThumb.gotoAndStop(1);
			addChild(scrollThumb);
			//scrollThumb.addEventListener(MouseEvent.MOUSE_OVER, scrollThumbOverHandler);
			//scrollThumb.addEventListener(MouseEvent.MOUSE_OUT, scrollThumbOutHandler);
			//scrollThumb.addEventListener(MouseEvent.MOUSE_DOWN, scrollThumbDownHandler);
		}
		
		private function scrollThumbOverHandler(e:MouseEvent):void{
			scrollThumb.gotoAndPlay(2);
		}
		
		private function scrollThumbOutHandler(e:MouseEvent):void{
			if(isThumbHight){
				scrollThumb.gotoAndPlay(11);
			}
		}
		
		private function scrollThumbDownHandler(e:MouseEvent):void{
			isThumbHight = false;
			mY = mouseY;
			stage.addEventListener(MouseEvent.MOUSE_UP, stageUpHandler);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, stageMoveHandler);
		}
		
		private function stageMoveHandler(e:MouseEvent):void{
			isScroll = true;
			scrollThumb.y += (mouseY - mY);
			
			if(scrollThumb.y > h - scrollThumb.height){
				scrollThumb.y = h - scrollThumb.height;
			}
			if(scrollThumb.y < 0 ){
				scrollThumb.y = 0;
			}
			mY = mouseY;
		}
		
		private function stageUpHandler(e:MouseEvent):void{
			isThumbHight = true;
			scrollThumb.gotoAndPlay(11);
			stage.removeEventListener(MouseEvent.MOUSE_UP, stageUpHandler);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, stageMoveHandler);
		}
		
		private function setScroll():void{
			scrollThumb.height = h*h / contentH < 10 ? 10 :  h*h / contentH;
			
			var sd:Number = h - scrollThumb.height;
			var cd:Number = contentH - h;
			cr = cd / sd * 1.0;
			
			if (contentH <= h){
				scrollThumb.visible = false;
			}else{
				scrollThumb.visible = true;
			}
			
			scrollThumb.y = 0;
			isScroll = true;
		}
		
		private function enterFrameHandler(e:Event):void{
			if(isScroll == false) return;
			
			if(scrollThumb.y > h - scrollThumb.height){
				scrollThumb.y = h - scrollThumb.height;
			}
			if(scrollThumb.y < 0 ){
				scrollThumb.y = 0;
			}
			var newY:Number = -scrollThumb.y * cr;
			if(Math.abs((newY-content.y)*speed) < 1){
				content.y = int(newY);
				isScroll = false;
			}else{
				content.y += (newY - content.y) * speed;
			}
		}
		
		public function setScrollThumb(n:Number):void{
			isScroll = true;
			if(n > h - scrollThumb.height){
				scrollThumb.y = h - scrollThumb.height;
				return;
			}
			if(n < 0 ){
				scrollThumb.y = 0;
				return;
			}
			scrollThumb.y = n;
		}
		
		public function scrollTo(y:Number):void{
			setScrollThumb(y/cr);
		}
		
		public function update(contentH:Number):void{
			this.contentH = contentH;
			setScroll();
			
			if(content.width > w){
				bg.width = int(w);
			}else{
				bg.width = int(content.width);
			}
			if(content.height > h){
				bg.height = int(h);
			}else{
				bg.height = int(content.height);
			}
		}
		
		public function setSize(w:Number, h:Number):void{
			this.w = w;
			this.h = h;
			
			contentMask.width = int(w);
			contentMask.height = int(h);
			scrollThumb.x = w - scrollThumb.width;
			content.setSize(w, h);
			setScroll();
			
			if(content.width > w){
				bg.width = int(w);
			}else{
				bg.width = int(content.width);
			}
			if(content.height > h){
				bg.height = int(h);
			}else{
				bg.height = int(content.height);
			}
		}
		
		override public function set visible(b:Boolean):void{
			super.visible = b;
			if(b){
				this.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
			}else{
				this.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			}
		}
		
		public function move(x:Number, y:Number):void{
			this.x = int(x);
			this.y = int(y);
		}
		
		public function getContent():Sprite{
			return content;
		}
		
		public function getBg():Sprite{
			return bg;
		}
		
		public function getW():Number{
			return w;
		}
		
		public function getH():Number{
			return h;
		}
		
		public function getIsMove():Boolean{
			return isMove;
		}
		
		private function wheelHandler(e:MouseEvent):void{
			if(scrollThumb.visible == false) return;
			setScrollThumb(scrollThumb.y-e.delta*5);
		}
		
		private function getDropShadowFilter(alpha:Number= 0.9, strength:Number = 0.8):DropShadowFilter {
			var color:Number = 0x000000;
			var angle:Number = 45;
			var blurX:Number = 5;
			var blurY:Number = 5;
			var distance:Number = 7;
			var inner:Boolean = false;
			var knockout:Boolean = false;
			var quality:Number = BitmapFilterQuality.HIGH;
			return new DropShadowFilter(distance,angle,color,alpha,blurX,blurY,strength,quality,inner,knockout);
		}
	}
}