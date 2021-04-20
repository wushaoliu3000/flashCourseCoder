package wsl.core{
	/** 定义用户类型的静态常量 */
	public class UserType{
		/** 管理员 */
		static public const ADMIN:String = "管理员";
		/** 店长 */
		static public const MANAGER:String = "店长";
		/** 厨师 */
		static public const CHEF:String = "厨师";
		/** 服务员 */
		static public const WAITER:String = "服务员";
		/** 收银员 */
		static public const CASHIER:String = "收银员 ";
		/** 食客*/
		static public const GUEST:String = "食客";
		
		
		/** 用户登录验证时用，密码错误  pwdWrong */
		static public const PWD_WRONG:String = "pwdWrong";
		/** 用户登录验证时用，用户不存在  noUser */
		static public const NO_USER:String = "noUser";
		/** 用户已经在线 nowOnline*/
		static public const NOW_ONLINE:String = "nowOnline";
		/** 已经有管理员登录，一次只能有一个管理员登录 */
		static public const ADMIN_EXSIT:String = "adminExsit";
	}
}