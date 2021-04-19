package wsl.interfaces{
	
	/** 需要接受键盘事件的视图类实现此接口， */
	public interface IKey{
		/** 当键盘按下时调用 */
		function keyDownHandler(keyCode:int):void;
		/** 当键盘释放时调用 */
		function keyUpHandler(keyCode:int):void;
	}
}