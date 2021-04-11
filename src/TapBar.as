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
import flash.globalization.CurrencyFormatter;

var curChart:int = 0;
var oldX:Number;
var oldY:Number;
var isSwapDrag:Boolean;
var isMoveDrag:Boolean;
var downItem:MovieClip;
var overItem:MovieClip;
var insert:MovieClip;
var insertIndex:int;
var menuChapter:NativeMenu;
var isDoubleClick:Boolean;
var overTip:MovieClip = new MouseOverTip();
var cw:int = 960;

init();
function init(){
	scrollRect = new Rectangle(0, 0, cw, 30);
	createMenu();
	insert = new TabInsert();
	holder.removeChildren();
    for(var i:int=0; i<Global.chartArr.length; i++){
        addChartAt(Global.chartArr[i]);
    }
	updateItem(false);
	parent["pageBar"].init();
	selectItemByIndex(curChart);
}

function addChartAt(obj, chart:int=-1):MovieClip{
	var item:MovieClip  = new TabItem();
	item.obj = obj;
	item.contextMenu = menuChapter;
	item.gotoAndStop(1);
	item.mouseChildren = false;
	item.hideFlag.visible = !obj.visible;
	item.tf.maxChars = 100;
	item.tf.text = obj.label;
	item.addEventListener(MouseEvent.MOUSE_OVER, overHandler);
	item.addEventListener(MouseEvent.MOUSE_OUT, outHandler);
	item.addEventListener(MouseEvent.MOUSE_DOWN, downHandler);
	obj.inst = item;
	holder.addChild(item);
	if(chart != -1) Global.chartArr.splice(chart, 0, obj);
	return item;
}

function createMenu():void{
	menuChapter = new NativeMenu();
    menuChapter.addItem(new NativeMenuItem("添加小节_前"));
    menuChapter.addItem(new NativeMenuItem("添加小节_后"));
    menuChapter.addItem(new NativeMenuItem("", true));
    menuChapter.addItem(new NativeMenuItem("设置"));
    menuChapter.addItem(new NativeMenuItem("", true));
    menuChapter.addItem(new NativeMenuItem("隐藏"));
    menuChapter.addItem(new NativeMenuItem("", true));
    menuChapter.addItem(new NativeMenuItem("删除"));
	menuChapter.addEventListener(Event.DISPLAYING, menuDisplayHandler);
    menuChapter.addEventListener(Event.SELECT, menuSelectHandler);
}
function menuDisplayHandler(e:Event):void{
	var menu:NativeMenu = e.currentTarget as NativeMenu;
	var n:int = getOverItemIndex();
	menu.getItemAt(5).label = overItem.hideFlag.visible ? "显示" : "隐藏";
	menu.getItemAt(5).enabled = curChart == getOverItemIndex() ? false : Global.chartArr.length > 1;
	menu.getItemAt(7).enabled = Global.chartArr.length > 1;
}
function menuSelectHandler(e:Event):void{
	var menuItem:NativeMenuItem = e.target as NativeMenuItem;
	if(menuItem.label == "添加小节_前"){
		insertChart(true);
	}else if(menuItem.label == "添加小节_后"){
		insertChart(false);
	}else if(menuItem.label == "设置"){
		var panel = new SetChartPanel();
		panel.setData(overItem.tf.text);
		Global.popup(panel, settingBackcall);
	}else if(menuItem.label == "隐藏"){
		hideItem(true);
	}else if(menuItem.label == "显示"){
		hideItem(false);
	}else if(menuItem.label == "删除"){
		Global.alert("确定要删除“"+overItem.tf.text+"”小节吗？", deleteBackcall);
	}
}

function settingBackcall(obj):void{
	overItem.tf.text = obj.label;
	overItem.obj.label = obj.label;
}

