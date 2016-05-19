package cn.superion.materialDept.util
{
	import cn.superion.base.config.BaseDict;
	import cn.superion.base.config.SimpleDictWinConfig;
	import cn.superion.base.util.RemoteUtil;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import flexlib.scheduling.util.DateUtil;
	
	import mx.collections.ArrayCollection;
	import mx.core.FlexGlobals;
	import mx.managers.PopUpManager;
	import mx.rpc.remoting.RemoteObject;

	public class MaterialDictShower
	{
		public static var isDictWinShow:Boolean=false;
		private static var isHidden:Boolean = false;
		public static var SYS_UNITS:ArrayCollection = null;
		//是否加载多个单位下的基础字典 ryh 13.01.21，泰州需要加载
		public static var isAllUnitsDict:Boolean=false;
		
		/**
		 * 显示批号选择对话框
		 * 用法：MaterialDictShower.showBatchNoChooser("123","234","123",function(it){})
		 * */
		public static function showBatchNoChooser(fmaterialId:String,fstorageCode:String,fbatch:String,callback:Function, x:int=-1, y:int=-1):void
		{
			var config:SimpleDictWinConfig=new SimpleDictWinConfig();
			config.destination='deptCommMaterialServiceImpl';
			config.method="findCurrentStockByFactoryBatch";
			
			config.gridDataFields=["materialCode", "materialName","materialSpec","materialUnits","tradePrice","amount","factoryName","madeDate","batch","availDate"];
			config.gridHeadTexts=["物资编码","物资名称","规格型号","单位","进价","现存量","生产企业","生产日期","批号","有效期至"];
			config.gridDataQueryOption=[{label: '批号', field: 'batch',value:fbatch}];
			config.typeName="批号查询";
			config.baseCondition={materialId:fmaterialId,storageCode:fstorageCode}
			config.widths=[1.3,2,1.2,1,1,1,3,1.5,1,1.5];
			config.initQueryValue=fbatch
//			config.formats=[,,,,'0.00','0.00'];
			config.callback=callback;
			var win:SimpleDictWin1=SimpleDictWin1(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), SimpleDictWin1));
			win.height=340;
			win.width=896;
			win.dictWinConfig=config;
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
		
		public static function showBatchNoChooser2(fmaterialId:String,fstorageCode:String,fbatch:String,callback:Function, x:int=-1, y:int=-1):void
		{
			var config:SimpleDictWinConfig=new SimpleDictWinConfig();
			config.destination='commMaterialServiceImpl';
			config.method="findCurrentStockByFactoryBatch";
			
			config.gridDataFields=["materialCode", "materialName","materialSpec","materialUnits","tradePrice","amount","factoryName","madeDate","batch","availDate"];
			config.gridHeadTexts=["物资编码","物资名称","规格型号","单位","进价","现存量","生产企业","生产日期","批号","有效期至"];
			config.gridDataQueryOption=[{label: '批号', field: 'batch',value:fbatch}];
			config.typeName="批号查询";
			config.baseCondition={materialId:fmaterialId,storageCode:fstorageCode}
			config.widths=[1.3,2,1.2,1,1,1,3,1.5,1,1.5];
			config.initQueryValue=fbatch
			//			config.formats=[,,,,'0.00','0.00'];
			config.callback=callback;
			var win:SimpleDictWin1=SimpleDictWin1(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), SimpleDictWin1));
			win.height=340;
			win.width=896;
			win.dictWinConfig=config;
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
		public static function addOneDay(date:Date):Date{
			//
			return flexlib.scheduling.util.DateUtil.addTime(new Date(date),flexlib.scheduling.util.DateUtil.DAY_IN_MILLISECONDS - 1000);
		}
		/**
		 * 显示物品包对话框
		 * 用法：MaterialDictShower.showCssdPackageDictChooser(function(it){})
		 * */
		public static function showCssdPackageDictChooser(callback:Function, x:int=-1, y:int=-1):void
		{
			var config:SimpleDictWinConfig=new SimpleDictWinConfig();
			config.destination='commCssdServiceImpl';
			config.method="findCssdPackageByIntputCode";
			config.gridDataFields=["packageId", "packageName"];
			config.gridHeadTexts=["物品包编码","物品包名称"];
			config.typeName="物品包查询";
			config.widths=[1,2];
			config.callback=callback;
			var win:SimpleDictWin=SimpleDictWin(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), SimpleDictWin));
			win.height=340;
			win.width=896;
			win.dictWinConfig=config;
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
		/**
		 * 显示物品包对话框
		 * 用法：MaterialDictShower.showCssdPackageDictChooser(function(it){})
		 * */
		public static function showCssdPackageDictChooser1(callback:Function, x:int=-1, y:int=-1):void
		{
			var config:SimpleDictWinConfig=new SimpleDictWinConfig();
			config.destination='commCssdServiceImpl';
			config.method="findCssdPackageByIntputCode1";
			config.gridDataFields=["packageNo", "packageName"];
			config.gridHeadTexts=["编号","名称",];
			config.typeName="物品包查询";
			config.widths=[1,2];
			config.callback=callback;
			var win:SimpleDictWin1=SimpleDictWin1(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), SimpleDictWin1));
			win.height=340;
			win.width=896;
			win.dictWinConfig=config;
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
		//
		/**
		 * 
		 * */
		public static function showMaterialDictNew(fstrStorageCode:String, fstrFixedSign:String, fstrCssdSign:String, fbStockAmountVisible:Boolean, callback:Function, x:int=-1, y:int=-1,fIsZeroDeliver:Boolean=true):void
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
			
			var ro:RemoteObject=RemoteUtil.getRemoteObject('centerSysParamImpl', function(rev:Object):void
			{
				if (rev.data && rev.data[0] == '1')
				{
					isHidden=false; 
				}
				else{
					isHidden=true; 
				}
				var win:MaterialDictWin=MaterialDictWin(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), MaterialDictWin, true));
				win.storageCode=fstrStorageCode;
				win.fixedSign=fstrFixedSign;
				win.cssdSign=fstrCssdSign;
				win.stockAmountVisible=fbStockAmountVisible;
				win.isZeroDeliver=fIsZeroDeliver;
				win.isHidden = isHidden;
				
				win.callback=callback
				if (x == -1)
				{
					PopUpManager.centerPopUp(win);
				}
				else
				{
					win.x=x;
					win.y=y;
				}
				
			});
			ro.findSysParamByParaCode("0606");
		}
		
		/**
		 * 显示物资名称字典
		 * */
		public static function showMaterialDict(fstrStorageCode:String,callback:Function, x:int=-1, y:int=-1):void
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
			var config:SimpleDictWinConfig=new SimpleDictWinConfig();
			config.destination='materialCommonDictImpl';
			config.method="findByInputCode";
			config.serverOrderField="materialCode";
			config.entityClassName="cn.superion.center.material.entity.CdMaterialDict";
			
			config.gridDataFields=["materialCode", "materialName", "materialSpec", "materialUnits", "factoryName"];
			config.gridHeadTexts=["物资编码", "物资名称", "规格型号", "单位", "生产厂家"];
			config.gridDataQueryOption=[{label: '拼音简码', field: 'phoInputCode'}, {label: '五笔简码', field: 'fiveInputCode'}];
			config.typeName="物资";
			config.baseCondition={storageCode: fstrStorageCode}
			config.widths=[1.5, 4, 3, 1, 4];
			config.callback=callback;
			var win:SimpleDictWin1=SimpleDictWin1(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), SimpleDictWin1, true));
			win.height=340;
			win.width=726;
			win.dictWinConfig=config;
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
		
		/**
		 * 显示收发类别显示；这里显示的rdFlag 为 1 即：所有入库的分类；
		 * 用法：MaterialDictShower.showReceiveTypeDict(function(it){})
		 * */
		public static function showReceiveTypeDict(callback:Function, x:int=-1, y:int=-1):void
		{
			var config:SimpleDictWinConfig=new SimpleDictWinConfig();
			config.destination='commMaterialServiceImpl';
			config.method="findOperationTypeByCondition";
			config.gridDataFields=["rdCode", "rdName"];
			config.gridHeadTexts=["编码","名称"];
			config.typeName="入库类别查询";
			config.baseCondition = {'rdFlag':"1"};
			config.widths=[1,2];
			config.callback=callback;
			var win:SimpleDictWin=SimpleDictWin(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), SimpleDictWin));
			win.height=340;
			win.width=500;
			win.dictWinConfig=config;
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
		
		
		/**
		 * 显示高值耗材类物资字典
		 * */
		public static function showMaterialValueDict(callback:Function, x:int=-1, y:int=-1):void
		{
			var win:MaterialValueDictWin=MaterialValueDictWin(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), MaterialValueDictWin));
			win.highValueSign='1';
			win.agentSign='1'; 
			win.callback=callback
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
		  
		/**
		 * 显示供应单位字典
		 * */
		public static function showProviderDict(callback:Function, x:int=-1, y:int=-1,fstrChargeDept:String=null,fstrProviderClass:String=null,isShareObj:Boolean=true):void
		{
			var config:SimpleDictWinConfig=new SimpleDictWinConfig();
			config.baseCondition={providerChargeDept:fstrChargeDept,providerClass:fstrProviderClass}
			config.destination='commMaterialDictImpl';
			config.method="findByInputCodeExt";
			config.serverOrderField="providerCode";
			config.entityClassName="cn.superion.center.provider.entity.CdProvider";
			
			config.gridDataFields=["providerCode", "providerName"];
			config.gridHeadTexts=["单位编码", "单位名称"];
			config.gridDataQueryOption=[{label: '拼音简码', field: 'phoInputCode'}, {label: '五笔简码', field: 'fiveInputCode'}];
			config.typeName="往来单位";
			config.widths=[1, 4];
			
			if(isAllUnitsDict && MaterialDictShower.isAllUnitsDict)
			{
				config.comboxData = SYS_UNITS.toArray();
				config.comboxLableField="unitsSimpleName"
				config.comboxFormItemLable="单位";
			}
			
			
			config.callback=callback;
			
			var win:SimpleDictWin=SimpleDictWin(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), SimpleDictWin, true));
			win.isShareObj=isShareObj;
			win.height=340;
			win.width=726;
			win.dictWinConfig=config;
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
		
		
		public static function getAdvanceDictList():void
		{
			var ro:RemoteObject=RemoteUtil.getRemoteObject('materialCommonDictImpl', function(rev:Object):void
			{
				fillAdvanceDict(rev.data[0]);
			})
			ro.findAdvanceDict();
		}
		
		private static function fillAdvanceDict(data:Object):void
		{
			for (var field:String in data)
			{
				BaseDict[field + 'Dict']=data[field];
			}
		}
	}
	
}