import flash.html.HTMLLoader;
import flash.net.URLRequest;
import flash.events.Event;
import flash.media.Sound;
import flash.events.MouseEvent;
import flash.utils.setTimeout;
import flash.events.DataEvent;
import flash.filesystem.File;
import flash.media.SoundMixer;
import flash.display.Bitmap;
import flash.display.BitmapData;
import fl.transitions.*;
import fl.transitions.easing.*;

var menu:RightMenu;
var html:HTMLLoader;
var bmMC:MovieClip;
var courseFolder:String = "file:///D:/course/course/level0/page0";

init();
function init():void{
	this.graphics.clear();
	this.removeChildren();

	html = new HTMLLoader();
	html.addEventListener(Event.COMPLETE, completeHandler);
	html.addEventListener(MouseEvent.RIGHT_CLICK, upHandler);
	addChild(html);
	resize();
	loadPage(courseFolder);
}

function upHandler(e:MouseEvent):void{
	if(menu) menuStageClickHandler(null);
	menu = new RightMenu();
	menu.x = e.stageX;
	menu.y = e.stageY;
	menu.filters = [new DropShadowFilter(3, 45, 0x666666, 1,  3, 3, 0.6, 3)]
	if(menu.x > stage.stageWidth-menu.width-10) menu.x = stage.stageWidth-menu.width-10;
	if(menu.y > stage.stageHeight-menu.height-10) menu.y = stage.stageHeight-menu.height-10;
	menu.addEventListener("select", menuHandler);
	stage.addChild(menu);
	stage.addEventListener(MouseEvent.CLICK, menuStageClickHandler);
	stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, menuStageClickHandler);
}

function loadPage(uri:String):void{
	if(html.location != "about:blank"){
		var bmd:BitmapData = new BitmapData(html.width, html.height);
		bmd.draw(this, null, null, null, null, true);
		var bm:Bitmap = new Bitmap(bmd, "auto", true);
		bmMC = new MovieClip();
		bmMC.addChild(bm);
		this.addChild(bmMC);
	}
	SoundMixer.stopAll();
	courseFolder = uri;
	html.visible = false;
	if(uri == ""){
		html.loadString('<html style="background-color: #2e2e2e;"></html>');
		return;
	}
	html.load(new URLRequest(uri+"/index.html"));
}

function completeHandler(e:Event):void{
	var self = this;
	if(bmMC && bmMC.stage){
		setTimeout(function(){
			self.removeChild(bmMC);
			bmMC = null;
		}, 450);
		setTimeout(function(){
			TransitionManager.start(bmMC, {type:Fade, direction:Transition.OUT, duration:0.3, easing:None.easeNone});
		}, 100);
	} 
	if(html.location == "about:blank") return;
	html.visible = true;
	var console:Object = new Object();
	console.log = function(str){ trace(str); }
	html.window.console = console;
	html.window.playSound = playSound;
}

function menuHandler(e:DataEvent){
	if(e.data == "编辑"){
		var f:File = new File(courseFolder+"/index.fla");
		f.openWithDefaultApplication();
	}else if(e.data == "刷新"){
		html.reload();
	}else if(e.data == "上一页"){
		new File(courseFolder).openWithDefaultApplication();
	}else if(e.data == "下一页"){

	}
}

function menuStageClickHandler(e:MouseEvent):void{
	if(menu == null) return;
	stage.removeEventListener(MouseEvent.CLICK, menuStageClickHandler);
	stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, menuStageClickHandler);
	stage.removeChild(menu);
	menu = null;
}

function playSound(id:String, loop:int=0):void{
	(new Sound(new URLRequest(courseFolder+"/sounds/"+id+".mp3"))).play(0, loop);
}

function resize():void{
	html.width = stage.stageWidth-parent["subject"].bg.width;
	html.height = stage.stageHeight-this.y;
}