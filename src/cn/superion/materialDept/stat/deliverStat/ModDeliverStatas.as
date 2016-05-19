
import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.materialDept.stat.deliverStat.view.WinDeliverStatQuery;
import cn.superion.materialDept.util.DefaultPage;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.managers.PopUpManager;

//服务类
public const DESTINATION:String='deptDeliverStatImpl';
private const MENU_NO:String="0504";
public var dict:Dictionary=new Dictionary();

/**
 * 初始化窗口
 * */
private function doInit():void
{
	this.parentDocument.title="出库汇总表";
	initToolBar();
}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.imageList1, toolBar.btQuery, toolBar.imageList6, toolBar.btExit];
	var laryEnables:Array=[toolBar.btExit, toolBar.btQuery];
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 打印
 * */
private function printClickHandler(event:Event):void
{
	if(checkUserRole("05"))
	{
		printReport("1");
	}
	else return
}

/**
 * 输出
 * */
private function expClickHandler(event:Event):void
{
	if(checkUserRole("08"))
	{		
		printReport("0");
	}
	else return
}

private function printReport(printSign:String):void
{
	var rawArray:ArrayCollection=gdDeliver.rawDataProvider as ArrayCollection;
	var lastItem:Object=rawArray.getItemAt(rawArray.length - 1);
	var dataList:ArrayCollection=gdDeliver.dataProvider as ArrayCollection;
	
	for (var i:int=0; i < dataList.length; i++)
	{
		var item:Object=dataList.getItemAt(i);
		item["groupName"]=item[gdDeliver.groupField];
	}  
	
	dict["主标题"]="出库汇总表";
	
	dict["单位"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["仓库"]=dataList.getItemAt(0).storageName;
	
	dict["合计"]="合  计 共 "+ dataList.length + " 项";
	
	dict["制单人"]=AppInfo.currentUserInfo.userName;
	
	if (printSign == '1')
	{
		ReportPrinter.LoadAndPrint("report/materialDept/stat/deliverStat.xml", dataList, dict);
	}
	else
	{
		ReportViewer.Instance.Show("report/materialDept/stat/deliverStat.xml", dataList, dict);
	}
}

/**
 * 查找
 * */
private function queryClickHandler(event:Event):void
{
	var queryWin:WinDeliverStatQuery=PopUpManager.createPopUp(this, WinDeliverStatQuery, true) as WinDeliverStatQuery;
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

