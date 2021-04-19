package wsl.core{
	import flash.utils.ByteArray;

	public interface IDataStorage{
		function get data():ByteArray;
		function set data(bs:ByteArray):void;
	}
}