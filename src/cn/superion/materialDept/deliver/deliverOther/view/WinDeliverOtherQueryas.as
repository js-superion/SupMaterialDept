/** 
 *		 其他出库模块---查询窗体  
 *		 author:邢树斌  2011.02.29
 *		 checked by 
 **/
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialDept.deliver.deliverOther.ModDeliverOther;
import cn.superion.materialDept.util.MainToolBar;
import cn.superion.materialDept.util.MaterialDictShower;
import cn.superion.materialDept.util.RdTypeDict;

import flexlib.scheduling.util.DateUtil;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

public var iparentWin:ModDeliverOther;
private var _aryEnableds:Array=[];
//查询条件对象
private static var _condition:Object={};

/**
 * 初始化
 * */
private function doInit():void
{
	fillCombo();
	fillForm();
}

/**
 * 填充表单
 * */
private function fillForm():void{	
	FormUtils.fillFormByItem(this,_condition);
	storage.text=AppInfo.currentUserInfo.deptName
}

/**
 * 返回主页面
 * */
protected function returnHandler():void
{
	PopUpManager.removePopUp(this);
}

/**
 * 查询事件响应方法
 * */
protected function btQuery_clickHandler(event:MouseEvent):void
{
	var paramQuery:ParameterObject=new ParameterObject();
	_condition["beginBillDate"]=beginBillDate.selectedDate;
	_condition["endBillDate"]=MaterialDictShower.addOneDay(endBillDate.selectedDate);
	_condition["rdType"]=rdType.selectedItem.deliverType;
	_condition["storageCode"]=AppInfo.currentUserInfo.deptCode;
	_condition["billNo"]=billNo.text;
	_condition["materialCode"]=materialCode.text;
	_condition["currentStatus"]=currentStatus.selectedItem.currentStatus;
	paramQuery.conditions=_condition;
	PopUpManager.removePopUp(this);
	var ro:RemoteObject=RemoteUtil.getRemoteObject("deptOtherDeliverImpl", function(rev:Object):void
	{
		if (rev.data.length <= 0)
		{
			Alert.show("没有相关数据", "提示");
			iparentWin.doInit();
			iparentWin.clearForm(true, true);
			returnHandler();
			return;
		}
		iparentWin.arrayAutoId=ArrayCollection(rev.data).toArray();
		iparentWin.findRdsById(rev.data[0]);
		setToolBarPageBts(rev.data.length);
		returnHandler();
	})
	ro.findOtherMasterListByCondition(paramQuery);
	return;
}
/**
 * 设置当前按钮是否显示
 */
private function setToolBarPageBts(flenth:int):void
{
	iparentWin.toolBar.queryToPreState()
	
	if (flenth < 2)
	{
		iparentWin.toolBar.btFirstPage.enabled=false
		iparentWin.toolBar.btPrePage.enabled=false
		iparentWin.toolBar.btNextPage.enabled=false
		iparentWin.toolBar.btLastPage.enabled=false
		return;
	}
	iparentWin.toolBar.btFirstPage.enabled=false
	iparentWin.toolBar.btPrePage.enabled=false
	iparentWin.toolBar.btNextPage.enabled=true
	iparentWin.toolBar.btLastPage.enabled=true
}
/**
 * 处理回车键转到下一个控件
 * */
protected function keyUpCtrl(e:KeyboardEvent, ctrl:Object):void
{
	FormUtils.toNextControl(e,ctrl);
}

/**
 * 物资字典
 * */
protected function materialCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialDict(function(rev:Object):void
	{
		materialName.text=rev.materialName;
		_condition.materialName=rev.materialName;
		materialCode.text=rev.materialCode;
	});
}

/**
 * 填充下拉框
 * */
private function fillCombo():void{
	rdType.dataProvider=RdTypeDict.deliverTypeDict;
	rdType.selectedIndex=3;
}