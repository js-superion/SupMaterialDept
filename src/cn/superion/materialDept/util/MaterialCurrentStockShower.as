package cn.superion.materialDept.util
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.core.FlexGlobals;
	import mx.managers.PopUpManager;

	public class MaterialCurrentStockShower
	{
		public static var isDictWinShow:Boolean=false;

		public static function showCurrentStock(fstrStorageCode:String, fstrMaterialId:String, fstrBatch:String, callback:Function, x:int=-1, y:int=-1):void
		{
			if (isDictWinShow)
			{
				return
			}
			isDictWinShow=true
			var timer:Timer=new Timer(1000, 1)
			timer.addEventListener(TimerEvent.TIMER, function(e:Event):void
			{
				isDictWinShow=false
			})
			timer.start();

			var win:WinCurrentStockBatch=WinCurrentStockBatch(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), WinCurrentStockBatch, true));

			win.storageCode=fstrStorageCode;
			win.materialId=fstrMaterialId;
			win.batch=fstrBatch;

			win.callback=callback;

			if (x == -1)
			{
				PopUpManager.centerPopUp(win);
			}
			else
			{
				win.x=x;
				win.y=y;
			}
		}
	}
}