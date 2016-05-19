package cn.superion.materialDept.util
{
	import cn.superion.base.util.LoadModuleUtil;

	import mx.core.FlexGlobals;
	import mx.modules.ModuleLoader;

	public class DefaultPage
	{
		public function DefaultPage()
		{
		}

		//回到缺省主页面，供各分模块中的返回调用
		public static function gotoDefaultPage():void
		{
			var url:String='cn/superion/materialDept/main/view/ModMainRight.swf';
			LoadModuleUtil.loadCurrentModule(ModuleLoader(FlexGlobals.topLevelApplication.mainWin.mainFrame), url, FlexGlobals.topLevelApplication.mainWin.modPanel);
		}
	}
}