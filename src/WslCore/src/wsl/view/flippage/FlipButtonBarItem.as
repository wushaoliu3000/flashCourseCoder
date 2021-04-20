package wsl.view.flippage{
	import flash.display.MovieClip;
	
	import wsl.core.View;
	
	public class FlipButtonBarItem extends View{
		private var pageIndex:int;
		private var _index:int;
		public var icon:MovieClip;
		
		public function FlipButtonBarItem(){
			this.initView("FlipButtonBarItemUI");
			icon = view["icon"];
			view.mouseEnabled = false;
			view.mouseChildren = false;
		}
		
		public function setPageIndex(n:int):void{
			pageIndex = n;
			this.icon.tf.text = ""+(n+1);
		}
		
		public function getPageIndex():int{
			return pageIndex;
		}
		
		public function set index(n:int):void{
			//this.icon.pageTf.text = ""+n;
			_index = n;
		}
		
		public function get index():int{
			return _index;
		}
		
		public function dispalyPageNumber(b:Boolean):void{
			this.icon.tf.visible = b;
		}
		
		public function setScalse(n:Number):void{
			icon.scaleX = icon.scaleY = n;
		}
		
		public function getScalse():Number{
			return icon.scaleX;
		}
	}
}