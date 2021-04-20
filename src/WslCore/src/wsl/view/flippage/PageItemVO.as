package wsl.view.flippage{
	public class PageItemVO{
		/**  通过此id可以在FlipPageView类中的itemVec中找到本身 */
		public var id:int;
		/** 此实例的名字 */
		public var label:String;
		/** 此实例要显示器的头像 */
		public var thumb:String;
		/** 保存此实例关联的信息的连接地址 */
		public var url:String;
		/** 类型，如：男、女等分类信息 */
		public var type:int;
		/** 让实例thumb图片显示不同的轮廓 */
		public var maskType:int;
		/** 是否在线 */
		public var isOnline:Boolean;
		/** 是否选择 */
		public var isSelected:Boolean;
	}
}