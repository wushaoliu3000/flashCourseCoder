package wsl.protocols{
	/** 通知服用器或指定的用户，加载指定的模块 */
	public class LoadModuleSP{
		static public const NAME:String = "LoadModuleSP";
		
		private var _id:int;
		private var _uri:String = "";
		
		/** 通知服用器或指定的用户，加载指定的模块 */
		public function LoadModuleSP(id:int, uri:String){
			_id = id;
			_uri = uri;
		}
		
		/** 模块ID<br>
		 * 每一个模块有一个指定的ID,如果此模块需要有SocketSession，
		 * 则此模块ID就是SocketSession的ID */
		public function get id():int{
			return _id;
		}
		public function set id(value:int):void{
			_id = value;
		}

		/** 模块的路径与名称 */
		public function get uri():String{
			return _uri;
		}
		public function set uri(value:String):void{
			_uri = value;
		}
	}
}