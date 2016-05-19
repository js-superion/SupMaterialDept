
import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.materialDept.stat.expiryAlarm.view.WinExpiryAlarmQuery;
import cn.superion.materialDept.util.DefaultPage;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.managers.PopUpManager;

//服务类
public const DESTINATION:String='deptAvailDateImpl';
private const MENU_NO:String="0506";
//以下变量用于报表
public var materialClass:String = null;//对应查询框中的物资类别
public var selectedRdoName:String = null;//选中按钮对应的label
public var selectedRdoValue:String = null;//选中按钮对应的值

/**
 * 初始化
 * */
private function doInit():void
{
	this.parentDocument.title="保质期预警";
	initToolBar();
}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.imageList1, toolBar.btQuery, toolBar.imageList6, toolBar.btExit];
	var laryEnables:Array=[toolBar.btExit, toolBar.btQuery, toolBar.btAdd]
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 打印
 */
private function printClickHandler(event:Event):void
{
	if(checkUserRole('05'))
	{
		printReport("1");
	}
	else return
}

/**
 * 输出
 */
private function expClickHandler(event:Event):void
{
	if(checkUserRole('08'))
	{
		printReport("0");
	}
	else return
}

private function printReport(printSign:String):void
{
	var dataList:ArrayCollection=dgAvailDate.dataProvider as ArrayCollection;
	var lastItem:Object=dataList.getItemAt(dataList.length - 1);
	preparePrintData(dataList);
	var dict:Dictionary=new Dictionary();
	
	dict["主标题"]="保质期预警表";
	
	dict["单位"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	
	dict["仓库"] = dataList.getItemAt(0).storageName;
	
	dict["物资类型"] = materialClass == null ? "" : materialClass;
	dict["selectedRadioName"]= selectedRdoName == null ? "" : selectedRdoName + ":";
	dict["selectedRdoValue"] = selectedRdoValue == null ? "" : selectedRdoValue;
	
	dict["制单人"]=AppInfo.currentUserInfo.userName;
	
	if (printSign == '1')
	{
		ReportPrinter.LoadAndPrint("report/materialDept/stat/expiryAlarm.xml", dataList, dict);	
	}
	else
	{
		ReportViewer.Instance.Show("report/materialDept/stat/expiryAlarm.xml", dataList, dict);	
	}
}

/**
 * 拼装打印数据
 * */
private function preparePrintData(faryData:ArrayCollection):void
{
	for (var i:int=0; i < faryData.length; i++)
	{
		var item:Object=faryData.getItemAt(i);
		item.tradePrice=!item.tradePrice ? '' :item.tradePrice;
		if(item.amount==0 || item.tradePrice==0)
		{
			item.tradePrice=0.00;
		}
		else
		{		
			item.tradeMoney=Number(item.amount *　item.tradePrice).toFixed(2);
		}
		item.madeDate=item.madeDate == null ? "" :item.madeDate;
		item.availDate=item.availDate == null ? "" : item.availDate;
		item.nameSpecFactory = item.materialName + " "+(item.materialSpec == null ? "" : item.materialSpec)+" "+(item.factoryName == null ? "" : item.factoryName.substr(0,6));
	}
} 

/**
 * 查找
 * */
private function queryClickHandler(event:Event):void
{
	var queryWin:WinExpiryAlarmQuery=PopUpManager.createPopUp(this, WinExpiryAlarmQuery, true) as WinExpiryAlarmQuery;
	queryWin.parentWin=this;
	FormUtils.centerWin(queryWin);
}

/**
 * 当前角色权限认证
 */
private function checkUserRole(role:String):Boolean
{
	//判断具有操作权限  -- 应用程序编号，菜单编号，权限编号
	// 01：增加                02：修改            03：删除
	// 04：保存                05：打印            06：审核
	// 07：弃审                08：输出            09：输入
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO,role))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return false;
	}
	return true;
}

/**
 * 退出
 * */
private function exitClickHandler(event:Event):void
{
	if (this.parentDocument is WinModual)		
	{
		PopUpManager.removePopUp(this.parentDocument as IFlexDisplayObject);
		return;
	}
	DefaultPage.gotoDefaultPage();
}
