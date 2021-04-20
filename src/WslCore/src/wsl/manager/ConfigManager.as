package wsl.manager{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;

	public class ConfigManager{
		
		public function ConfigManager(){
		}
		
		static public function getConfig():XML{
			var xml:XML;
			var f:File = File.applicationStorageDirectory.resolvePath("config.xml");
			var fs:FileStream = new FileStream();
			if(f.exists == false){
				xml = <data><netModule type="1"/><autoLoging auto="0"/><baseUri uri=""/><keepPwd keep="1"/><loginIP/><userInfo/></data>
				fs.open(f, FileMode.WRITE);
				fs.writeMultiByte(xml.toXMLString(), "utf-8");
				fs.close();
			}else{
				fs.open(f, FileMode.READ);
				xml = XML(fs.readMultiByte(fs.bytesAvailable, "utf-8"));
				fs.close();
			}
			return xml;
		}
		
		static public function saveConfig(xml:XML):void{
			var f:File = File.applicationStorageDirectory.resolvePath("config.xml");
			var fs:FileStream = new FileStream();
			fs.open(f, FileMode.WRITE);
			fs.writeMultiByte(xml.toXMLString(), "utf-8");
			fs.close();
		}
		
		/** 取得登陆的网络模式 */
		static public function getNetModule():int{
			var xml:XML = getConfig();
			return parseInt(xml["netModule"].@["type"]);
		}
		
		/**  设置登陆的网络模式 */
		static public function setNetModule(type:int):void{
			var xml:XML = getConfig();
			xml["netModule"].@["type"] = ""+type;
			saveConfig(xml);
		}
		
		/** 获取是否自动登陆 0_显示登陆模式面板  1_自动登陆 */
		static public function getAutoLoging():int{
			var xml:XML = getConfig();
			return parseInt(xml["autoLoging"].@["auto"]);
		}
		
		/** 设置是否自动登陆 0_显示登陆模式面板  1_自动登陆 */
		static public function setAutoLoging(type:int):void{
			var xml:XML = getConfig();
			xml["autoLoging"].@["auto"] = ""+type;
			saveConfig(xml);
		}
		
		/** 获取讲稿、配置等文件存放的目录 */
		static public function getBaseUri():String{
			var xml:XML = getConfig();
			return xml["baseUri"].@["uri"];
		}
		
		/** 设置讲稿、配置等文件存放的目录 */
		static public function setBaseUri(uri:String):void{
			var xml:XML = getConfig();
			xml["baseUri"].@["uri"] = ""+uri;
			saveConfig(xml);
		}
		
		/** 获取是否保存密码 0为不保存   1为保存 */
		static public function getKeepPwd():int{
			var xml:XML = getConfig();
			return parseInt(xml["keepPwd"].@["keep"]);
		}
		
		/** 获取已经保存的登陆IP */
		static public function getLoginIPVec():Vector.<String>{
			var vec:Vector.<String>;
			var xml:XML = getConfig();
			var xmlList:XMLList = xml["loginIP"];
			if(xmlList){
				vec = new Vector.<String>;
				for(var i:uint=0; i<xmlList.children().length(); i++){
					vec.push(xmlList.children()[i].@["ip"]);
				}
			}
			return vec;
		}
		
		/** 添加要保存的登陆IP */
		static public function addLoginIP(ip:String):void{
			var xml:XML = getConfig();
			var xmlList:XMLList = xml["loginIP"];
			for(var i:uint=0; i<xmlList.children().length(); i++){
				if(xmlList.children()[i].@["ip"] == ip){
					var t:XML = <ip ip={xmlList.children()[i].@["ip"]}/>;
					delete xmlList.children()[i];
					xmlList.appendChild(t);
					saveConfig(xml);
					return;
				}
			}
			if(xmlList.children().length() >= 3){
				delete xmlList.children()[0];
			}
			xmlList.appendChild(<ip ip={ip} />);
			saveConfig(xml);
		}
		
		/** 删除已经保存的登陆IP */
		static public function delLoginIP(ip:String):void{
			var xml:XML = getConfig();
			var xmlList:XMLList = xml["loginIP"];
			for(var i:uint=0; i<xmlList.children().length(); i++){
				if(xmlList.children()[i].@["ip"] == ip){
					delete xmlList.children()[i];
					break;
				}
			}
			saveConfig(xml);
		}
		
		/** 获取已经保存的登陆信息。返回对象格式 {name:"", pwd:""} */
		static public function getUserInfo():Vector.<Object>{
			var vec:Vector.<Object>;
			var obj:Object;
			var xml:XML = getConfig();
			var xmlList:XMLList = xml["userInfo"];
			if(xmlList){
				vec = new Vector.<Object>;
				for(var i:uint=0; i<xmlList.children().length(); i++){
					obj = {name:xmlList.children()[i].@["nm"], pwd:xmlList.children()[i].@["pwd"]}
					vec.push(obj);
				}
			}
			return vec;
		}
		
		/** 添加要保存的登陆信息 */
		static public function addUserInfo(name:String, pwd:String, isSavePwd:Boolean):void{
			var xml:XML = getConfig();
			var xmlList:XMLList = xml["userInfo"];
			xml["keepPwd"].@["keep"] = ""+(isSavePwd==true ? 1 : 0);
			for(var i:uint=0; i<xmlList.children().length(); i++){
				if(xmlList.children()[i].@["nm"] == name){
					if(isSavePwd ==  true){
						xmlList.children()[i].@["pwd"] = pwd;
					}else{
						xmlList.children()[i].@["pwd"] = "";
					}
					var t:XML = <info nm={xmlList.children()[i].@nm} pwd={xmlList.children()[i].@pwd}/>;
					delete xmlList.children()[i];
					xmlList.appendChild(t);
					saveConfig(xml);
					return;
				}
			}
			if(xmlList.children().length() >= 3){
				delete xmlList.children()[0];
			}
			if(isSavePwd ==  true){
				xmlList.appendChild(<info nm={name} pwd={pwd} />);
			}else{
				xmlList.appendChild(<info nm={name} />);
			}
			saveConfig(xml);
		}
		
		/** 删除已经保存的登陆信息 */
		static public function delUserInfo(name:String):void{
			var xml:XML = getConfig();
			var xmlList:XMLList = xml["userInfo"];
			for(var i:uint=0; i<xmlList.children().length(); i++){
				if(xmlList.children()[i].@["nm"] == name){
					delete xmlList.children()[i];
					break;
				}
			}
			saveConfig(xml);
		}
	}
}