function insertChart(isFront:Boolean):void{
	curChart = isFront ? getOverItemIndex() : getOverItemIndex()+1;
	var item:MovieClip = addChartAt(Global.getChartObj(), curChart);
	Global.updateShowChartArr();
	var n:int = getIndexByitem(item, true);
	parent["pageBar"].addPageAt(Global.getPageObj(), n, 0, true);
	updateItem();
	if(isFront){
		if(item.x+holder.x < 0)	holder.x -= holder.x+item.x;
	}else{
		if(item.x > cw-100){
			var px = holder.x-item.width;
			if(px < cw-holder.width) px = cw-holder.width;
			if(getIndexByitem(item) == Global.chartArr.length-1) px = cw-holder.width; 
			holder.x = px;
		}
	}
}

function deleteBackcall(obj):void{
	var chart:int = getOverItemIndex();
	var b:Boolean = chart == curChart;
	Global.chartArr.removeAt(chart);
	holder.removeChild(overItem);
	Global.updateShowChartArr();
	if(curChart > Global.chartArr.length-1) curChart = Global.chartArr.length-1; 
	updateItem();
	if(b){
		var n:int = getIndexByitem(Global.chartArr[curChart].inst, true);
		parent["pageBar"].selectItemByPosition({chart:n, index:0});
	} 
	if(holder.x+holder.width < cw) holder.x = cw-holder.width;
	if(holder.x > 0) holder.x = 0;
}

function hideItem(isHide:Boolean):void{
	var obj:Object = getOverItemIndex();
	if(isHide){
		overItem.obj.visible = false;
		overItem.hideFlag.visible = true;
	}else{
		overItem.obj.visible = true;
		overItem.hideFlag.visible = false;
	}
	Global.updateShowChartArr();
	parent["pageBar"].updateItem();
}

function overHandler(e:MouseEvent):void{
	if(isSwapDrag == true) return;
	var item:MovieClip = e.currentTarget as MovieClip;
	overItem = item;
	if(item.obj.visible && getOverItemIndex() != curChart) item.tf.textColor = 0xFFFFFF;
	if(overItem.tf.textWidth > overItem.tf.width){
		var p:Point = new Point(overItem.x, overItem.y);
		p = holder.localToGlobal(p);
		overTip.setData(overItem.tf.text);
		overTip.x = p.x;
		overTip.y = p.y+30;
		stage.addChild(overTip);
	}
}
function outHandler(e:MouseEvent):void{
	if(isSwapDrag == true) return;
	var item:MovieClip = e.currentTarget as MovieClip;
	item.tf.textColor = 0xAAAAAA;
	if(overTip.stage) stage.removeChild(overTip);
}
function downHandler(e:MouseEvent):void{
	if(overTip.stage) stage.removeChild(overTip);
	if(Global.chartArr.length == 1) return;
	isSwapDrag = false;
	isMoveDrag = false;
	if(isDoubleClick == true){
		isSwapDrag = true;
		holder.addChild(insert);
		overItem.alpha = 0.3;
		swapDraging(e);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, moveHandler);
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
				holder.mouseEnabled = false;
				holder.mouseChildren = false;
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
	}else if(isMoveDrag == true){
		moveEnd(e);
	}else{
		if(Math.abs(e.stageX-oldX) < 8) clickItem(e);
	}
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

function swapDraging(e:MouseEvent):void{
	var p:Point = new Point(e.stageX, e.stageY);
	p = holder.globalToLocal(p);
	var totalItem = holder.numChildren-1;
	insertIndex = int(p.x/160);
	var position = p.x%160;
	if(position > 80) insertIndex++;
	if(insertIndex < 0) insertIndex = 0;
	if(insertIndex > totalItem) insertIndex = totalItem;
	insert.x = 160*insertIndex;
}
function swapDragEnd(e:MouseEvent):void{
	isSwapDrag = false;
	overItem.alpha = 1;
	if(insert.stage) holder.removeChild(insert);
	if(Math.abs(e.stageX-oldX) < 8) return;

	var oldInsertIndex = getOverItemIndex();
	if(insertIndex == oldInsertIndex || insertIndex == oldInsertIndex+1) return;

	var tempItem:MovieClip = Global.chartArr[curChart].inst;
	if(oldInsertIndex < insertIndex) insertIndex--;
	var obj:Object = Global.chartArr.removeAt(oldInsertIndex);
	Global.chartArr.splice(insertIndex, 0, obj);
	Global.updateShowChartArr();

	var chart:int = getOverItemIndex();
	if(Global.chartArr[chart].visible == true){
		curChart = chart;
		updateItem();
	}else{
		updateItem(false);
		for(var i:int=0; i<Global.chartArr.length; i++){
			if(tempItem == Global.chartArr[i].inst){
				curChart = i;
				break;
			} 
		}
	}
}

