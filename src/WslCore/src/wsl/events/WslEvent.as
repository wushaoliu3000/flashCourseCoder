package wsl.events{
	import flash.events.Event;
	
	public class WslEvent extends Event{
		private var _data:*;
		
		public function WslEvent(type:String, obj:*, bubbles:Boolean=false, cancelable:Boolean=false){
			super(type, bubbles, cancelable);
			this._data = obj;
		}
		
		
		public function get data():*{
			return _data;
		}

		public function set data(value:*):void{
			_data = value;
		}

	}
}