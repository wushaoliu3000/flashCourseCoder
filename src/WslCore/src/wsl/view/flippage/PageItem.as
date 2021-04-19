package wsl.view.flippage{
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.text.TextField;
	
	import wsl.core.View;
	import wsl.manager.DefinitionManager;
	
	public class PageItem extends View{
		private var _id:int;
		public var loader:*;
		public var loaderMask:MovieClip;
		public var titleTf:TextField;
		private var isExternal:Boolean;
		
		public function PageItem(){
			this.initView("PageItemUI");
			
			loader = view["loader"];
			loaderMask = view["loaderMask"];
			titleTf = view["titleTf"];
			this.loader.mask = this.loaderMask;
		}
		
		public function addData(vo:PageItemVO):void{
			if(vo.maskType == 0){
				this.loaderMask.gotoAndStop(1);
			}else{
				this.loaderMask.gotoAndStop(vo.maskType);
			}
			this._id = vo.id;
			isExternal = true;
			if(DefinitionManager.hasDefinition(vo.thumb) != null){
				isExternal = false;
				loadCompleteHandler(null);
			}
			this.loader.source = vo.thumb;
			this.loader.addEventListener(Event.COMPLETE, loadCompleteHandler);
			this.titleTf.text = vo.label;
			this.titleTf.mouseEnabled = false;
			this.visible = true;
		}
		
		public function clearData():void{
			this.loader.unload();
			this.titleTf.text = "";
			this.visible = false;
		}
		
		/** 通过此id可以在FlipPageView类中的itemVec中找到与本实例相关的PageItemVO */
		public function get id():int{
			return _id;
		}
		
		private function loadCompleteHandler(e:Event):void{
			if(isExternal == true){
				(e.target.content as Bitmap).smoothing = true;
			}
			this.dispatchEvent(new Event(Event.COMPLETE));
		}
	}
}