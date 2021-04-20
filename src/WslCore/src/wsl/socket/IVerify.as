package wsl.socket
{
	/**验证Socket连接上来的用户，保存超级管理员修改过的用户配置*/
	public interface IVerify{
		/** 验证Socket连接上来的用户，返回一个用户级别<br>
		 * 通过验证后，用户状态设为在线<br>
		 * 参数name=""与 password="" 表示食客登录。<br>
		 * @return
		 * 返回一个表示用户类型的字符串，返回类型在UserType中定义<br>
		 * guest 游客<br>
		 * wrongPassword 表示密码错误。<br>
		 * noUser 表示用户不存在。 */ 
		function verifyUser(name:String, password:String):String;
		
		/** 当有用户下线时，修改用户的在线状态 */
		function userDownline(name:String):void;
		
		/** 验证连接的IP来源 */
		function verifyIP():Boolean;
	}
}