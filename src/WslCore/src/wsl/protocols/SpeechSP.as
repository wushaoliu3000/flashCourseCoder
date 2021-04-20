package wsl.protocols{
	public class SpeechSP{
		static public const NAME:String = "SpeechSP";
		
		/** 要执行的操作<br> 
		 * 1 打开讲稿<br> 2 上一页<br> 3 下一页*/
		public var operate:int;
		public var data:String;
		public function SpeechSP(operate:int=1, data:String=""){
			this.operate = operate;
			this.data = data;
		}
	}
}