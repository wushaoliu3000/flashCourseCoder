package wsl.view.onlineuser{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.utils.Dictionary;
	
	import wsl.core.Global;
	import wsl.core.View;
	import wsl.protocols.OnlineUserSP;
	import wsl.view.flippage.FlipPageView;
	import wsl.view.flippage.IPageItemClick;
	import wsl.view.flippage.PageItemVO;
	import wsl.view.listpanel.ListItem;
	import wsl.view.listpanel.ListItemVO;
	import wsl.view.listpanel.ListPane;
	import wsl.view.listpanel.ScrollView;
	
	/** 此类为单例<br>
	 * 提供一个在线用户展示界面，界面由包括此类的应用程序提供，此类提供Show()与hide()方法来显示与隐藏界面。<br>
	 * 作用如下：<br>
	 * 1、选择要转发Socket信息的在线用户，当点击选择按钮后发送Event.SELECT事件，可以在此事件的侦听器中调用getSelectOnlineUser()方法
	 * 来取得选择的用户。
	 */
	public class OnlineUserView extends View implements IPageItemClick{
		static private var inst:OnlineUserView;
		
		private var modeBg:Sprite;
		private var backcall:Function;
		private var userVec:Vector.<OnlineUserSP>;
		private var bg:MovieClip;
		private var menuBtn:MovieClip;
		private var menu:OnlineUserMenu;
		private var userPanel:FlipPageView;
		private var titleTf:TextField;
		private var groupBg:MovieClip;
		private var groupPanel:ListPane;
		private var groupSV:ScrollView;
		private var curGroupIndex:int;
		
		/** 存储当前在线的，或连接过的人员 */
		private var onlineVec:Vector.<PageItemVO>;
		/** 存储从分组配置文件里加载的所有人员 */
		private var allVec:Vector.<PageItemVO>;
		/** 存储当前分组配置 */
		private var groupDic:Dictionary = new Dictionary();
		
		/** 此类为单例<br>
		 * 提供一个在线用户展示界面，界面由包括此类的应用程序提供，此类提供show()与hide()方法来显示与隐藏界面。<br>
		 * 作用如下：<br>
		 * 1、选择要转发Socket信息的在线用户，当点击确定按钮后回调backcall函数，此函数在show方法中传入。
		 */
		public function OnlineUserView(){
			if(inst != null){
				throw new Error("SocketConnect是单例，通过getInstance()方法获得实例！");
			}
			
			initView("OnlineUserPanel");
			initUI();
			Global.stage.addEventListener(Event.RESIZE, resizeHandler);
			resizeHandler(null);
		}
		
		private function createBg():void{
			if(modeBg == null){
				modeBg = new Sprite();
			}
			modeBg.graphics.clear();
			modeBg.graphics.beginFill(0x0, 0.5);
			modeBg.graphics.drawRect(0, 0, Global.stageWidth, Global.stageHeight);
			modeBg.graphics.endFill();
			modeBg.x = -x;
			modeBg.y = -y;
			addChildAt(modeBg, 0); 
		}
		
		private function resizeHandler(e:Event):void{
			var w:Number = Global.stage.stageWidth;
			var h:Number = Global.stage.stageHeight;
			if(modeBg){
				removeChild(modeBg);
			}
			Global.setScale(this);
			x = int((w - bg.width*scaleX)/2);
			y = int((h - bg.height*scaleX)/2);
			createBg();
		}
		
		static public function getInstance():OnlineUserView{
			if(inst == null){
				inst = new OnlineUserView();
			}
			return inst;
		}
		
		private function initUI():void{
			bg = view["bg"];
			bg.width = 775;
			bg.height = 460;
			titleTf = view["titleTf"];
			groupBg = view["groupBg"];
			groupBg.height = bg.height - 68;
			
			//创建翻页
			userPanel = new FlipPageView(540, 410, true);
			userPanel.x = 199;
			userPanel.y = 68;
			userPanel.setPageItemClick(this);
			addChild(userPanel);
			
			//创建分组
			groupPanel = new ListPane(true, false, true);
			groupPanel.addEventListener(ListPane.LONG_PRESS, groupItemLongPressHandler);
			groupPanel.addEventListener(ListPane.SELECT_ITEM, groupItemSelectedHandler);
			groupSV = new ScrollView(groupPanel, 175, 395);
			groupSV.move(2, 68);
			addChild(groupSV);
			
			addGroup("在线人员");
			//getGroupXML();
			
			//创建菜单
			menuBtn = view["menuBtn"];
			menu = new OnlineUserMenu(view["menu"]);
			menu.addEventListener(OnlineUserMenu.ITEM_SELECTED, menuItemSelectedHandler);
			addChild(menu);
			menu.init();
			menuBtn.buttonMode = true;
			menuBtn.useHandCursor = true;
			menuBtn.addEventListener(MouseEvent.CLICK, menuBtnHandler);
			view["closeBtn"].addEventListener(MouseEvent.CLICK, closeBtnHandler);
			view["okBtn"].addEventListener(MouseEvent.CLICK, okBtnHandler);
		}
		
		private function groupItemLongPressHandler(e:DataEvent):void{
			trace(e.data);
		}
		
		private function menuItemSelectedHandler(e:DataEvent):void{
			if(e.data == "showGroupBtn"){
				showGroupPanel();
			}else if(e.data == "closeBtn"){
				this.hide();
			}
		}
		
		private function menuBtnHandler(e:MouseEvent):void{
			menu.show();
		}
		
		private function showGroupPanel():void{
			var vec:Vector.<PageItemVO> = userPanel.getItemVec();
			this.removeChild(userPanel);
			if(groupSV.visible == false){
				groupSV.visible = true;
				groupBg.visible = true;
				userPanel = new FlipPageView(540, 410, true);
				userPanel.x = 199;
			}else{
				groupSV.visible = false;
				groupBg.visible = false;
				userPanel = new FlipPageView(720, 410, true);
				userPanel.x = 24;
			}
			userPanel.y = 68;
			addChild(userPanel);
			userPanel.setItemVec(vec);
		}
		
		private function groupItemSelectedHandler(e:DataEvent):void{
			curGroupIndex = parseInt(e.data);
			if(curGroupIndex == 0 || curGroupIndex == 1){
				groupPanel.cancelAllSelected();
				groupPanel.selectedId = curGroupIndex;
			}else{
				groupPanel.cancelSelectedById(""+0);
				groupPanel.cancelSelectedById(""+1);
			}
			if(curGroupIndex == 0){
				if(onlineVec != null){
					userPanel.setItemVec(onlineVec);
				}
			}else if(curGroupIndex == 1){
				userPanel.setItemVec(allVec);
			}else{
				var idVec:Vector.<String> = groupPanel.getSelectedDataVec();
				var vec:Vector.<PageItemVO> = new Vector.<PageItemVO>;
				var tVec:Vector.<PageItemVO>;
				for(var i:uint=0; i<idVec.length; i++){
					tVec = getPageItemVoById(idVec[i]);
					if(tVec != null && tVec.length>0){
						for(var j:uint=0; j<tVec.length; j++){
							vec.push(tVec[j]);
						}
					}
				}
				userPanel.setItemVec(vec);
			}
		}
		
		private function getPageItemVoById(id:String):Vector.<PageItemVO>{
			if(!groupDic[id]) return null;
			
			var vec:Vector.<PageItemVO> = new Vector.<PageItemVO>;
			var idVec:Vector.<int> = groupDic[id] as Vector.<int>;
			for(var i:uint=0; i<idVec.length; i++){
				for(var j:uint=0; j<allVec.length; j++){
					if(idVec[i] == allVec[j].id){
						vec.push(allVec[j]);
						break;
					}
				}
			}
			return vec;
		}
		
		/** 添加一个组<br>
		 * name 组名 */
		private function addGroup(name:String, vec:Vector.<int>=null):void{
			var item:ListItemVO = new ListItemVO();
			item.name = name;
			if(name == "在线人员"){
				item.data =  ""+0;
				groupPanel.addItem(item,0xFF9900);
			}else if(name == "所有人员"){
				item.data =  ""+1;
				groupPanel.addItem(item, 0x009900);
			}else{
				item.data =  ""+groupPanel.getId();
				groupPanel.addItem(item);
			}
			
			groupSV.update(groupPanel.height);
			
			if(vec != null){
				addGroupMembers(item.data, vec);
			}
		}
		
		/** 为指定的组添加成员<br>
		 * id 要添加成员的组ID<br>
		 * vec 要添加的成员 */
		private function addGroupMembers(id:String, vec:Vector.<int>):void{
			groupDic[id] = vec;
		}
		
		/** 删除指定的组，同时删除此组关联的组员Vec<br> 
		 * id 要删除组的ID*/
		private function removeGroupById(id:String):void{
			groupPanel.removeItemById(id);
			groupDic[id] = null;
			delete groupDic[id];
		}
		
		
		/** 从配置文件读入分组 */
		private function getGroupXML():void{
			//MyLoader.loadTextByReserveUri(Global.configUri+"group1.xml", "", groupXMLHandler);
		}
		
		private function groupXMLHandler(str:String):void{
			var xml:XML = XML(str);
			var sXML:XMLList = xml.child("student").children();
			
			if(!xml.child("student") || sXML.length()<1) return;
			
			//清除现有的分组
			var item:ListItem;
			for(var i:uint=0; i<groupPanel.numChildren; i++){
				item = groupPanel.getChildAt(i) as ListItem;
				if(item.data != ""+0){
					removeGroupById(item.data);
				}
			}
			//重新设置所有人员
			var xmlList:XML;
			var vec:Vector.<int>;
			var vo:PageItemVO;
			allVec = new Vector.<PageItemVO>;
			addGroup("所有人员");
			for(i=0; i<sXML.length(); i++){
				vo = new PageItemVO();
				vo.id = parseInt(sXML[i].@id);
				vo.label = sXML[i].@name;
				vo.thumb = sXML[i].@boy == "男" ? "BoyHeader" : "GirlHeader";
				allVec.push(vo);
			}
			//创建新的分组
			for(i=0; i<xml.child("group").length(); i++){
				xmlList = xml.child("group")[i];
				vec = new Vector.<int>;
				for(var j:uint=0; j<xmlList.children().length(); j++){
					vec.push(xmlList.children()[j].@id);
				}
				addGroup(xmlList.@name, vec);
			}
			groupSV.update(groupPanel.height);
			
			userPanel.setItemVec(allVec);
		}
		
		
		/** 当翻页视图的实例被点击时执行<br>
		 *  当FlipPageView为实例单选时，itemIndex为选择的实例。此时itemVec为null<br>
		 * 当 FlipPageView为实例多选时，itemVec为选择的一个或多个实例。此时itemIndex为-1。 */
		public function pageItemClick(itemIndex:int, itemVec:Vector.<PageItemVO>):void{
			trace(itemIndex);
		}
		
		private function userSelectHandler(e:MouseEvent):void{
			var user:MovieClip = e.target as MovieClip;
			if(user.currentFrame == 1){
				user.gotoAndStop(2);
			}else{
				user.gotoAndStop(1);
			}
		}
		
		private function closeBtnHandler(e:MouseEvent):void{
			hide();
			if(backcall != null){
				backcall = null;
			}
		}
		
		/** 确定选择用户，发送OnlineUserEvent.SELECT事件 */
		private function okBtnHandler(e:MouseEvent):void{
			hide();
			var onlineUser:OnlineUserSP;
			var selectedOnlineUserVec:Vector.<OnlineUserSP> = new Vector.<OnlineUserSP>;
			for(var i:uint=0; i<userPanel.getSelectedVec().length; i++){
				onlineUser = new OnlineUserSP();
				onlineUser.userId = userPanel.getSelectedVec()[i].id;
				onlineUser.userName = userPanel.getSelectedVec()[i].label;
				selectedOnlineUserVec.push(onlineUser);
			}

			if(backcall != null){
				backcall(selectedOnlineUserVec);
				backcall = null;
			}
		}
		
		/** dispalyObject 表示此类要添加到的显示对象。<br>
		 * backcall 当点击确定按钮后要回调的方法，backcall方法必须接收一个OnlineUserSP类型的Vector对象为参数。 */
		public function show(displayObj:DisplayObjectContainer, backcall:Function, titleStr:String="在线人员"):void{
			this.backcall = backcall;
			
			this.titleTf.text = titleStr;
			displayObj.addChild(this);
			var w:Number = displayObj.width > stage.stageWidth ? stage.stageWidth : displayObj.width;
			var h:Number = displayObj.height > stage.stageHeight ? stage.stageHeight  : displayObj.height;
			this.x = int((w - bg.width)/2);
			this.y = int((h - bg.height)/2);
			resizeHandler(null);
			
			if(curGroupIndex == 0){
				userPanel.setItemVec(onlineVec);
			}
		}
		
		/** 此方法与show方法对应，从此类对象所在的DisplayObject上删除此类界面 */
		public function hide():void{
			if(this.parent){
				this.parent.removeChild(this);
			}
		}
		
		/** 更新用户列表，用socket服务器返回的在线用户数组来更新在线人数的显示 */
		public function addUsers(userArr:Vector.<OnlineUserSP>):void{
			userVec = new Vector.<OnlineUserSP>;
			onlineVec = new Vector.<PageItemVO>;
			var onlineUser:OnlineUserSP;
			var item:PageItemVO;
			for(var i:uint=0; i<userArr.length; i++){
				onlineUser = new OnlineUserSP();
				item = new PageItemVO();
				item.label = onlineUser.userName = (userArr[i] as OnlineUserSP).userName;
				item.id = onlineUser.userId = (userArr[i] as OnlineUserSP).userId;
				item.isOnline = true;
				item.thumb = "BoyHeader";
				userVec.push(onlineUser);
				if(item.label != "server"){
					onlineVec.push(item);
				}
			}
			if(this.parent && curGroupIndex == 0){
				userPanel.setItemVec(onlineVec);
			}
		}
		
		/** 返回在线用户数组 */
		public function getAllOnlineUser():Vector.<OnlineUserSP>{
			return userVec;
		}
		
		/** 通过用户名取得一个在线用户 */
		public function getOnlineUserByName(userName:String):OnlineUserSP{
			for(var i:uint=0; i<userVec.length; i++){
				if(userVec[i].userName == userName){
					return userVec[i];
				}
			}
			return null;
		}
		
		/** 通过用户的ID(即socketId)取得一个在线用户 */
		public function getOnlineUserById(userId:uint):OnlineUserSP{
			for(var i:uint=0; i<userVec.length; i++){
				if(userVec[i].userId == userId){
					return userVec[i];
				}
			}
			return null;
		}
	}
}