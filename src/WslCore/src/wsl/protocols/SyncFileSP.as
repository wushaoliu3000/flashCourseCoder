package wsl.protocols{
	import flash.utils.ByteArray;

	public class SyncFileSP{
		static public const NAME:String = "SyncFileSP";
		
		/** 同步操作的名称 */
		public var name:String;
		/** 文件夹路径 */
		public var path:String;
		/** 文件的数据 */
		public var data:ByteArray;
		/** 操作码，大文件时分段传, 0没有分段， 1开始分段(分段传输的第一段)， 2继续分段(分段传输的中间段)， 3最后一段(分段传输的最后一段)。 */
		public var opcode:int;
		/** 文件大小(字节为单位) */
		public var size:int;
		
		/** 文件传输 。<br>
		 * name 同步操作的名称。<br>
		 * path 文件夹路径。<br>
		 * data 文件的数据。<br>
		 * opcode 操作码，大文件时分段传, 0没有分段， 1开始分段(分段传输的第一段)， 2继续分段(分段传输的中间段)， 3最后一段(分段传输的最后一段)。*/
		public function SyncFileSP(name:String="", path:String="", data:ByteArray=null, opcode:int=0, size:int=0):void{
			this.name = name;
			this.path = path;
			this.opcode = opcode;
			this.data = data;
			this.size = size;
		}
	}
}