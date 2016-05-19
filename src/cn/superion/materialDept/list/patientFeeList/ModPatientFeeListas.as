import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.DateUtil;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.materialDept.list.patientFeeList.view.WinPatientFeeListQuery;
import cn.superion.materialDept.util.DefaultPage;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.managers.PopUpManager;

public const DESTINATION:String='deptFeeListImpl';
private const MENU_NO:String="0403";
public var dict:Dictionary=new Dictionary();

/**
 * 初始化
 * */
private function doInit():void
{
	this.parentDocument.title="病人费用列表";
	initPanel();
	initToolBar();
}

/**
 * 初始化面板
 * */
private function initPanel():void
{	
	dgPatientFeeList.grid.sumRowLabelText='合计';
	dgPatientFeeList.grid.horizontalScrollPolicy="on";
	var paramQuery:ParameterObject=new ParameterObject();
	paramQuery.conditions={};
	dgPatientFeeList.config(paramQuery, DESTINATION, 'findFeeDetailListByCondition', function(rev:Object):void
	{
		setToolBarBts(rev);		
	}, null, false);
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
 * 设置工具栏的可用按钮
 */
private function setToolBarBts(rev:Object):void
{
	if (rev.data && rev.data.length)
	{
		toolBar.btPrint.enabled=true;
		toolBar.btExp.enabled=true;
		
		for (var i:int;i<rev.data.length-1;i++)
		{
			var item:Object=rev.data.getItemAt(i);
			
			item.accounterName=item.accounter==null ? "" : ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', item.accounter).personIdName;

			item.wardName=item.wardCode==null ? "" : ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', item.wardCode).deptName;
			
			item.nameSpecFactory=item.materialName + " "+(item.materialSpec == null ? "" : item.materialSpec)+" "+(item.factoryName == null ? "" : item.factoryName);
			item.availDate=item.availDate==null ? "" : DateUtil.dateToString(item.availDate,'YYYY-MM-DD');
		}
	}
	else
	{
		toolBar.btPrint.enabled=false;
		toolBar.btExp.enabled=false;
	}
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
	var dataList:ArrayCollection=dgPatientFeeList.grid.dataProvider as ArrayCollection;
	
	dict["主标题"]="病人费用列表";
	
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	
	dict["制单人"]=AppInfo.currentUserInfo.userName;
	if (printSign == '1')
	{
		ReportPrinter.LoadAndPrint("report/materialDept/list/patientFeeList.xml", dataList, dict);
		
	}
	else
	{
		ReportViewer.Instance.Show("report/materialDept/list/patientFeeList.xml", dataList, dict);
		
	}
}


/**
 * 查找
 * */
private function queryClickHandler(event:Event):void
{
	var queryWin:WinPatientFeeListQuery=PopUpManager.createPopUp(this, WinPatientFeeListQuery, true) as WinPatientFeeListQuery;
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
 *退出
 * */
protected function exitClickHandler(event:Event):void
{
	if (this.parentDocument is WinModual)		
	{
		PopUpManager.removePopUp(this.parentDocument as IFlexDisplayObject);
		return;
	}
	DefaultPage.gotoDefaultPage();				
}
