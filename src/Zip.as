package wsl.utils {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.CompressionAlgorithm;
	
	import wsl.core.Setting;
		
	public class Zip extends EventDispatcher{
		/** 没有找到要解压的文件 */
		static public const NOT_FILE:String = "notFile";
		/** 解压完成 */
		static public const FINISH:String = "finish";
		
		private var numFile:int = 0;
		private var zipBa:ByteArray = new ByteArray();
		/** 保存以下路径的目的是，把绝对路径裁剪成相对路径 */
		private var fileDirectory:String;
		private var directory:String;
		
		public function Zip(){
		}
		
		/** 打开一个目录下的所有文件为一个课程文件（zip文件）。
		 * @param inputFolder 要打包的目录。
		 * @param outFile 要输出的文件路径，文件扩展名只能是zip。 */
		public function baleCourse(inputFolder:String, outFile:String):void{
			var flag:Number = new Date().getTime();
			//修改配置文件中的课程修改日期，用于判断当前目录下的文件与刚下载的文件是否一至
			var str:String = Setting.readText(inputFolder+"config.txt");
			if(str == null){
				trace("要打包的目录下必需要有config.txt文件");
				return;
			}
			var obj:Object = JSON.parse(str);
			obj.modifyTime = flag;
			str = JSON.stringify(obj);
			Setting.writeText(inputFolder+"config.txt", str);
			//压缩文件目录到一个zip中
			compress(inputFolder, outFile, flag);
		}
		
		/** 获取一个zip文件的modifyTime（修改时间），macId(mac地址)。
		 * @param path 要读取的zip文件路径。
		 * @return {modifyTime:"", macId:""} */
		public function getFlag(path:String):Object{
			var obj:Object = {};
			var f:File = new File(path);
			var fs:FileStream = new FileStream();
			fs.open(f, FileMode.READ);
			obj.macId = fs.readMultiByte(25, "utf-8");
			obj.modifyTime =fs.readDouble();
			fs.close();
			return obj;
		}
		
		/** 压缩一个目录下的所有文件。
		 * @param inputDirectory 要压缩的目录。
		 * @param outDirectory 压缩文件的保存目录。
		 * @param flag 写到文件最前面的标识(此标识不压缩，方便读取)，如果为-1则自动写入当前系统时间。 */
		public function compress(inputDirectory:String, outDirectory:String=null, flag:Number=-1):void{
			this.fileDirectory = inputDirectory
			this.directory = inputDirectory.replace("file:///", "");
			if(outDirectory == null) outDirectory = Setting.downDirectory+"test.zip";
			var root:File = new File(inputDirectory);
			zipBa.writeInt(0);
			compressFun(root);
			zipBa.position = 0;
			zipBa.writeInt(numFile);
			zipBa.compress(CompressionAlgorithm.LZMA);
			var ba:ByteArray = new ByteArray();
			//写入25个字符做占位符，等待用户下载后获本机的macId来替换此字符串，防止其它用户使用
			ba.writeMultiByte("0000000000000000000000000", "utf-8");
			//写入modifyTime
			ba.writeDouble(flag == -1 ? new Date().getDate() : flag);
			ba.writeBytes(zipBa);
			saveFile(ba, outDirectory);
		}
		private function getMac():String{
			var str:String = "";
			for(var i:uint=0; i<20; i++){
				str += "0";
			}
			return str;
		}
		
		private function compressFun(directory:File):void{
			var f:File;
			var name:String;
			var arr:Array = directory.getDirectoryListing();
			var e:String;
			for(var i:uint=0; i<arr.length; i++){
				f = arr[i];
				if(f.isDirectory){
					compressFun(f);
				}else{
					e = f.extension;
					if(e=="html" || e=="js" || e=="png" || e=="jpg" || e=="mp3" || e=="wav" || e=="mp4" || e=="flv" || e=="f4v" || e=="ico" || e=="txt" || e=="json"){
						zipBa.writeBytes(getFormatBa(f.nativePath, getBytes(f)));
						numFile++;
					}
				}
			}
		}
		
		/** 解压一个压缩文件。
		 * @param inputFile 要解压的压缩文件。
		 * @param outDirectory 解压出的文件要保存的目录。
		 * @param delcurDirectory 在解压前是否删除当前目录下的所有内容。 */
		public function uncompress(inputFile:String, outDirectory:String=null, delcurDirectory=true):void{
			if(outDirectory == null) outDirectory = Setting.currentDirectory;
			var f:File = new File(outDirectory);
			if(delcurDirectory && f.exists) f.deleteDirectory(true);
			f = new File(inputFile);
			if(f.exists == false){
				this.dispatchEvent(new Event(NOT_FILE));
				trace("没有找到要解压的文件");
				return;
			}
			var ba:ByteArray = getBytes(f, true);
			ba.uncompress(CompressionAlgorithm.LZMA);
			ba.position = 0;
			var num:uint = ba.readInt();
			var totalLen:uint;
			var nmLen:uint;
			var nm:String;
			var bytes:ByteArray = new ByteArray();
			for(var i:uint=0; i<num; i++){
				totalLen = ba.readInt();
				nmLen = ba.readInt();
				nm = ba.readMultiByte(nmLen, "utf-8");
				bytes = new ByteArray();
				ba.readBytes(bytes, 0, totalLen - nmLen);
				saveFile(bytes, outDirectory+nm);
			}
			this.dispatchEvent(new Event(FINISH));
		}
		
		private function getFormatBa(nm:String, bytes:ByteArray):ByteArray{
			nm = nm.replace(/\\/ig, "/");
			nm = nm.replace(fileDirectory+"/", "");
			nm = nm.replace(directory+"/", "");
			nm = nm.replace(fileDirectory, "");
			nm = nm.replace(directory, "");
			var nmBa:ByteArray = new ByteArray();
			nmBa.writeMultiByte(nm, "utf-8");
			var ba:ByteArray = new ByteArray();
			ba.writeInt(nmBa.length+bytes.length);
			ba.writeInt(nmBa.length);
			ba.writeBytes(nmBa);
			ba.writeBytes(bytes);
			return ba;
		}
		
		private function getBytes(f:File, isFlag:Boolean=false):ByteArray{
			var ba:ByteArray = new ByteArray();
			var fs:FileStream = new FileStream();
			fs.open(f, FileMode.READ);
			//丢掉flag，课程打包时写入的modifyTime与下载完后写入的macId
			if(isFlag){
				var str:String = fs.readMultiByte(25, "utf-8");
				var n:Number = fs.readDouble();
			}
			fs.readBytes(ba);
			fs.close();
			fs = null;
			return ba;
		}
		
		private function saveFile(ba:ByteArray, path:String):void{
			ba.position = 0;
			var f:File = new File(path);
			var fs:FileStream = new FileStream();
			fs.open(f, FileMode.WRITE);
			fs.writeBytes(ba);
			fs.close();
			fs = null;
		}
	}
}