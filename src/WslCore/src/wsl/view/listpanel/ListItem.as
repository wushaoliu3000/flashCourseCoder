package wsl.view.listpanel{
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	import wsl.core.View;
	import wsl.view.listpanel.ListItemVO;
	
	public class ListItem extends View{
		private var _nameTf:TextField;
		private var _bg:MovieClip;
		private var _data:String;
		private var _bgType:int;
		
		public function ListItem(){
			this.initView("ListPanelItemUI");
			view.gotoAndStop(1);
			addChild(view);
			initUI();
		}
		
		private function initUI():void{
			_nameTf = view["nameTf"];
			_bg = view["bg"];
			_bg.doubleClickEnabled = true;
			_nameTf.mouseEnabled = false;
		}
		
		public function setData(vo:ListItemVO):void{
			_nameTf.text = vo.name;
			_data = vo.data;
		}
		
		override public function setSize(w:Number, h:Number):void{
			_bg.width = w;
			_nameTf.width = w - 15;
		}
		
		public function get nameTf():TextField{
			return _nameTf;
		}
		
		public function get label():String{
			return _nameTf.text;
		}
		
		public function get data():String{
			return _data;
		}
		
		public function get bg():MovieClip{
			return _bg;
		}
		
		public function get isSelected():Boolean{
			return _bg.currentFrame == 3;
		}
		
		public function get bgType():int{
			return _bgType;
		}
		
		public function set bgType(value:int):void{
			_bgType = value;
			_bg.gotoAndStop(value);
		}
	}
}
