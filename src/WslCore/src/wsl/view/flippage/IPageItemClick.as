package wsl.view.flippage{
	public interface IPageItemClick{
		/** 当分布视图已经选定实例时执行此方法<br>
		 * 当FlipPageView为实例单选时，itemIndex为选择的实例。此时itemVec。为空<br>
		 * 当 FlipPageView为实例多选时，itemVec为选择的一个或多个实例。此时itemIndex为-1。*/
		function pageItemClick(itemIndex:int, itemVec:Vector.<PageItemVO>):void;
	}
}