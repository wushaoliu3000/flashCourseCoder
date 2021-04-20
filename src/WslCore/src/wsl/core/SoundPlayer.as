package wsl.core{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
	
	public class SoundPlayer extends EventDispatcher{
		/** 当循环多次播放完成时处发Event事件 */
		static public const SOUND_LOOP_COMPLETE:String = "soundLoopComplete";
		
		/** 服务器刚启动播放声音时，如果是显示视频模块并且不播放声音，此时暂停声音播放。 */
		static public var isStartPause:Boolean;
		
		private var sound:Sound;
		private var channel:SoundChannel;
		private var times:int;//是否循环
		private var cnt:int = 0;
		private var time:Number;
		private var name:String;
		private var isPlay:Boolean;
		/** 音量大小 */
		private var v:int = 100;
		
		public function SoundPlayer(){
		}
		
		/** 播放一个mp3声音。<br>
		 * url 要播放的mp3名称。<br>
		 * times 要循环播放的次数。*/
		public function play(nm:String, times:int=1):void{
			this.name = nm;
			this.times = times;
			this.cnt = 0;
			this.isPlay = true;
			
			sound = new Sound();
			sound.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			sound.addEventListener(Event.COMPLETE, loadCompleteHandler);
			sound.load(new URLRequest(nm));
		}
		
		private function loadCompleteHandler(e:Event):void{
			if(channel) channel.stop();
			channel = sound.play();
			volume = v;
			channel.addEventListener(Event.SOUND_COMPLETE, soundCompleteHandler);
			if(isStartPause) {
				pause();
				isStartPause = false;
			}
		}
		
		private function soundCompleteHandler(e:Event):void{
			if(cnt >= times-1){
				close();
				this.dispatchEvent(new Event(SOUND_LOOP_COMPLETE));
				return;
			}
			channel = sound.play();
			channel.addEventListener(Event.SOUND_COMPLETE, soundCompleteHandler);
			cnt++;
		}
		
		/** 设置音量大小  1~100之间*/
		public function set volume(n:int):void{
			v = n;
			if(channel == null) return;
			var st:SoundTransform=new SoundTransform();
			st.volume = n/100;
			channel.soundTransform=st;
		}
		
		/** 暂停播放 */
		public function pause():void{
			if(isPlay == true && channel != null){
				isPlay = false;
				time = channel.position;
				channel.stop();
			}
		}
		
		/** 恢复暂停的播放 */
		public function resume():void{
			if(isPlay == false && channel != null){
				isPlay = true;
				channel = sound.play(time);
				channel.addEventListener(Event.SOUND_COMPLETE, soundCompleteHandler);
			}
		}
		
		/** 停止声音播放与close方法一样功能 */
		public function stop():void{
			close();
		}
		
		/** 停止声音播放 */
		public function close():void{
			if(channel != null){
				channel.removeEventListener(Event.SOUND_COMPLETE, soundCompleteHandler);
				channel.stop();
			}
			isPlay = false;
			channel = null;
			sound = null;
		}
		
		private function ioErrorHandler(e:IOErrorEvent):void {
		}
	}
}