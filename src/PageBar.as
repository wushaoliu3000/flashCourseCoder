import flash.events.MouseEvent;
import flash.display.MovieClip;
import flash.geom.Point;
import flash.display.NativeMenu;
import flash.display.NativeMenuItem;
import flash.events.Event;
import flash.utils.setTimeout;
import flash.geom.Rectangle;
import flash.text.TextFieldType;
import flash.text.TextField;
import flash.display.Stage;
import flash.display.Sprite;

var oldX:Number;
var oldY:Number;
var isSwapDrag:Boolean;
var isMoveDrag:Boolean;
var downItem:MovieClip;
var overItem:MovieClip;
var insert:MovieClip;
var insertIndex:int;
var isFront:Boolean;
var menuChapter:NativeMenu;
var isDoubleClick:Boolean;
var chartBg:Sprite;
var curChart:int=0;
var curPage:int = 0;
var cw:int = 960;

function init(){
	this.scrollRect = new Rectangle(0, 0, cw, 110);
	menuChapter = new NativeMenu();
    menuChapter.addItem(new NativeMenuItem("添加页_前"));
    menuChapter.addItem(new NativeMenuItem("添加页_后"));
    menuChapter.addItem(new NativeMenuItem("", true));
    menuChapter.addItem(new NativeMenuItem("设置"));
    menuChapter.addItem(new NativeMenuItem("", true));
    menuChapter.addItem(new NativeMenuItem("删除"));
	menuChapter.addEventListener(Event.DISPLAYING, menuDisplayHandler);
    menuChapter.addEventListener(Event.SELECT, menuSelectHandler);
	
	insert = new PageInsert();
	insert.y = 5;
	holder.removeChildren();
	chartBg = new Sprite();
	chartBg.y = 3;
	chartBg.graphics.beginFill(0xFFCC00, 0.5);
	chartBg.graphics.drawRect(0, 0, 200, 104);
	chartBg.graphics.endFill();
	holder.addChild(chartBg);
	var charts:Array = Global.showChartArr;
	var pages:Array;
    for(var i:int=0; i<charts.length; i++){
		pages = charts[i].pages;
		for(var j:int=0; j<pages.length; j++){
			addPageAt(pages[j], i, j);
		}
    }
	updateItem();
	selectItemByPosition({chart:0, index:0});
}

function addPageAt(pageObj:Object, chartIndex:int=-1, pageIndex:int=-1, isInsert:Boolean=false):MovieClip{
	var item:MovieClip  = new PageItem();
	item.y = 5;
	item.obj = pageObj;
	item.contextMenu = menuChapter;
	item.gotoAndStop(1);
	item.mouseChildren = false;
	item.tf.text = (chartIndex+1)+"_"+ (isInsert ? Global.showChartArr[chartIndex].pages.length : pageIndex);
	item.addEventListener(MouseEvent.MOUSE_OVER, overHandler);
	item.addEventListener(MouseEvent.MOUSE_OUT, outHandler);
	item.addEventListener(MouseEvent.MOUSE_DOWN, downHandler);
	pageObj.inst = item;
	pageObj.label += " "+chartIndex+"_"+pageIndex;
	holder.addChild(item);
	if(isInsert) Global.showChartArr[chartIndex].pages.splice(pageIndex, 0, pageObj);
	return item;
}

function menuDisplayHandler(e:Event):void{
	var menu:NativeMenu = e.currentTarget as NativeMenu;
	var obj:Object = getOverItemPosition();
	menu.getItemAt(5).enabled = Global.showChartArr[obj.chart].pages.length > 1;
}
function menuSelectHandler(e:Event):void{
	var menuItem:NativeMenuItem = e.target as NativeMenuItem;
	var item:MovieClip;
	var obj:Object;
	if(menuItem.label == "添加页_前"){
		insertPage(true);
	}else if(menuItem.label == "添加页_后"){
		insertPage(false);
	}else if(menuItem.label == "设置"){
		var panel = new SetPagePanel();
		panel.setData(overItem.tf.text);
		Global.popup(panel, settingBackcall);
	}else if(menuItem.label == "删除"){
		obj = getOverItemPosition();
		var chartName:String = Global.showChartArr[obj.chart].label;
		var pageName:String = Global.showChartArr[obj.chart].pages[obj.index].label;
		Global.alert("确定要删除“"+chartName+" → "+pageName+"”页吗？", deleteBackcall);
	}
}

function insertPage(isFront:Boolean){
	var obj:Object = getOverItemPosition();
	var page:int = isFront ? obj.index : obj.index+1;
	var item:MovieClip = addPageAt(Global.getPageObj(), obj.chart, page, true);
	updateItem();
	if(isFront){
		if(item.x+holder.x < 0) holder.x -= holder.x+item.x;
	}else{
		if(item.x > cw-100){
			var px = holder.x-item.width;
			if(px < cw-holder.width) px = cw-holder.width;
			if(getIndexByItem(item) == Global.showChartArr.length-1) px = cw-holder.width; 
			holder.x = px;
		}
	}
	selectChartByIndex(obj.chart, page);
	parent["tabBar"].selectItemByIndex(obj.chart, true);
}

