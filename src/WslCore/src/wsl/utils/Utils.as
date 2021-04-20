package wsl.utils{
	import flash.filters.BitmapFilterQuality;
	import flash.filters.BlurFilter;
	import flash.filters.ColorMatrixFilter;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.net.InterfaceAddress;
	import flash.net.NetworkInfo;
	import flash.net.NetworkInterface;
	
	public class Utils{ 
		public function Utils(){
		}
		
		/** 判断字符串是否为空 */
		static public function isEmpty(str:String):Boolean{
			var b:Boolean = true;
			
			if(str == "") return b;
			
			for(var i:uint=0; i<str.length; i++){
				if(str.charAt(i) != " "){
					b = false;
					break;
				}
			}
			
			return b;
		}
		
		/** 去掉字符串首尾的空格 */
		static public function removeBlank(str:String):String{
			str = str.replace(/^\s*/g,"");
			str = str.replace(/\s*$/g,"")
			return str;
		}
		
		
		/** 返回一个投影滤镜 */
		static public function getDropShadowFilter(blurX:Number=3, blurY:Number=3, strength:Number=0.5, distance:Number=3):DropShadowFilter{
			var color:Number = 0x0;
			var angle:Number = 45;
			var alpha:Number = 1;
			var inner:Boolean = false;
			var knockout:Boolean = false;
			var quality:Number = BitmapFilterQuality.HIGH;
			return new DropShadowFilter(distance, angle, color, alpha, blurX, blurY, strength, quality, inner,knockout);
		}
		
		/** 返回一个模糊滤镜 */
		static public function getBlurFilter(blurX:Number, blurY:Number):BlurFilter {
			return new BlurFilter(blurX, blurY, BitmapFilterQuality.HIGH);
		}
		
		/** 返回一个发光滤镜 */
		static public function getGlowFilter(alpha:Number=0.8, blur:Number=9, strength:Number=1.5, color:uint=0xFFFFFF):GlowFilter {
			var inner:Boolean = false;
			var knockout:Boolean = false;
			var quality:Number = BitmapFilterQuality.HIGH;
			return new GlowFilter(color, alpha ,blur, blur, strength, quality, inner, knockout);
		}
		
		/** 取得灰度滤镜 */
		static public function getGrayFilter():ColorMatrixFilter{
			var matrix:Array=[0.3086, 0.6094, 0.0820, 0, 0,  
				0.3086, 0.6094, 0.0820, 0, 0,  
				0.3086, 0.6094, 0.0820, 0, 0,  
				0,      0,      0,      1, 0];  
			return new ColorMatrixFilter(matrix);
		}
		
		/** 用于精减打开游戏与关闭游戏的时间，以便于保存。<br>
		 * 2017年6月22日到当前时间的秒数。*/
		static public function getShortTime():uint{
			var t1:Number = (new Date).time;
			var t2:Number = (new Date(2017,6,22)).time;
			return uint((t1-t2)/1000);
		}
		
		/** 取得年月日，如：20170706 */
		static public function getDay():int{
			var dt:Date = new Date();
			var yStr:String = ""+dt.getFullYear();
			var m:int = dt.getMonth()+1;
			var mStr:String = m>10 ? ""+m : "0"+m;
			var d:int = dt.getDate();
			var dStr:String = d>10 ? ""+d : "0"+d;
			var id:int = parseInt(yStr+mStr+dStr);
			return id
		}
		
		/** 取得当天到现在已经过的秒数，0-86400之间 */
		static public function getSeconds():int{
			var dt:Date = new Date();
			var id:int = dt.getHours()*3600+dt.getMinutes()*60+dt.getSeconds();
			return id;
		}
		
		/** 把配置文件中保存的时间转换成相对于1970年以来的时间，并格式化 */
		static public function formatTime(time:uint):String{
			var t:Number = (new Date(2013,10,10)).time;
			var date:Date = new Date(Number(t+time*1000));
			return date.fullYear+"-"+(date.month+1)+"-"+date.date+" "+date.hours+":"+date.minutes+":"+date.seconds;
		}
		
		/** 获取本机的IP地址 */
		static public function getIP():String{ 
			var interfaces:Vector.<NetworkInterface> = NetworkInfo.networkInfo.findInterfaces(); 
			var subInterface:InterfaceAddress;
			if(interfaces != null ) {
				for(var i:uint=0; i<interfaces.length; i++) { 
					if(interfaces[i].active == true){
						for (var j:uint=0; j<interfaces[i].addresses.length; j++) { 
							subInterface = interfaces[i].addresses[j];
							if(subInterface.ipVersion == "IPv4" && subInterface.address != "127.0.0.1" && subInterface.broadcast != ""){
								return subInterface.address;
							}
						} 
					}
				}
			} 
			return ""; 
		}
		
		/** 获取本机的Mac地址，做为设备的唯一标识  */
		static public function getMacID():String{
			var interfaces:Vector.<NetworkInterface> = NetworkInfo.networkInfo.findInterfaces(); 
			if(interfaces != null && interfaces.length > 0) {
				for(var i:uint=0; i<interfaces.length; i++) { 
					if(interfaces[i].active == true){
						if(!!interfaces[i].hardwareAddress) return interfaces[i].hardwareAddress.replace(/\-/ig,"");
					}
				} 
			}
			return "";
		}
	}
}

