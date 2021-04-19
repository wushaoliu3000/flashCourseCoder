package wsl.view.flippage{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	public class FlipButtonBar extends Sprite{
		/** 总共有多少页 */
		private var numTotalPage:int;
		/** 翻页条能显示的页数 */
		private var numDispalyPage:int;
		/** 页的移动方向 */
		private var dir:int;
		/** 当前选择按钮的缩影 */
		private var curBtnIndex:int;
		/** 当前选择的页 */
		private var curPageIndex:int;
		/** 保存每一个实例的x坐标 */
		private var xVec:Vector.<int>;
		/** 当前实例 被缩小 */
		private var curItem:FlipButtonBarItem;
		/** 下一个实例 被放大 */
		private var nextItem:FlipButtonBarItem;
		
		private var initX:Number;
		private var scale:Number;
		private var isSwitch:Boolean;
		
		public function FlipButtonBar(){
			this.mouseEnabled = false;
			this.addEventListener(MouseEvent.CLICK, clickHandler);
		}
		
		public function addItem(totalPage:int):void{
			if(numChildren > 0){
				this.removeChildren(0, numChildren-1);
			}
			
			var item:FlipButtonBarItem;
			var _parent:FlipPageView = parent as FlipPageView;
			var maxPageNum:int = Math.floor((_parent.pageWidth-100)/60);
			numTotalPage = totalPage;
			dir = 0;
			curPageIndex = 0;
			
			numDispalyPage = numTotalPage > maxPageNum ? maxPageNum : numTotalPage;
			
			if(numTotalPage==1){
				item = new FlipButtonBarItem();
				item.setPageIndex(0);
				item.x = 30;
				addChild(item);
			}else if(numTotalPage==2){
				xVec = new Vector.<int>;
				for(var i:uint=0; i<numDispalyPage; i++){
					xVec.push(0);
					item = new FlipButtonBarItem();
					item.setPageIndex(i);
					item.index = i;
					item.x = 20+i*60;
					item.icon.scaleX = 0.5;
					item.icon.scaleY = 0.5;
					addChild(item);
				}
				curItem = getItemByIndex(1);
				nextItem = getItemByIndex(0);
			}else{
				xVec = new Vector.<int>;
				for(i=0; i<=numDispalyPage; i++){
					xVec.push(0);
					item = new FlipButtonBarItem();
					if(i == 0){
						item.setPageIndex(numTotalPage-1);
					}else{
						item.setPageIndex(i-1);
					}
					item.index = i;
					item.x = 20+i*60;
					item.icon.scaleX = 0.5;
					item.icon.scaleY = 0.5;
					addChild(item);
				}
				curItem = getItemByIndex(1);
				nextItem = getItemByIndex(1);
			}
			
			if(numTotalPage < 3){
				this.scrollRect = new Rectangle(-5, -30, numChildren*60+5, 60);
			}else{
				this.scrollRect = new Rectangle(0, -30, ((numChildren-1)*60), 60);
			}
		}
		
		/** 选择第一页 */
		public function selectFirstPage():void{
			var item:FlipButtonBarItem;
			if(numTotalPage <= numDispalyPage){
				selectPageByItem(getItemByPageIndex(0));
			}else{
				/*curPageIndex = 1;
				for(var i:uint=0; i<=numDispalyPage; i++){
					item = getChildAt(i) as FlipButtonBarItem;
					item.setPageIndex(i);
					item.index = i;
					item.x = 20+i*60;
					item.icon.scaleX = 0.5;
					item.icon.scaleY = 0.5;
				}
				curItem = getItemByIndex(numDispalyPage);
				curItem.x = -60;
				dir = 1;
				setXvec();
				curItem.icon.scaleX = curItem.icon.scaleY = 1;
				nextItem = getItemByIndex(0);
				(parent as FlipPageView).switchPage(-1, 0);*/
			}
		}
		
		/** 选择第一页 */
		public function selectLastPage():void{
			if(numTotalPage <= numDispalyPage){
				selectPageByItem(getItemByPageIndex(numTotalPage-1));
			}else{
				
			}
		}
		
		private function clickHandler(e:MouseEvent):void{
			if(numTotalPage == 1) return;
			var item:FlipButtonBarItem = e.target as FlipButtonBarItem;
			if(numTotalPage == 2){
				if(item.index == 0){
					(parent as FlipPageView).prevPage();
				}else{
					(parent as FlipPageView).nextPage();
				}
				return;
			}
			selectPageByItem(item);
		}
		
		private function selectPageByItem(item:FlipButtonBarItem):void{
			var _parent:FlipPageView = parent as FlipPageView;
			
			if(curBtnIndex == item.index) return;
			
			initX = 800;
			curItem = nextItem;
			nextItem = getItemByIndex(item.index);
			isSwitch = true;
			
			if(item.index > curBtnIndex){
				dir = -1;
				_parent.switchPage(-1, item.getPageIndex());
				if(item.index >= numDispalyPage-1){
					setXvec();
				}
			}else if(item.index < curBtnIndex){
				dir = 1;
				_parent.switchPage(1, item.getPageIndex());
				
				if(item.index == 0){
					var tItem:FlipButtonBarItem = getItemByIndex(numDispalyPage);
					if(getItemByIndex(0).getPageIndex() == 0){
						tItem.setPageIndex(numTotalPage-1);
					}else{
						tItem.setPageIndex(getItemByIndex(0).getPageIndex()-1);
					}
					tItem.x = -60;
					setXvec();
				}
			}
			
			curBtnIndex = item.index;
		}
		
		public function setInitValue(n:Number, dir:int):void{
			this.initX = n;
			this.dir = dir;
			this.mouseChildren = false;
			
			//只有两页时
			if(numTotalPage == 2){
				if(curPageIndex == 0){
					curItem = getItemByIndex(0);
					nextItem = getItemByIndex(1);
				}else{
					curItem = getItemByIndex(1);
					nextItem = getItemByIndex(0);
				}
				return;
			}
			
			//大于两页时
			var btn:int;
			if(dir == -1){
				btn = curBtnIndex >= numDispalyPage-2 ? numDispalyPage-2 : curBtnIndex
				curItem = getItemByIndex(btn);
				nextItem = getItemByIndex(btn+1);
				
				if(curBtnIndex < numDispalyPage-2) return;
				setXvec();
			}else{
				btn = curBtnIndex <=1 ? 1 : curBtnIndex;
				curItem = getItemByIndex(btn);
				nextItem = getItemByIndex(btn-1);
				
				if(curBtnIndex > 1) return;
				
				var item:FlipButtonBarItem = getItemByIndex(numDispalyPage);
				if(getItemByIndex(0).getPageIndex() == 0){
					item.setPageIndex(numTotalPage-1);
				}else{
					item.setPageIndex(getItemByIndex(0).getPageIndex()-1);
				}
				item.x = -60;
				setXvec();
			}
		}
		
		public function tween(n:Number):void{
			//缩放
			scale = (initX - n)/initX;
			curItem.icon.scaleX = curItem.icon.scaleY = 1-scale;
			if(curItem.icon.scaleX != 0.5 && curItem.icon.scaleX < 0.5){
				curItem.setScalse(0.5);
			}
			nextItem.setScalse(0.5+(scale/2));
			
			if(numTotalPage == 2) return;
			if(isSwitch == true){
				if(dir == -1 && curBtnIndex < numDispalyPage-1) return;
			}else{
				if(dir == -1 && curBtnIndex < numDispalyPage-2) return;
			}
			if(isSwitch == true){
				if(dir == 1 && curBtnIndex > 0) return;
			}else{
				if(dir == 1 && curBtnIndex > 1) return;
			}
			
			//平移
			if(dir == -1){
				for(var i:uint=0; i<numChildren; i++){
					getChildAt(i).x = xVec[i]-60*scale;
				}
			}else if(dir == 1){
				for(i=0; i<numChildren; i++){
					getChildAt(i).x = xVec[i]+60*scale;
				}
				getItemByIndex(numChildren-1).x = -40+60*scale
			}
		}
		
		public function selectIndex(index:int):void{
			if(numTotalPage == 1) return;
			
			curItem.setScalse(0.5);
			nextItem.setScalse(1);
			curPageIndex = index;
			
			this.mouseChildren = true;
			curItem.mouseEnabled = true;
			curItem.mouseChildren = true;
			nextItem.mouseEnabled = false;
			nextItem.mouseChildren = false;
			
			if(numTotalPage == 2) return;
			
			if(isSwitch == true){
				if(dir == -1 && curBtnIndex >= numDispalyPage-1) left();
			}else{
				if(dir == -1 && curBtnIndex >= numDispalyPage-2) left();
			}
			
			if(isSwitch == true){
				if(dir== 1 && curBtnIndex < 1)	right();
			}else{
				if(dir== 1 && curBtnIndex <= 1)	right();
			}
			
			
			if(dir == -1){
				curBtnIndex = nextItem.index == numDispalyPage-1 ? numDispalyPage-2 : nextItem.index;
			}else{
				curBtnIndex = nextItem.index == 0 ? 1 : nextItem.index;
			}
			
			isSwitch = false;
		}
		
		private function left():void{
			var itemVec:Vector.<FlipButtonBarItem> = new Vector.<FlipButtonBarItem>;
			for(var i:uint=0; i<=numDispalyPage; i++){
				itemVec.push(getItemByIndex(i));
			}
			
			itemVec[0].x = 20+numDispalyPage*60;
			if(itemVec[numDispalyPage].getPageIndex() >= numTotalPage-1){
				itemVec[0].setPageIndex(0);
			}else{
				itemVec[0].setPageIndex(itemVec[numDispalyPage].getPageIndex()+1);
			}
			
			for(i=1; i<=numDispalyPage; i++){
				itemVec[i].index--;
			}
			itemVec[0].index = numDispalyPage;
		}
		
		private function right():void{
			var itemVec:Vector.<FlipButtonBarItem> = new Vector.<FlipButtonBarItem>;
			for(var i:uint=0; i<=numDispalyPage; i++){
				itemVec.push(getItemByIndex(i));
			}
			
			for(i=0; i<numDispalyPage; i++){
				itemVec[i].index++;
			}
			itemVec[numDispalyPage].index = 0;
		}
		
		private function getItemByIndex(index:int):FlipButtonBarItem{
			var item:FlipButtonBarItem;
			for(var i:uint=0; i<=numDispalyPage; i++){
				item = getChildAt(i) as FlipButtonBarItem;
				if(item.index == index){
					break;
				}
			}
			return item;
		}
		
		private function getItemByPageIndex(pageIndex:int):FlipButtonBarItem{
			var item:FlipButtonBarItem;
			for(var i:uint=0; i<=numDispalyPage; i++){
				item = getChildAt(i) as FlipButtonBarItem;
				if(item.getPageIndex() == pageIndex){
					break;
				}
			}
			return item;
		}
		
		private function setXvec():void{
			for(var i:uint=0; i<numChildren; i++){
				xVec[i] = getChildAt(i).x;
			}
		}
		
		public function getDisplayPageNum():int{
			return numDispalyPage;
		}
		
		public function move(px:Number, py:Number):void{
			if(numTotalPage > 2){
				x = int(px)+30;
			}else{
				x = int(px);
			}
			y = int(py)-30;
		}
	}
}