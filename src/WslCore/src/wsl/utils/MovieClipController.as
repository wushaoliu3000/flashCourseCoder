package wsl.utils{
	import flash.display.MovieClip;

	public class MovieClipController{
		
		public function MovieClipController(){
		}
		
		/** 停止MovieClip及子级的播放 */
		static public function stopMc(mc:MovieClip):void{
			var subMc:MovieClip;
			mc.stop();
			for(var i:uint=0; i<mc.numChildren; i++){
				if(mc.getChildAt(i) is MovieClip){
					subMc = mc.getChildAt(i) as MovieClip;
					subMc.stop();
					//递归
					stopMc(subMc);
				}
			}
		}
		
		/** 播放MovieClip及子级 */
		static public function playMc(mc:MovieClip):void{
			var subMc:MovieClip;
			for(var i:uint=0; i<mc.numChildren; i++){
				if(mc.getChildAt(i) is MovieClip){
					subMc = mc.getChildAt(i) as MovieClip;
					subMc.gotoAndPlay(1);
					//递归
					stopMc(subMc);
				}
				mc.gotoAndPlay(1);
			}
		}
	}
}