package wsl.manager
{
	import flash.display.DisplayObject;
	import flash.display.IBitmapDrawable;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.system.ApplicationDomain;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	public class DefinitionManager extends Sprite {
		static public var loadInfo:LoaderInfo;
		
		static private var resDomain:ApplicationDomain;
		static private var lobbyDomain:ApplicationDomain;
		static private var appDomain:ApplicationDomain;
		
		public function DefinitionManager():void {
		}
		
		static public function hasDefinition(obj:Object):Class{
			if (obj is DisplayObject) {
				return (obj as Class);
			}
			if (obj is String) {
				try {
					return getDefinitionByName(String(obj)) as Class;
				} catch (err:Error) {
					try {
						return obj.loaderInfo.applicationDomain.getDefinition(String(obj)) as Class;
					} catch (err:Error) {
					}
				}
			} else {
				try {
					return getDefinitionByName(getQualifiedClassName(obj)) as Class;
				} catch (e:Error) {
					try {
						return obj.loaderInfo.applicationDomain.getDefinition(getQualifiedClassName(obj)) as Class;
					} catch (e:Error) {
					}
				}
			}
			
			return null;
		}
		
		static public function getDefinition(obj:Object):Class {
			
			if (obj is DisplayObject) {
				return (obj as Class);
			}
			if (obj is String) {
				try {
					return getDefinitionByName(String(obj)) as Class;
				} catch (err:Error) {
					try {
						return obj.loaderInfo.applicationDomain.getDefinition(String(obj)) as Class;
					} catch (err:Error) {
					}
				}
			} else {
				try {
					return getDefinitionByName(getQualifiedClassName(obj)) as Class;
				} catch (e:Error) {
					try {
						return obj.loaderInfo.applicationDomain.getDefinition(getQualifiedClassName(obj)) as Class;
					} catch (e:Error) {
					}
				}
			}
			
			throw Error(obj.toString()+" can not find !");
			return null;
		}
		
		static public function getDefinitionInstance(obj:*):IBitmapDrawable {
			if (obj is Class) {
				return (new obj()) as DisplayObject;
			} else if (obj is DisplayObject) {
				(obj as DisplayObject).x = 0;
				(obj as DisplayObject).y = 0;
				return obj as DisplayObject;
			}
			
			var classDef:Class = getDefinition(obj);
			
			if (classDef == null) {
				return null;
			}
			return (new classDef()) as IBitmapDrawable;
		}
		
		static public function getDefinitionInstanceAt(obj:*):IBitmapDrawable {
			if(loadInfo == null){
				throw new Error("在调用DefinitionManager.getDefinitionInstanceAt()方法前，必须设置DefinitionManager.loadInfo此属性。");
			}
			return new (loadInfo.applicationDomain.getDefinition(String(obj)) as Class);
		}
	}
}