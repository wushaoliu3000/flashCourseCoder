package wsl.view.flippage{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.system.Capabilities;
	
	import wsl.interfaces.IKey;
	import wsl.utils.Utils;
	import wsl.view.Key;
	
	public class PageView extends Sprite implements IKey{
		/** 所有实例加载完成时触发new Event(LOAD_COMPLETE) */
		static public const LOAD_COMPLETE:String = "loadComplete";
		/** 重新加载实例完成时触发new Event(LOAD_COMPLETE) */
		static public const RE_LOAD_COMPLETE:String = "reloadComplete";
		/** 所有实例是否加载完成 */
		public var isLoadComplete:Boolean;
		/** 实例数 */
		public var numItem:int;
		/** 是否重新加载 应用刚打开或选择分类时设置为false */
		public var isReload:Boolean;
		
		/** 当前选择的缩影 */
		public var curIndex:int;
		/** 当前选择的实例 */
		public var curItem:PageItem;
		/** 实例行数 */
		private var numX:int;
		
		private var _parent:FlipPageView;
		
		private var _index:int;
		private var loadNum:int;
		
		public function PageView(_parent:FlipPageView, index:int){
			this._parent = _parent;
			_index = index;
			init();
		}
		
		public function init():void{
			this.removeAllItem();
			
			var item:PageItem;
			var cnt:int = 0;
			curIndex = 0;
			numX = _parent.gridCountW;
			var p:int;
			for(var i:uint=0; i<_parent.gridCountH; i++){
				for(var j:uint=0; j<_parent.gridCountW; j++){
					item = new PageItem();
					p = Capabilities.os.indexOf("Windows") == -1 ? 3 : 0;
					item.titleTf.y = _parent.gridH-_parent.THUMB_H > 30 ? (142+p) : (112+p);
					item.x = int(j*_parent.gridW + _parent.spaceW);
					item.y = int(i*_parent.gridH + _parent.spaceH);
					item.filters = null;
					item.visible = false;
					item.mouseChildren = false;
					item.addEventListener(Event.COMPLETE, loadCompleteHandler);
					item.addEventListener(MouseEvent.CLICK, itemHandler);
					addChild(item);
					cnt++;
				}
			}
		}
		
		private function itemHandler(e:MouseEvent):void{
			if(Math.abs(_parent.deltaX) < 16){
				var index:int = getChildIndex((e.currentTarget as PageItem));
				selectItemAt(index);
				if(_parent.isMultiple == false){
					enterItem();
				}
			}
		}
		
		private function enterItem():void{
			var item:PageItem = getChildAt(curIndex) as PageItem;
			_parent.itemClickHandler(item.id, null);
		}
		
		/** 提供一个页实例数组来实例化每一个实例显示什么内容，此方法不会重新构造一个实例，事实上，页实例只在构造方法中创建一次。 */
		public function addItems(vec:Vector.<PageItemVO>):void{
			var item:PageItem;
			var cnt:int = 0;
			var ran:int;
			curIndex = 0;
			loadNum = 0;
			isLoadComplete = false;
			numItem = vec.length;
			
			if(parent == null){
				return;
			}
			
			for(var i:uint=0; i<_parent.gridCountH; i++){
				for(var j:uint=0; j<_parent.gridCountW; j++){
					item = this.getChildAt(cnt) as PageItem;
					if(cnt >= numItem){
						item.clearData();
					}else{
						item.addData(vec[cnt]);
					}
					cnt++;
				}
			}
		}
		
		private function loadCompleteHandler(e:Event):void{
			loadNum++;
			if(loadNum >= numItem){
				isLoadComplete = true;
				if(isReload){
					this.dispatchEvent(new Event(RE_LOAD_COMPLETE));
				}else{
					isReload = true;
					this.dispatchEvent(new Event(LOAD_COMPLETE));
				}
			}
		}
		
		public function clearItems():void{
			var item:PageItem;
			for(var i:uint=0; i<numChildren; i++){
				item = this.getChildAt(i) as PageItem;
				item.loader.unload();
				item.titleTf.text = "";
			}
		}
		
		public function removeAllItem():void{
			var item:PageItem;
			//除出已有实例
			while(numChildren > 0){
				item = this.getChildAt(0) as PageItem;
				item.removeEventListener(Event.COMPLETE, loadCompleteHandler);
				item.removeEventListener(MouseEvent.CLICK, itemHandler);
				item.loader.unload();
				item.titleTf.text = "";
				removeChild(item);
			}
		}
		
		/** 页缩影，构造方法中设置，以后不能在改变 */
		public function get index():int{
			return _index;
		}
		
		/** 选择指定的实例 */
		public function selectItemAt(index:int):void{
			if(_parent.isMultiple == true){
				curIndex = index;
				curItem = getChildAt(index) as PageItem;
				var vo:PageItemVO = _parent.getPageItemVoById(curItem.id);
				if(vo.isSelected){
					vo.isSelected = false;
					curItem.filters = null;
				}else{
					vo.isSelected = true;
					curItem.filters = [Utils.getGlowFilter(1, 10, 3, 0xFFFF00)];
				}
			}else{
				if(curItem){
					curItem.filters = null;
				}
				curIndex = index;
				curItem = getChildAt(index) as PageItem;
				curItem.filters = [Utils.getGlowFilter(1, 10, 3, 0xFFFF00)];
			}
		}
		
		/** 在实例可多选的情况下，每次翻页时重新选择PageItemVO.isSelected=true的实例  */
		public function reSelect():void{
			for(var i:uint=0; i<numItem; i++){
				var item:PageItem = getChildAt(i) as PageItem;
				var vo:PageItemVO = _parent.getPageItemVoById(item.id);
				if(vo.isSelected == false){
					item.filters = null;
				}else{
					item.filters = [Utils.getGlowFilter(1, 10, 3, 0xFFFF00)];
				}
			}
		}
		
		/** 清除选择 */
		public function clearSelectItem():void{
			for(var i:uint=0; i<numChildren; i++){
				getChildAt(i).filters = null;
			}
			curItem = null;
		}
		
		/** 当按下键盘时在BabyLearn中调用,所有模块的键盘事件都由BabyLearn转发 */
		public function keyDownHandler(keyCode:int):void{
		}
		
		public function keyUpHandler(keyCode:int):void{
			if(keyCode == Key.ENTER){
				enterItem();
				return;
			}
			
			if(keyCode == Key.LEFT){
				if(Key.isSpace){
					_parent.prevPage();
					return;
				}
				
				if(curIndex == 0){
					if(_parent.numTotalPage == 1){
						curIndex = numItem-1;
					}else{
						_parent.prevPage();
						return;
					}
				}else{
					curIndex--;
				}
			}else if(keyCode == Key.UP){
				if(Key.isSpace){
					_parent.firstPage();
					return;
				}
				
				if(this.numItem <= _parent.gridCountW) return;
				
				if(curIndex-numX < 0){
					curIndex = (Math.ceil((numItem-1)/numX)-1)*numX + curIndex%numX;
					if(curIndex > numItem-1){
						curIndex = (Math.floor((numItem-1)/numX)-1)*numX + curIndex%numX;
					}
				}else{
					curIndex = curIndex-numX;
				}
			}else if(keyCode == Key.RIGHT){
				if(Key.isSpace){
					_parent.nextPage();
					return;
				}
				
				if(this.numItem <= _parent.gridCountW) return;
				
				if(curIndex == numItem - 1){
					if(_parent.numTotalPage == 1){
						curIndex = 0;
					}else{
				 		_parent.nextPage();
						return;
					}
				}else{
					curIndex++;
				}
				
			}else if(keyCode == Key.DOWN){
				if(Key.isSpace){
					_parent.lastPage();
					return;
				}
				
				curIndex = curIndex+numX > numItem-1 ? curIndex%numX : curIndex+numX;
			}
			
			selectItemAt(curIndex);
		}
	}
}