function settingBackcall(obj):void{
}

function deleteBackcall(obj):void{
	var obj:Object = getOverItemPosition();
	var b:Boolean = obj.index == curPage;
	Global.showChartArr[obj.chart].pages.removeAt(obj.index);
	holder.removeChild(overItem);
	updateItem();
	if(curChart == obj.chart){
		var len:int = Global.showChartArr[obj.chart].pages.length-1;
		if(len == 0){
			selectChartByIndex(obj.chart, 0);
		}else if(b){
			if(obj.index > len) obj.index = len;
			selectChartByIndex(obj.chart, obj.index);
		}
	}
	
	if(holder.x+holder.width < cw) holder.x = cw-holder.width;
	if(holder.x > 0) holder.x = 0;
}

function overHandler(e:MouseEvent):void{
	if(isSwapDrag == true) return;
	var item:MovieClip = e.currentTarget as MovieClip;
	overItem = item;
}
function outHandler(e:MouseEvent):void{
	if(isSwapDrag == true) return;
}
function downHandler(e:MouseEvent):void{
	if(holder.numChildren == 1) return;
	isSwapDrag = false;
	isMoveDrag = false;
	if(isDoubleClick == true){
		var obj:Object = getPositionByItem(downItem);
		if(Global.showChartArr[obj.chart].pages.length > 1){
			isSwapDrag = true;
			swapDragStart(e);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, moveHandler);
		}
	}else{
		isDoubleClick = true;
		setTimeout(function(){ isDoubleClick = false; }, 200);
		if(holder.width > cw) stage.addEventListener(MouseEvent.MOUSE_MOVE, moveHandler);
	}
	stage.addEventListener(MouseEvent.MOUSE_UP, upHandler);
	downItem = e.currentTarget as MovieClip;
	oldX = e.stageX;
	oldY = e.stageY;
}
function moveHandler(e:MouseEvent):void{
	if(isSwapDrag == true){
		swapDraging(e);
	}else{
		if(isMoveDrag == true || Math.abs(e.stageX-oldX) > 8){
			if(isMoveDrag == false){
				isMoveDrag = true;
				moveStart(e);
			}
			moveDraging(e);
		}
	}
}
function upHandler(e:MouseEvent):void{
	stage.removeEventListener(MouseEvent.MOUSE_MOVE, moveHandler);
	stage.removeEventListener(MouseEvent.MOUSE_UP, upHandler);
	if(isSwapDrag == true){
		swapDragEnd(e);
		isSwapDrag = false;
	}else if(isMoveDrag == true){
		moveEnd(e);
		isMoveDrag = false;
	}else if(Math.abs(e.stageX-oldX) < 8){
		clickItem(e);
	}
}

function moveStart(e:MouseEvent):void{
	holder.mouseEnabled = false;
	holder.mouseChildren = false;
}
function moveDraging(e:MouseEvent):void{
	holder.x += e.stageX - oldX;
	oldX = e.stageX;
	if(holder.x > 0) holder.x = 0;
	if(holder.x < cw-holder.width) holder.x = cw-holder.width;
}
function moveEnd(e:MouseEvent):void{
	holder.mouseEnabled = true;
	holder.mouseChildren = true;
}

function swapDragStart(e:MouseEvent):void{
	holder.mouseEnabled = false;
	holder.mouseChildren = false;
	holder.addChild(insert);
	overItem.alpha = 0.3;
	swapDraging(e);
}
function swapDraging(e:MouseEvent):void{
	var p:Point = new Point(e.stageX, e.stageY);
	p = holder.globalToLocal(p);
	if(p.x < 0 || p.x > holder.width-10 || mouseX < 0 || mouseX > cw) return;
	var totalItem = holder.numChildren-3;
	insertIndex = int(p.x/183);
	
	var position = p.x%183;
	if(insertIndex < 0) insertIndex = 0;
	if(insertIndex > totalItem) insertIndex = totalItem;
	isFront = position < 90;
	insert.x = isFront ? 183*insertIndex : 183*(insertIndex+1)-10;

	var obj:Object = getPositionByIndex(insertIndex);
	parent["tabBar"].selectTip(obj.chart);
}
function swapDragEnd(e:MouseEvent):void{
	holder.mouseEnabled = true;
	holder.mouseChildren = true;
	overItem.alpha = 1;
	if(insert.stage) holder.removeChild(insert);
	if(Math.abs(e.stageX-oldX) < 8) return;

	var oldIndex = getIndexByItem(overItem);
	if(insertIndex == oldIndex) return;

	var oldObj:Object = getOverItemPosition();
	var insertObj:Object = getPositionByIndex(insertIndex);
	var item:Object = Global.showChartArr[oldObj.chart].pages.removeAt(oldObj.index);
	if(isFront == false) insertObj.index++;
	if(oldObj.chart == insertObj.chart){
		if(oldIndex < insertIndex) insertObj.index--;
		Global.showChartArr[oldObj.chart].pages.splice(insertObj.index, 0, item);
	}else{
		Global.showChartArr[insertObj.chart].pages.splice(insertObj.index, 0, item);
	}
	updateItem();

	var obj:Object = getPositionByIndex(insertIndex);
	parent["tabBar"].selectTip(obj.chart, true);
}

