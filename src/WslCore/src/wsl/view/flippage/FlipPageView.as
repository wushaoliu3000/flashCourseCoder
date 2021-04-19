package wsl.view.flippage{
	import com.greensock.TweenLite;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import wsl.interfaces.IPopupView;
	import wsl.utils.Utils;
	
	public class FlipPageView extends Sprite implements IPopupView{
		/** 所有需要加载页的实例加载完成时触发new Event(ALL_LOAD_COMPLETE) */
		static public const ALL_LOAD_COMPLETE:String = "allLoadComplete";
		/** 第一页(在屏幕上可见的页)加载完成时触发 new Event(FIRST_LOAD_COMPLETE)*/
		static public const FIRST_LOAD_COMPLETE:String = "firstLoadComplete";
		
		/**希望的网格宽度 180*/
		public const GRID_W:int = 180;
		/**希望的网格高度 170*/
		public const GRID_H:int = 170;
		/**实际图标宽度 160*/
		public const THUMB_W:int = 160;
		/**实际图标高度 160*/
		public const THUMB_H:int = 160;
		/**翻页条的高度 70*/
		public const FLIP_BUTTON_BAR_H:int = 70;
		
		/**网格宽度*/
		public var gridW:Number;
		/**网格高度*/
		public var gridH:Number;
		/**网格行数*/
		public var gridCountW:int;
		/**网格列数*/
		public var gridCountH:int;
		/**图标到网格的水平间隙*/
		public var spaceW:Number;
		/**图标到网格的垂直间隙*/
		public var spaceH:Number;
		/**页的宽度*/
		public var pageWidth:int;
		/** 页的高度 */
		public var pageHeight:int;
		/** 总的页数 */
		public var numTotalPage:int;
		/** 页过渡是否完成，在页过渡过程中，屏蔽所有操作 */
		public var isTween:Boolean;
		/** 用于判断页是否移动 */
		public var deltaX:Number = 0;
		/** 是否可以多选实例 */
		public var isMultiple:Boolean;
		
		/** 当前显示的页 */
		private var curPage:int;
		/** 需要加载的页 */
		private var loadPage:int;
		/** 需要加载的页,跳转页时用到 */
		private var loadPage1:int;
		
		/** 保存所有页的实例，每次调用setItemVec时都被重新赋值 */
		private var itemVec:Vector.<PageItemVO>;
		
		/** 绘制一个透明背景，现实在页中任何点可以拖动页 */
		private var bg:Sprite;
		/** 翻页按钮条 */
		public var btnBar:FlipButtonBar;
		
		/** 构造时创建页，以后不管如何设置实例类型，页都不会变 */
		private var page0:PageView;
		private var page1:PageView;
		private var page2:PageView;
		
		/** 用于正确的指向页的顺序，不管页如何切换，始终指向左中右的页 */
		private var pVec:Vector.<PageView>;
		
		/** 翻页方向 */
		private var dir:int;
		/** 是否是切换页 */
		private var isSwitch:Boolean;
		
		/** 当实例被点击时执行此类的pageItemClick方法 */
		private var pageItemClickInst:IPageItemClick;
		
		private var oldX:Number;
		private var isDown:Boolean;
		
		/** 分页视图 <br>
		 * pageWidth 页宽<br>
		 * pageHeight 页高<br>
		 * isMultiple 是否可以多选页中的实例*/
		public function FlipPageView(pageWidth:int, pageHeight:int, isMultiple:Boolean){
			this.isMultiple = isMultiple;
			this.scrollRect = new Rectangle(0, -8, pageWidth, pageHeight+5);
			
			this.pageWidth = pageWidth;
			this.pageHeight = pageHeight - FLIP_BUTTON_BAR_H;
			
			setParam();
			createBg();
			createPage();
			this.addEventListener(MouseEvent.MOUSE_DOWN, downHandler);
			this.addEventListener(MouseEvent.MOUSE_MOVE, moveHandler);
			this.addEventListener(MouseEvent.MOUSE_UP, upHandler);
			this.addEventListener(MouseEvent.MOUSE_OUT, upHandler);
		}
		
		public function reSize(pageWidth:int, pageHeight:int):void{
			this.scrollRect = new Rectangle(0, -8, pageWidth, pageHeight+5);
			
			this.pageWidth = pageWidth;
			this.pageHeight = pageHeight - FLIP_BUTTON_BAR_H;
			setParam();
			createBg();
			for(var i:uint=0; i<3; i++){
				pVec[i].init();
			}
			setItemVec(itemVec);
		}
		
		private function setParam():void{
			gridCountW = int(pageWidth/GRID_W);
			gridCountH = int(pageHeight/GRID_H);
			gridW = GRID_W + (pageWidth - gridCountW*GRID_W)/gridCountW;
			gridH = GRID_H + (pageHeight - gridCountH*GRID_H)/gridCountH;
			spaceW = (gridW - THUMB_W)/2;
			spaceH = (gridH - THUMB_H)/2;
		}
		
		private function createBg():void{
			if(bg == null){
				bg = new Sprite();
			}else{
				bg.graphics.clear();
			}
			bg.graphics.beginFill(0x000000, 0);
			bg.graphics.drawRect(0, 0, pageWidth, pageHeight);
			bg.graphics.endFill();
			addChild(bg);
		}
		
		private function createPage():void{
			pVec = new Vector.<PageView>;
			pVec.push(null, null, null);
			
			pVec[2] = new PageView(this, 2);
			pVec[2].addEventListener(PageView.LOAD_COMPLETE, allLoadCompleteHandler);
			pVec[2].addEventListener(PageView.RE_LOAD_COMPLETE, reloadCompleteHandler);
			addChild(pVec[2]);
			
			pVec[0] = new PageView(this, 0);
			pVec[0].addEventListener(PageView.LOAD_COMPLETE, firstLoadHandler);
			pVec[0].addEventListener(PageView.RE_LOAD_COMPLETE, reloadCompleteHandler);
			addChild(pVec[0]);
			
			pVec[1] = new PageView(this, 1);
			pVec[1].addEventListener(PageView.LOAD_COMPLETE, allLoadCompleteHandler);
			pVec[1].addEventListener(PageView.RE_LOAD_COMPLETE, reloadCompleteHandler);
			addChild(pVec[1]);
			
			initPage();
		}
		
		private function initPage():void{
			var tVec:Vector.<PageView> = new Vector.<PageView>;
			for(var i:uint=0; i<3; i++){
				pVec[i].isReload = false;
				pVec[i].clearItems();
				tVec[i] = getPageByIndex(i);
			}
			pVec[0] = tVec[0];
			pVec[1] = tVec[1];
			pVec[2] = tVec[2];
			pVec[2].x = -pageWidth;
			pVec[0].x = 0;
			pVec[1].x = pageWidth;
		}
		
		private function getPageByIndex(index:int):PageView{
			var page:PageView;
			for(var i:uint=0; i<pVec.length; i++){
				if(pVec[i].index == index){
					page = pVec[i];
					break;
				}
			}
			return page;
		}
		
		/** 根据提供的Vector.<PageItemVO>来创建页实例并创建按钮条，<br>
		 * 此方法将删除原来的数据，用新的数据来创建页。<br>
		 * 注：如果vec.length=0则隐藏本身 */
		public function setItemVec(vec:Vector.<PageItemVO>):void{
			if(vec == itemVec && vec.length == itemVec.length) return;
			if(itemVec && vec.length == itemVec.length){
				for(var i:uint=0; i<vec.length; i++){
					if(vec[i].label != itemVec[i].label){
						break;
					}
				}
				if(i == vec.length){
					return;
				}
			}
			setItems(vec);
		}

		private function setItems(vec:Vector.<PageItemVO>):void{
			if(itemVec != null){
				for(var i:uint=0; i<itemVec.length; i++){
					itemVec[i].isSelected = false;
				}
			}
			
			for(i=0; i<3; i++){
				pVec[i].clearSelectItem();
			}
			
			itemVec = vec;
			curPage = 0;
			numTotalPage = Math.ceil(itemVec.length/(gridCountW*gridCountH));
			initPage();
			pVec[0].addItems(getPageVecAt(curPage));
			
			createButtonBar();
			
			this.visible = itemVec.length == 0 ? false : true;
		}
		
		/** 设置一个实现了IPageItemClick接口的类, 在页实例被点击时调用此接口的方法。<br>
		 * 此方法实现了同一个此类的实例可用于不同的用途，如：同一个实例即可用作游戏选择、也可用作图片选择…… */
		public function setPageItemClick(inst:IPageItemClick):void{
			pageItemClickInst = inst;
		}
		
		private function firstLoadHandler(e:Event):void{
			if(isMultiple == false){
				pVec[0].selectItemAt(0);
			}
			dispatchEvent(new Event(FIRST_LOAD_COMPLETE));
			if(numTotalPage == 1){
				dispatchEvent(new Event(ALL_LOAD_COMPLETE));
			}else if(numTotalPage == 2){
				pVec[1].addItems(getPageVecAt(curPage+1));
			}else{
				pVec[2].addItems(getPageVecAt(numTotalPage-1));
				pVec[1].addItems(getPageVecAt(curPage+1));
			}
		}
		
		private function allLoadCompleteHandler(e:Event):void{
			if(numTotalPage == 2 && pVec[1].isLoadComplete){
				dispatchEvent(new Event(ALL_LOAD_COMPLETE));
			}else if(pVec[1].isLoadComplete && pVec[2].isLoadComplete){
				dispatchEvent(new Event(ALL_LOAD_COMPLETE));
			}
		}
		
		private function getPageVecAt(numPage:int):Vector.<PageItemVO>{
			var numPageItem:int = gridCountW*gridCountH;
			var vec:Vector.<PageItemVO> = new Vector.<PageItemVO>;
			for(var i:uint=0; i<numPageItem; i++){
				if(numPage*numPageItem+i >= itemVec.length){
					break;
				}
				vec[i] = itemVec[numPage*numPageItem+i];
			}
			return vec;
		}
		
		private function createButtonBar():void{
			if(btnBar == null){
				btnBar = new FlipButtonBar();
				//btnBar.filters = [Utils.getDropShadowFilter(2, 2, 0.3, 2)];
				addChild(btnBar);
			}
			
			btnBar.addItem(numTotalPage);
			if(gridH-THUMB_H > 30){
				btnBar.move((pageWidth - btnBar.getDisplayPageNum()*60)/2, pageHeight + 35);
			}else{
				btnBar.move((pageWidth - btnBar.getDisplayPageNum()*60)/2, pageHeight + 15);
			}
			btnBar.selectIndex(curPage);
		}
		
		private function downHandler(e:MouseEvent):void{
			if(numTotalPage == 1) return;
			if(mouseY > pageHeight) return;
			if(isTween == true) return;
			
			oldX = this.mouseX;
			deltaX = 0;
			isDown = true;
		}
		
		private function moveHandler(e:MouseEvent):void{
			if(numTotalPage == 1) return;
			if(mouseY > pageHeight) return;
			if(isDown == false) return;
			if(isTween == true) return;
			
			deltaX = mouseX - oldX;
			if(Math.abs(deltaX)<16) return;
			
			pVec[0].x = deltaX;
			if(numTotalPage == 2){
				if(deltaX <= 0){
					pVec[1].x = pVec[0].x+pageWidth;
				}else{
					pVec[1].x = pVec[0].x-pageWidth;
				}
			}else{
				pVec[2].x = pVec[0].x-pageWidth;
				pVec[1].x = pVec[0].x+pageWidth;
			}
			
			e.updateAfterEvent();
		}
		
		private function upHandler(e:MouseEvent):void{
			if(numTotalPage == 1) return;
			if(mouseY > pageHeight) return;
			if(isDown == false) return;
			if(isTween == true) return;
			
			isDown = false;
			if(Math.abs(deltaX)<16)	return;
			
			deltaX > 0 ? prevPage() : nextPage();
		}
		
		/** 下一页 */
		public function nextPage():void{
			if(numTotalPage == 1) return;
			
			dir = -1;
			curPage++;
			if(curPage == numTotalPage){
				curPage = 0;
				loadPage = 1;
			}else if(curPage == numTotalPage-1){
				loadPage = 0;
			}else{
				loadPage = curPage+1;
			}
			
			btnBar.setInitValue(Math.abs(pVec[0].x+(dir*pageWidth)), dir);
			startTween();
		}
		
		/** 上一页 */
		public function prevPage():void{
			if(numTotalPage == 1) return;
			
			dir = 1;
			curPage--;
			if(curPage == -1){
				curPage = numTotalPage-1;
				loadPage = numTotalPage-2;
			}else if(curPage == 0){
				loadPage = numTotalPage-1;
			}else{
				loadPage = curPage-1;
			}
			btnBar.setInitValue(Math.abs(pVec[0].x+(dir*pageWidth)), dir);
			startTween();
		}
		
		/** 跳到第一页 */
		public function firstPage():void{
			if(numTotalPage == 1 || curPage == 0) return;
			if(numTotalPage == 2){
				prevPage();
				return;
			}
			
			btnBar.selectFirstPage();
		}
		
		/** 跳到最后一页 */
		public function lastPage():void{
			if(numTotalPage == 1  || curPage == numTotalPage-1) return;
			if(numTotalPage == 2){
				nextPage();
				return;
			}
			btnBar.selectLastPage();
		}
		
		/** 当FlipButtonBar的按钮点击、跳到第一页或最后一页时调用 */
		public function switchPage(dir:int, page:int):void{
			this.dir = dir;
			this.curPage = page;
			this.isSwitch = true;
			pVec[0].isLoadComplete = false;
			
			if(dir == -1){
				loadPage = page+1;
				loadPage = loadPage > numTotalPage-1 ?  0 :  loadPage;
				loadPage1 = page-1;
				loadPage1 = loadPage1 < 0 ?  numTotalPage-1 : loadPage1;
				//实例加载完后调用reloadCompleteHandler
				pVec[1].addItems(getPageVecAt(page));
			}else{
				loadPage = page-1;
				loadPage = loadPage < 0 ?  numTotalPage-1 : loadPage;
				loadPage1 = page+1;
				loadPage1 = loadPage1 > numTotalPage-1 ?  0 :  loadPage1;
				//实例加载完后调用reloadCompleteHandler
				pVec[2].addItems(getPageVecAt(page));
			}
		}
		
		private function startTween():void{
			setIsTween(true);
			var t:Number = (pageWidth-Math.abs(pVec[0].x))/1000;
			TweenLite.to(pVec[0], t, {x:dir*pageWidth,  onUpdate:onUpdateFun, onComplete:onFinishTween});
			
			//清出已经选择的实例
			for(var i:uint=0; i<3; i++){
				pVec[i].curIndex = 0;
				pVec[i].clearSelectItem();
			}
		}
		
		private function onUpdateFun():void{
			if(numTotalPage == 2){
				pVec[1].x = pVec[0].x-dir*pageWidth;
			}else{
				if(dir == 1){
					pVec[2].x = pVec[0].x-pageWidth;
				}else{
					pVec[1].x = pVec[0].x+pageWidth;
				}
			}
			
			btnBar.tween(Math.abs(pVec[0].x-dir*pageWidth));
		}
		
		private function onFinishTween():void{
			if(numTotalPage == 2){
				page0 = pVec[1];
				page1 = pVec[0];
				pVec[0] = page0;
				pVec[1] = page1;
				setIsTween(false);
			}else{
				if(dir == 1){
					pVec[1].x = -pageWidth;
					page0 = pVec[1];
					page1 = pVec[2];
					page2 = pVec[0];
				}else{
					pVec[2].x = pageWidth;
					page0 = pVec[0];
					page1 = pVec[1];
					page2 = pVec[2];
				}
				
				if(numTotalPage == 3){
					setIsTween(false);
				}else{
					if(dir == 1){
						pVec[1].addItems(getPageVecAt(loadPage));
					}else{
						pVec[2].addItems(getPageVecAt(loadPage));
					}
					if(isSwitch == true){
						pVec[0].addItems(getPageVecAt(loadPage1));
					}
				}
				
				pVec[2] = page0;
				pVec[0] = page1;
				pVec[1] = page2;
			}
			
			//每次切换页时，选择实例
			if(isMultiple == false){
				if(dir == -1){
					pVec[0].selectItemAt(0);
				}else{
					pVec[0].selectItemAt(pVec[0].numItem-1);
				}
			}else{
				
				pVec[0].reSelect();
				pVec[1].reSelect();
				if(numTotalPage > 2){
					pVec[2].reSelect();
				}
			}
			//选择按钮条对应的实例
			btnBar.selectIndex(curPage);
			
			deltaX = 0;
		}
		
		private function reloadCompleteHandler(e:Event):void{
			if(pVec[0].isLoadComplete && pVec[1].isLoadComplete && pVec[2].isLoadComplete){
				setIsTween(false);
				isSwitch = false;
			}
			if(isSwitch == true && isTween==false){
				startTween();
			}
		}
		
		private function setIsTween(b:Boolean):void{
			isTween = b;
			this.mouseEnabled = !b;
			this.mouseChildren = !b;
		}
		
		public function itemClickHandler(itemIndex:int, itemVec:Vector.<PageItemVO>):void{
			if(Math.abs(deltaX) < 16){
				pageItemClickInst.pageItemClick(itemIndex, itemVec);
			}
		}
		
		/** 在多选情况下，取得当前选择的PageItemVO */
		public function getSelectedVec():Vector.<PageItemVO>{
			var vec:Vector.<PageItemVO> = new Vector.<PageItemVO>;
			for(var i:uint=0; i<itemVec.length; i++){
				if(itemVec[i].isSelected == true){
					vec.push(itemVec[i]);
				}
			}
			return vec;
		}
		
		/** 在多选情况下，删除所选的实例，并刷新 */
		public function removeSelectedItem():void{
			var vec:Vector.<PageItemVO> = getSelectedVec();
			for(var i:uint=0; i<vec.length; i++){
				removeItemVO(vec[i].id);
			}
			setItems(itemVec);
		}
		
		/** 通过实例id删除一个或多个 */
		public function removeItemsById(idVec:Vector.<int>):void{
			for(var i:uint=0; i<idVec.length; i++){
				removeItemVO(idVec[i]);
			}
			setItems(itemVec);
		}
		
		private function removeItemVO(id:int):void{
			for(var i:uint=0; i<itemVec.length; i++){
				if(itemVec[i].id == id){
					itemVec.splice(i, 1);
					break;
				}
			}
		}
		
		/** 通过id取得itemVec中的PageItemVO */
		public function getPageItemVoById(id:int):PageItemVO{
			var vo:PageItemVO;
			for(var i:uint=0; i<itemVec.length; i++){
				if(itemVec[i].id == id){
					vo = itemVec[i];
					break;
				}
			}
			return vo;
		}
		
		public function getItemVec():Vector.<PageItemVO>{
			return itemVec;
		}
		
		/** 当按下键盘时在BabyLearn中调用,所有模块的键盘事件都由BabyLearn转发 */
		public function keyDownHandler(keyCode:int):void{
		}
		
		public function keyUpHandler(keyCode:int):void{
			if(isTween) return;
			pVec[0].keyUpHandler(keyCode);
		}
		
		public function clear():void{
		}
	}
}