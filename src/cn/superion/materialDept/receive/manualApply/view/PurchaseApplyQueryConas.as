// ActionScript file
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialDept.util.MainToolBar;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.List;
import mx.events.CloseEvent;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import spark.events.TextOperationEvent;

public var data:Object={};
public var _dry1:Object={};
private var paramsObj:Object={};
private var destination:String='deptApplyImpl';
public var deptCode1:String="";
public var personId1:String="";
public var materialCodeFrom1:String="";
public var materialCodeTo1:String="";
public var salerCode1:String="";

/**
 * 关闭查询界面
 */ 
public function returnHandler():void
{
	PopUpManager.removePopUp(this);
}

/**
 * 供应商字典
 */ 
protected function productCode_queryIconClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict(function(rev:Object):void
		{
			event.target.text=rev.providerName;
			salerCode1=rev.providerId;
		}, x, y);
}

/**
 * 起始物资编码字典
 */ 
protected function materialCodeFrom_queryIconClickHandler(event:Event):void
{
	//				 TODO Auto-generated method stub
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialDict(function(rev:Object):void
		{
			event.target.text=rev.materialCode;
			materialCodeFrom1=rev.materialCode;
		}, x, y);
}

/**
 * 结束物资编码字典
 */ 
protected function materialCodeTo_queryIconClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialDict(function(rev:Object):void
		{
			event.target.text=rev.materialCode;
			materialCodeTo1=rev.materialCode;
		}, x, y);
}
/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{	
}

/**
 * 按回车跳转
 */ 
private function toNextControl(e:KeyboardEvent, fcontrolNext:*):void
{
	if (e.keyCode == Keyboard.ENTER)
	{
		if (fcontrolNext.className == "DropDownList" || fcontrolNext is DropDownList)
		{
			fcontrolNext.openDropDown();
			fcontrolNext.setFocus();
			return;
		}
		if (fcontrolNext.className == "DateField")
		{
			fcontrolNext.open();
			fcontrolNext.setFocus()
			return;
		}
		fcontrolNext.setFocus();
	}
}

/**
 * 查找
 */ 
protected function btQuery_clickHandler(event:Event):void
{
	var fparameter:Object={};
	var params:ParameterObject=new ParameterObject();
	fparameter["manualSign"]="1"
	fparameter["beginBillNo"]=billNoFrom.text;
	fparameter["endBillNo"]=billNoTo.text;
	if (isBillDate.selected == true)
	{
		fparameter["beginBillDate"]=billDateFrom.selectedDate;
		fparameter["endBillDate"]=MainToolBar.addOneDay(billDateTo.selectedDate);
	}
//	if (isBookDate.selected == true)
//	{
//		fparameter["beginAdviceBookDate"]=adviceBookDateFrom.selectedDate;
//		fparameter["endAdviceBookDate"]= MainToolBar.addOneDay(adviceBookDateTo.selectedDate);
//	}
	fparameter["currentStatus"]=currentStatus.selectedItem.currentStatus;
	params.conditions=fparameter;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(destination, function(rev:Object):void
		{
			if(rev.data.length<=0)
			{
				Alert.show("没有相关数据","提示");
				data.parentWin.doInit();
				data.parentWin.clearForm(true,true);
				return;
			}		
			data.parentWin.arrayAutoId=	ArrayCollection(rev.data).toArray();;
			data.parentWin.findRdsById(rev.data[0]);
			setToolBarPageBts(rev.data.length);
		});
	ro.findApplyMasterListByCondition(params);
	returnHandler();
}
/**
 * 设置当前按钮是否显示
 */
private function setToolBarPageBts(flenth:int):void
{
	data.parentWin.toolBar.queryToPreState()
		
	if (flenth < 2)
	{
		data.parentWin.toolBar.btFirstPage.enabled=false
		data.parentWin.toolBar.btPrePage.enabled=false
		data.parentWin.toolBar.btNextPage.enabled=false
		data.parentWin.toolBar.btLastPage.enabled=false
		return;
	}
	data.parentWin.toolBar.btFirstPage.enabled=false
	data.parentWin.toolBar.btPrePage.enabled=false
	data.parentWin.toolBar.btNextPage.enabled=true
	data.parentWin.toolBar.btLastPage.enabled=true
}
protected function stockType_creationCompleteHandler(event:FlexEvent):void
{
	// TODO Auto-generated method stub
	var typeArc:ArrayCollection=BaseDict.buyOperationTypeDict;
	for each (var item:Object in typeArc)
	{
		if (item.operationTypeName == '')
		{
			typeArc.removeItemAt(typeArc.getItemIndex(item))
		}
	}
}