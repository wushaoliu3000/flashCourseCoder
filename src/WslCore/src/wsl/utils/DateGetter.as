package wsl.utils{
	import flash.utils.getTimer;

	/** 日期时间处理 */	
	public class DateGetter{
		private static var _date:Date = new Date();
		
		public function DateGetter(){
		}
		
		public static function ini():void{
			_date = new Date();
		}
		
		/**
		 * 年 
		 *  @return 2012
		 */		
		public static function get year():String{
			return String(_date.getFullYear());
		}
		
		/**
		 * 月 
		 * @return 01,02,03...12 
		 */		
		public static function get month():String{
			_date = new Date();
			//_date = new Date(_date.getTime() + getTimer());
			return String(_date.getMonth() < 9 ? ("0" + (_date.getMonth() + 1)) : (_date.getMonth() + 1));
		}
		
		/**
		 * 日 
		 * @return 01,02,03...31 
		 */		
		public static function get date():String{
			_date = new Date();
			//_date = new Date(_date.getTime() + getTimer());
			return String(_date.getDate() < 10 ? ("0" + _date.getDate()) : _date.getDate());
		}
		
		/**
		 * 星期 
		 * @return 一,二，三,四,五,六,日 
		 */		
		public static function get day():String{
			//_date = new Date();
			//_date = new Date(_date.getTime() + getTimer());
			
			var day:String;
			switch (_date.getDay()) {
				case 0 :
					day = "日";
					break;
				case 1 :
					day = "一";
					break;
				case 2 :
					day = "二";
					break;
				case 3 :
					day = "三";
					break;
				case 4 :
					day = "四";
					break;
				case 5 :
					day = "五";
					break;
				case 6 :
					day = "六";
					break;
			}
			return day;
		}
		
		/** 1970 年 1 月 1 日午夜以来的毫秒数 */		
		public static function get time():Number {
			_date = new Date();
			return _date.getTime();
			//return _date.getTime();
		}
		
		/**
		 * 返回当前时间 
		 * 格式12:31:58 
		 */		
		public static function get currentTime():String{
			_date = new Date();
			//var date:Date = new Date(_date.getTime() + getTimer());
			return String(_date.getHours() < 10 ? ("0" + _date.getHours()) : _date.getHours()) + ":" + String(_date.getMinutes() < 10 ? ("0" + _date.getMinutes()) : _date.getMinutes()) + ":" + String(_date.getSeconds() < 10 ? ("0" + _date.getSeconds()) : _date.getSeconds());
		}
		
		/**
		 * 将2010/12/09-11:08:30格式转换为秒 
		 * @param value 2010/12/09-11:08:30
		 * @return 秒
		 */		
		public static function toSec(value:String):Number{
			var str:String = value;
			var year:int = Number(str.slice(0, 4));
			var month:int = Number(str.slice(5, 7));
			var day:int = Number(str.slice(8, 10));
			var hour:int = Number(str.slice(11, 13));
			var min:int = Number(str.slice(14, 16));
			var sec:int = Number(str.slice(17, 19));
			var date:Date = new Date(year, month - 1, day, hour, min, sec);
			return Math.floor(date.getTime()/1000);
		}
		
		/**
		 * 将秒数格式化为05:19字符串 
		 */		
		public static function formatSecond(sec:int):String{
			var m:int = Math.floor(sec / 60);
			var s:int = Math.floor(sec % 60);
			return (m < 10 ? ( "0" + m) : m) + ":" + (s < 10 ? ( "0" + s) : s);
		}	
	}
}