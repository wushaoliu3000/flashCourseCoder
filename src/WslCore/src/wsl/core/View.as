package wsl.core{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import wsl.manager.DefinitionManager;
	
	
	public class View extends Sprite{
		public var view:MovieClip;
		
		public function View(){
		}
		
		public function initView(viewName:String):void{
			view = DefinitionManager.getDefinitionInstance(viewName) as MovieClip;
			addChild(view);			
		}
		
		public function move(px:Number, py:Number):void{
			this.x = int(px);
			this.y = int(py);
			if(view.parent != this){
				view.x = int(px);
				view.y = int(py);
			}
		}
		
		public function setSize(w:Number, h:Number):void{	
		}
		
		override public function set visible(b:Boolean):void{
			super.visible = b;
			if(view != null){view.visible = b;}
		}
		
		public function clear():void{
			throw Error("View.clear()方法必需被子类覆盖");
		}
	}
}