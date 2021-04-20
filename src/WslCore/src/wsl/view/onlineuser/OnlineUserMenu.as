package wsl.view.onlineuser{
	import flash.display.MovieClip;
	import flash.events.DataEvent;
	import flash.events.MouseEvent;
	
	import wsl.core.Global;
	import wsl.core.View;
	import wsl.utils.McToBtn;

	public class OnlineUserMenu extends View{
		static public var ITEM_SELECTED:String = "itemSelected";
		
		private var clickName:String;
		private var modeBg:MovieClip;
		private var showGroupCmb:MovieClip;
		private var showGroupBtn:MovieClip;
		private var addGroupBtn:MovieClip;
		private var randomGroupBtn:MovieClip;
		private var clearBtn:MovieClip;
		private var openConfigBtn:MovieClip;
		private var closeBtn:MovieClip;
		
		public function OnlineUserMenu(view:MovieClip){
			this.view = view;
			addChild(view);
		}
		
		public function init():void{
			modeBg = view["modeBg"];
			showGroupCmb = view["showGroupCmb"];
			showGroupBtn = view["showGroupBtn"];
			addGroupBtn = view["addGroupBtn"];
			randomGroupBtn = view["randomGroupBtn"];
			clearBtn = view["clearBtn"];
			openConfigBtn = view["openConfigBtn"];
			closeBtn = view["closeBtn"];
			McToBtn.setBtn(showGroupBtn);
			McToBtn.setBtn(addGroupBtn);
			McToBtn.setBtn(randomGroupBtn);
			McToBtn.setBtn(clearBtn);
			McToBtn.setBtn(openConfigBtn);
			McToBtn.setBtn(closeBtn);
			modeBg.width = Global.stage.stageWidth;
			modeBg.height = Global.stage.stageHeight;
			modeBg.addEventListener(MouseEvent.CLICK, modeBgHandler);
			showGroupBtn.addEventListener(MouseEvent.CLICK, bntHandler);
			addGroupBtn.addEventListener(MouseEvent.CLICK, bntHandler);
			randomGroupBtn.addEventListener(MouseEvent.CLICK, bntHandler);
			clearBtn.addEventListener(MouseEvent.CLICK, bntHandler);
			openConfigBtn.addEventListener(MouseEvent.CLICK, bntHandler);
			closeBtn.addEventListener(MouseEvent.CLICK, bntHandler);
			showGroupCmb.gotoAndStop(2);
			this.visible = false;
		}
		
		
		private function modeBgHandler(e:MouseEvent):void{
			this.visible = false;
		}

		private function bntHandler(e:MouseEvent):void{
			if(e.target == showGroupBtn){
				if(showGroupCmb.currentFrame == 1){
					showGroupCmb.gotoAndStop(2);
				}else{
					showGroupCmb.gotoAndStop(1);
				}
			}else if(e.target == addGroupBtn){
			}else if(e.target == randomGroupBtn){
			}else if(e.target == clearBtn){
			}else if(e.target == openConfigBtn){
			}else if(e.target == closeBtn){
			}
			e.target.gotoAndStop(2);
			modeBgHandler(e);
			this.dispatchEvent(new DataEvent(ITEM_SELECTED, false, false, e.target.name));
		}
		
		public function show():void{
			modeBg.x = -view.x-parent.x;
			modeBg.y = -view.y-parent.y;
			this.visible = true;
			parent.addChild(this);
		}
	}
}