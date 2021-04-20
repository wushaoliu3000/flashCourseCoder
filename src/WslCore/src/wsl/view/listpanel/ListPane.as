package wsl.view.listpanel{
	import flash.events.DataEvent;
	import flash.events.MouseEvent;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import wsl.core.View;
	
	public class ListPane extends View{
		static public const SELECT_ITEM:String = "selectItem";
		static public const LONG_PRESS:String = "longPress";
		
		private var w:int; 
		private var h:int;
		private var _id:int = 1;
		private var _selectedIndex:int;
		private var _selectedItem:ListItem;
		private var _overItem:ListItem;
		private var isSelect:Boolean;
		private var isMultiple:Boolean;
		private var isLongPress:Boolean;
		private var isLongItemSelected:Boolean;
		private var isHideLabel:Boolean = false;
		private var timeoutId:uint;
		
		/** isMultiple是否可以同时选择多个实例<br>
		 *  isSelect为true,则在已经选择的实例上点击也生效 */
		public function ListPane(isMultiple:Boolean=true, isSelect:Boolean=false, isLongPress:Boolean=false){
			this.isMultiple = isMultiple;
			this.isSelect = isSelect;
			this.isLongPress = isLongPress;
			this.graphics.beginFill(0xFFFFFF,0);
			this.graphics.drawRect(0, 0, 100, 30);
			this.graphics.endFill();
		}
		
		/** 添加实例 */
		public function addItem(vo:ListItemVO, textColor:Number=0x0):void{
			var item:ListItem = new ListItem(); 
			if(textColor != 0x0){
				item.nameTf.textColor = textColor;
			}
			item.setData(vo);
			if(isHideLabel){
				item.nameTf.visible = false;
			}
			item.doubleClickEnabled = true;
			item.addEventListener(MouseEvent.MOUSE_DOWN, downHandler);
			addChild(item);
			
			layout();
		}
		
		/** 删除实例通过ID<br> 
		 * id ListItemVO.data值，通过ListItemVO.data来删除对象*/
		public function removeItemById(id:String):void{
			var item:ListItem;
			for(var i:uint=0; i<numChildren; i++){
				item = getChildAt(i) as ListItem;
				if(item.data == id){
					removeChild(item);
					break;
				}
			}
			layout();
		}
		
		public function removeAll():void{
			while(numChildren>0){
				removeChildAt(0);
			}
		}
		
		private function downHandler(e:MouseEvent):void{
			(e.currentTarget as ListItem).addEventListener(MouseEvent.CLICK, clickHandler);
			stage.addEventListener(MouseEvent.MOUSE_UP, upHandler);
			if(isLongPress == true){
				timeoutId = setTimeout(longPress, 600, e.currentTarget as ListItem);
			}
		}
		
		private function upHandler(e:MouseEvent):void{
			stage.removeEventListener(MouseEvent.MOUSE_UP, upHandler);
			if(isLongPress == true){
				clearTimeout(timeoutId);
			}
		}
		
		private function longPress(item:ListItem):void{
			item.removeEventListener(MouseEvent.CLICK, clickHandler);
			var sv:ScrollView = parent as ScrollView;
			if(sv && sv.getIsMove()){
				return;
			}
			
			var li:ListItem
			for(var i:uint=0; i<numChildren; i++){
				li = getChildAt(i) as ListItem;
				if(li.bg.currentFrame == 4){
					if(isLongItemSelected){
						li.bg.gotoAndStop(3);
					}else{
						li.bg.gotoAndStop(li.bgType);
					}
					break;
				}
			}
			
			isLongItemSelected = item.bg.currentFrame == 3;
			item.bg.gotoAndStop(4);
			_selectedIndex = getChildIndex(item);
			
			this.dispatchEvent(new DataEvent(LONG_PRESS, false, false, item.data));
		}
		
		private function clickHandler(e:MouseEvent):void{
			var de:DataEvent = new DataEvent(SELECT_ITEM, false, false, e.currentTarget["data"]);
			var item:ListItem = e.currentTarget as ListItem;
			if(isMultiple == true){
				selectedItem = item;
				this.dispatchEvent(de);
			}else{
				if(_selectedItem == null){
					selectedItem = item;
					this.dispatchEvent(de);
					return;
				}
				if(item == selectedItem && isSelect == false){
				}else{
					selectedItem = item;
					this.dispatchEvent(de);
				}
			}
		}
		
		private function layout():void{
			var tempH:uint = 0;
			var item:ListItem;
			for(var i:uint=0; i<numChildren; i++){
				item = getChildAt(i) as ListItem;
				item.y = tempH;
				item.setSize(w, h);
				item.bgType = i%2+1;
				tempH += getChildAt(i).height+1;
			}
		}
		
		override public function setSize(w:Number, h:Number):void{
			this.w = w;
			this.h = h;
			var item:ListItem;
			for(var i:uint=0; i<numChildren; i++){
				item = getChildAt(i) as ListItem;
				item.setSize(w, h);
			}
		}
		
		public function hideLabel(b:Boolean):void{
			isHideLabel = b;
			if(b){
				for(var i:uint=0; i<numChildren; i++){
					getChildAt(i)["nameTf"].visible = false;
				}
			}else{
				for(i=0; i<numChildren; i++){
					getChildAt(i)["nameTf"].visible = true;
				}
			}
		}
		
		public function get overItem():ListItem{
			return _overItem;
		}
		
		public function get selectedId():int{
			return _selectedIndex;
		}
		public function set selectedId(id:int):void{
			if(id < 0) return;
			
			for(var i:uint=0; i<numChildren; i++){
				if((getChildAt(i) as ListItem).data == ""+id){
					_selectedIndex = id;
					break;
				}
			}
			selectedItem = getChildAt(_selectedIndex) as ListItem;
		}
		
		public function get selectedItem():ListItem{
			return _selectedItem;
		}
		public function set selectedItem(item:ListItem):void{
			if(isMultiple == false){
				if(_selectedItem != null){
					_selectedItem.bg.gotoAndStop(_selectedItem.bgType);
				}
				_selectedItem = item;
				_selectedItem.bg.gotoAndStop(3);
			}else{
				if(item.bg.currentFrame == 3 || item.bg.currentFrame == 4){
					item.bg.gotoAndStop(item.bgType);
				}else{
					item.bg.gotoAndStop(3);
				}
				_selectedItem = item;
			}
			_selectedIndex = getChildIndex(_selectedItem);
		}
		/** 取消所有的选择 */
		public function cancelAllSelected():void{
			var item:ListItem;
			for(var i:uint=0; i<numChildren; i++){
				item = getChildAt(i) as ListItem;
				item.bg.gotoAndStop(item.bgType);
			}
		}
		
		/** 取消指定的选择<br>
		 * id 要消的ListItem.data */
		public function cancelSelectedById(id:String):void{
			var item:ListItem;
			for(var i:uint=0; i<numChildren; i++){
				item = getChildAt(i) as ListItem;
				if(item.data == id){
					item.bg.gotoAndStop(item.bgType);
					break;
				}
			}
		}
		
		/** 在多选择情况下，返回所选择实例(一个或多个)的data数据 */
		public function getSelectedDataVec():Vector.<String>{
			var vec:Vector.<String> = new Vector.<String>;
			var item:ListItem;
			for(var i:uint=0; i<numChildren; i++){
				item = getChildAt(i) as ListItem;
				if(item.isSelected){
					vec.push(item.data);
				}
			}
			return vec;
		}
		
		public function getLength():int{
			return this.numChildren;
		}
		
		/** 返回一个ID值，可以用此ID来找到唯实例<br>
		 * 注：每调用一次，id值都会加一 */
		public function getId():int{
			return _id = _id > int.MAX_VALUE-1 ? 0 : _id+1;
		}
	}
}
