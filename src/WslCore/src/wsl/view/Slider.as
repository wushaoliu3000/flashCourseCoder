package wsl.view{
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	import wsl.core.View;
	import wsl.events.WslEvent;
	import wsl.utils.McToBtn;
	
	public class Slider extends View{
		static public const VALUE_CHANGE:String = "valueChange";
		
		private var thumb:MovieClip;
		private var track:MovieClip;
		private var valueTf:TextField;
		private var _value:Number;
		private var mX:Number;
		private var trackW:Number;
		private var min:Number;
		private var max:Number;
		/** 分段数 */
		private var snap:int;
		/** 刻度数 */
		private var calibration:uint;
		/** 刻度值 */
		private var calibrationValue:Number;
		/** 刻度的标签 */
		private var calibrationLabelVec:Vector.<String>;
		
		/** 拖动滑动条<br>
		 * view 滑动条UI<br> min 最小值, min>=0<br> max 最大值<br> 
		 * calibration 刻度数。如：calibration=3  |___|___|<br>
		 * 注意：如果calibration<1 VALUE_CHANGE事件返回的值在min到max这间的值,否则返回刻度值。*/
		public function Slider(view:MovieClip, min:Number=0, max:Number=100, calibration:int=0){
			min = min < 0 ? 0 : min;
			this.view = view;
			this.min = min;
			this.max = max;
			this.snap = calibration-1;
			this.calibration = calibration;
			initUI();
		}
		
		private function initUI():void{
			thumb = view["thumb"];
			track = view["track"];
			valueTf = view["valueTf"];
			thumb.focusRect = false;
			trackW = track.width;
			McToBtn.setBtn(thumb, "", true);
			thumb.addEventListener(MouseEvent.MOUSE_DOWN, thumbDownHandler);
			drawSnape();
		}
		
		private function drawSnape():void{
			if(calibration < 2) return;
			
			view.graphics.clear();
			view.graphics.lineStyle(2, 0xB8B4A3, 1);
			for(var i:uint=0; i<calibration; i++){
				if(i == calibration-1){
					view.graphics.moveTo(i*trackW/snap-1, -2);
					view.graphics.lineTo(i*trackW/snap-1, 0);
				}else{
					view.graphics.moveTo(i*trackW/snap+1, -2);
					view.graphics.lineTo(i*trackW/snap+1, 0);
				}
			}
		}
		
		/** 如果calibration<2 设置的是min到max这间的值，否则，设置的是刻度值<br>
		 * 返回的值在min到max这间的值。 */
		public function get value():Number{
			return _value;
		}
		
		public function set value(value:Number):void{
			if(value < min) value = min;
			if(value > max) value = max;
			_value = value;
			valueTf.text = ""+int(value);
			
			var d:Number = max - min;
			thumb.x = (value-min)/d*trackW;
			
			if(calibration > 1 && calibrationLabelVec != null){
				valueTf.text = calibrationLabelVec[int(value)];
			}
			
			this.dispatchEvent(new WslEvent(VALUE_CHANGE, value));
			
			valueTf.width = valueTf.textWidth+10;
		}
		
		/** 设置能滑动的范围 */
		public function setTrackWidth(w:int):void{
			trackW = w;
			track.width = w;
			valueTf.x = w+5;
			drawSnape();
			var d:Number = max - min;
			thumb.x = (value-min)/d*trackW;
		}
		
		/** 设置一个刻度对应的标签数组，当刻度改变时，显示对应的标签。<br>
		 * 每个刻度标签不要超过四个字符，否则显示不下。*/
		public function setcCalibrationLabels(arr:Array):void{
			calibrationLabelVec = new Vector.<String>;
			for(var i:uint=0; i<arr.length; i++){
				calibrationLabelVec.push(arr[i]);
			}
		}
		
		/** 是否隐藏文本 */
		public function visibleValueTf(b:Boolean):void{
			view.valueTf.visible = b;
		}
		
		private function thumbDownHandler(e:MouseEvent):void{
			mX = view.mouseX;
			view.stage.addEventListener(MouseEvent.MOUSE_MOVE, stageMoveHandler);
			view.stage.addEventListener(MouseEvent.MOUSE_UP, stageUpHandler);
		}
		
		private function stageMoveHandler(e:MouseEvent):void{
			if(view.mouseX < -5 || view.mouseX > trackW+3) return;
			
			if(calibration < 2){
				thumb.x -= mX-view.mouseX;
			}else{
				var n:Number = int(view.mouseX/trackW*snap);
				
				if(view.mouseX > mX){
					thumb.x = n*trackW/snap;
				}else{
					if(view.mouseX < 0){
						thumb.x = 0;
					}else{
						thumb.x = (n+1)*trackW/snap;
						n = n+1;
					}
				}
				n = n < 0 ? 0 : n;
				n = n > snap ? snap : n;
			}
			
			
			if(thumb.x<0){
				thumb.x = 0;
			}
			if(thumb.x > trackW){
				thumb.x = trackW;
			}
			mX = view.mouseX;
			
			_value = thumb.x/trackW;
			_value = min + _value*(max-min);
			if(calibration < 2){ 
				view.valueTf.text = int(_value);
				this.dispatchEvent(new WslEvent(VALUE_CHANGE, _value));
			}else{
				if(n != calibrationValue){
					calibrationValue = n;
					view.valueTf.text = int(_value);
					if(calibrationLabelVec != null){
						valueTf.text = calibrationLabelVec[n];
						valueTf.width = valueTf.textWidth+10;
					}
					this.dispatchEvent(new WslEvent(VALUE_CHANGE, n));
				}
			}
		}
		
		private function stageUpHandler(e:MouseEvent):void{
			view.stage.removeEventListener(MouseEvent.MOUSE_MOVE, stageMoveHandler);
			view.stage.removeEventListener(MouseEvent.MOUSE_UP, stageUpHandler);
		}
	}
}