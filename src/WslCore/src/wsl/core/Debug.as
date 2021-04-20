package wsl.core{
	import flash.display.Stage;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	public class Debug{
		/** 弹出一个消息提示框 */
		static private var alt:Alert;
		
		/** 假如isAlt=false，即使调用了alert方法，也不会显示alert提示框。 */
		static public var isAlt:Boolean = true;
		
		/**设置一个舞台对象，以便Alert等显示对象能正确显示*/
		static public var stage:Stage;
		
		/** 假如isTrace为flase  myTrace方法将不做输出 */
		static public var isTrace:Boolean = true;
		
		public function Debug(){
		}
		
		/** 代替trace功能<br>
		 * 在isTrace为flase时不做输出 */
		static public function myTrace(...parameters):void{
			if(isTrace){
				trace(parameters);
			}
		}
		
		/** 显示一个提示对话框 <br>
		 * msg 要显示的内容 <br>
		 * title 提示对话框的标题<br>
		 * backFun 点击确定按钮后要回调的函数<br>
		 * param  回调函数要接收的参数*/
		static public function alert(msg:String, title:String="", backFun:Function=null, param:Object=null, btnText:String="确定", cancelBackFun:Function=null, cancelParam:Object=null, cancelLabel:String="取消", hideColseBtn:Boolean=false, tipCBStr:String=""):void{
			if(stage == null){
				throw new Error("请为Debug.stage设置一个stage对象!");
			}
			
			if(isAlt == false) return;
			
			if(alt == null){
				alt = new Alert();
			}
			
			alt.setMessage(msg, title, backFun, param, btnText, cancelBackFun, cancelParam, cancelLabel, hideColseBtn, tipCBStr);
		}
		
		static public function setAlertBlank(r:Rectangle):void{
			alt.setBlank(r);
		}
		
		static public function setAlertY(y:int):void{
			alt.y = y;
		}
		
		static public function getAltH():int{
			return alt.height;
		}
		
		/** 输出字符 */
		static public function traceString(str:String, ...arg):void{
			trace(str, arg);
		}
		
		/** 输出一个对象的格式化字符串 */
		static public function traceObject(obj:Object, title:String = ""):void {
			trace("\nDebug-->printObject:  " + title);
			
			if(obj){
				trace(getDecodeStr(obj));
			}else{
				trace("要打印的对象有误！");
			}
		}
		
		/** 返回一个对象的格式化字符串 */
		static public function getDecodeStr(obj:Object, kspace:String = "", prekspace:String = ""):String {
			if (obj is Number || obj is String) {
				var str:String = "";
				if(obj is String){
					str = '"'+obj.toString()+'"';
				}else{
					str = obj.toString();
				} 
				return str;
			}else if (obj is Array) {
				str = kspace + "[";
				for (var i:uint = 0; i < obj.length; i++) {
					str += "\n" + kspace + "\t" + i + " : " + getDecodeStr(obj[i], kspace + "\t", kspace + "\t") + (i < obj.length -1 ? "," : "");
				}
				str += "\n" + kspace + "]\n" + prekspace;
				return str;
			}else if (obj is Object) {
				var firstAtr:Boolean = true;
				str = kspace + "{";
				for(var nm:String in obj){
					str += (firstAtr ? "" : ",") + "\n" + kspace + "\t" + nm + " : " + getDecodeStr(obj[nm], kspace + "\t", kspace + "\t");
					firstAtr = false;
				}
				str += "\n" + kspace + "}\n" + prekspace;
				return str;	
			}
			return kspace + obj;
		}
		
		/** 输出一个字节数组的16进制字符串 */
		static public function traceHex(receiveBuf:ByteArray, describe:String=""):void{
			var p:uint = receiveBuf.position;
			var len:uint = receiveBuf.length;
			var str:String = "";
			var hex:String = "";
			receiveBuf.position = 0;
			while (len > 0){
				hex = receiveBuf.readUnsignedByte().toString(16).toUpperCase();
				if (hex.length < 2) hex = '0' + hex;
				str += hex + ' ';
				len--;
			}
			receiveBuf.position = p;
			
			trace(describe, str);
		}
		
		/** 输出一个字节数组的字符串，每一个字节转成一个字符 */
		static public function traceChar(receiveBuf:ByteArray, describe:String=""):void{
			var p:uint = receiveBuf.position;
			var len:uint = receiveBuf.length;
			var str:String = "";
			var c:String = "";
			receiveBuf.position = 0;
			while (len > 0){				
				c = receiveBuf.readUTFBytes(1);
				str += c;
				len--;
			}
			receiveBuf.position = p;
			
			trace(describe, str);
		}
	}
}