function clickItem(e:MouseEvent):void{
	if(getOverItemIndex() == curChart) return;
	var obj:Object = Global.chartArr[getOverItemIndex()];
	if(obj.visible == false) return;
	var item:MovieClip;
	for(var i:int=0; i<Global.chartArr.length; i++){
		item = Global.chartArr[i].inst;
		if(item == downItem){
			curChart = i;
			item.gotoAndStop(2);
		}else{
			item.gotoAndStop(1);
		}
	}
	parent["pageBar"].selectChartByIndex(getOverItemIndex(true));
}

function getOverItemIndex(isShow:Boolean=false):int{
	return getIndexByitem(overItem, isShow);
}
function getIndexByitem(item, isShow:Boolean=false):int{
	var arr:Array = isShow ? Global.showChartArr : Global.chartArr;
	for(var i:int=0; i<arr.length; i++){
		if(arr[i].inst == item){
			return i;
		}
	}
	return -1;
}

function selectItemByIndex(chart:int, isShow:Boolean=false, isDraw:Boolean=false):void{
	var item:MovieClip;
	var arr:Array = isShow ? Global.showChartArr : Global.chartArr;
	for(var i:int=0; i<arr.length; i++){
		item = arr[i].inst;
		item.gotoAndStop(1);
	}
	arr[chart].inst.gotoAndStop(2);
	curChart = chart;
	var n:int = getIndexByitem(Global.chartArr[chart].inst, true);
	parent["pageBar"].drawChartBg(isDraw ? chart : n);
}

function selectTip(chart:int=-1, isSelect:Boolean=false){
	var item:MovieClip;
	var arr:Array = Global.showChartArr;
	for(var i:int=0; i<arr.length; i++){
		item = arr[i].inst;
		if(item["tf"]) item["tf"].textColor = 0xAAAAAA;
	}
	item = arr[chart].inst;
	item["tf"].textColor = 0x00AA00;
	if(isSelect){
		item["tf"].textColor = 0xAAAAAA;
		selectItemByIndex(chart, true, true);
	}
}

function updateItem(update:Boolean=true):void{
	holder.removeChildren();
	var item;
	for(var i:int=0; i<Global.chartArr.length; i++){
		item = Global.chartArr[i].inst;
		holder.addChild(item);
		item.x = i*item.width;
		item.trans.visible = true;
	}
	item.trans.visible = false;
	if(holder.width < cw) holder.x = 0;
	if(update){
		selectItemByIndex(curChart);
		var chart:int = getIndexByitem(Global.chartArr[curChart].inst, true);
		parent["pageBar"].updateItem(chart);
		parent["pageBar"].selectChartByIndex(chart);
	} 
}

function updatePageNum():void{
	var t:int = 0;
	var n:int;
	for(var i:int=0; i<Global.chartArr.length; i++){
		n = Global.chartArr[i].pages.length;
		t += n;
		Global.chartArr[i].inst.numTf.text = Global.chartArr[i].pages.length;
	}
	var tf:TextField = parent["pageNumTf"];
	tf.text = ""+t;
	if(holder.width > cw){
		tf.x = this.x+cw+2;
	}else{
		tf.x = this.x+holder.width-5;
	}
}

function resize():void{
	cw = stage.stageWidth-200;
	this.scrollRect = new Rectangle(0, 0, cw, 30);
	if(holder.x+holder.width < cw) holder.x = cw-holder.width;
	if(holder.x > 0) holder.x = 0;
	updatePageNum();
}