package wsl.core{
	public interface IView{
		function setSize(w:Number, h:Number):void;
		function move(px:Number, py:Number):void;
		function destroy():void;
	}
}