function clickItem(e:MouseEvent):void{
	var obj:Object = getPositionByItem(downItem);
	if(obj.chart == curChart && obj.index == curPage) return;
	selectItemByPosition(obj);
	parent["tabBar"].selectItemByIndex(obj.chart, true, true);
	parent["html"].loadPage(downItem.obj.uri);
}


function selectChartByIndex(chartIndex:int, pageIndex:int=0):void{
	drawChartBg(chartIndex);
	if(holder.width < cw){
		holder.x = 0;
	}else{
		if(holder.x + chartBg.x < 0){
			holder.x = -chartBg.x;
		}else if(holder.x+chartBg.x+chartBg.width > cw){
			holder.x = cw-chartBg.x-chartBg.width;
		}

		if(holder.x > 0) holder.x = 0;
		if(holder.x < cw-holder.width) holder.x = cw-holder.width;
	}
	selectItemByPosition({chart:chartIndex, index:pageIndex});
}

function selectItemByPosition(obj:Object):void{
	var item:MovieClip;
	for(var i:int=1; i<holder.numChildren; i++){
		item = holder.getChildAt(i) as MovieClip;
		item.gotoAndStop(1);
	}
	Global.showChartArr[obj.chart].pages[obj.index].inst.gotoAndStop(2);
	curChart = obj.chart;
	curPage = obj.index;
}

function getPositionByIndex(index:int):Object{
	var arr:Array = Global.showChartArr;
	var pages:Array;
	var n:int = 0;
    for(var i:int=0; i<arr.length; i++){
		pages = arr[i].pages;
		for(var j:int=0; j<pages.length; j++){
			if(index == n) return {chart:i, index:j};
			n++;
		}
    }
	return null;
}

function getOverItemPosition():Object{
	return getPositionByItem(overItem);
}
function getPositionByItem(inst:MovieClip):Object{
	var arr:Array = Global.showChartArr;
	var pages:Array;
    for(var i:int=0; i<arr.length; i++){
		pages = arr[i].pages;
		for(var j:int=0; j<pages.length; j++){
			if(pages[j].inst == inst) return {chart:i, index:j};
		}
    }
	return null;
}

function getIndexByItem(inst:MovieClip):int{
	var arr:Array = Global.showChartArr;
	var pages:Array;
	var n:int = 0;
    for(var i:int=0; i<arr.length; i++){
		pages = arr[i].pages;
		for(var j:int=0; j<pages.length; j++){
			if(pages[j].inst == inst) return n;
			n++;
		}
    }
	return -1;
}

function drawChartBg(chartIndex:int):void{
	var n:int = 0;
	var arr:Array = Global.showChartArr;
	for(var i:int=0; i<chartIndex; i++){
		if(arr[i].visible == true){
			n += arr[i].pages.length;
		} 
	}
	chartBg.x = n*183-2;
	chartBg.width =arr[chartIndex].pages.length*183-1;
}

function updateItem(chart:int=-1):void{
	var item;
	var arr:Array = Global.showChartArr;
	var pages:Array;
	var n:int = 0;
	holder.removeChildren();
	holder.addChild(chartBg);
    for(var i:int=0; i<arr.length; i++){
		pages = arr[i].pages;
		if(arr[i].visible == false) continue;
		for(var j:int=0; j<pages.length; j++){
			item = pages[j].inst;
			if(!item) item = addPageAt(pages[j], i, j);
			holder.addChild(item);
			item.x = n*183;
			n++;
		}
    }
	if(holder.width < cw){
		holder.x = 0;
	}else if(holder.x+holder.width < cw){
		holder.x = cw-holder.width;
	} 
	if(chart != -1) curChart = chart;
	drawChartBg(curChart);
	
	parent["tabBar"].updatePageNum();
}

function resize():void{
	cw = stage.stageWidth;
	this.scrollRect = new Rectangle(0, 0, cw, 110);
	if(holder.x+holder.width < cw) holder.x = cw-holder.width;
	if(holder.x > 0) holder.x = 0;
}