package wsl.protocols{
	
	/** 提供一个简单的回复协议定义，只回复一个字符串 */
	public class BaseReturnSP{
		static public const NAME:String = "BaseReturnSP";
		private var _data:String;
		public function BaseReturnSP(str:String){
			_data = str;
		}

		public function get data():String{
			return _data;
		}

		public function set data(value:String):void{
			_data = value;
		}

	}
}