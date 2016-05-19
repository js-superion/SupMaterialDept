import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.materialDept.receive.receive.ModReceive;
import cn.superion.materialDept.receive.receiveBag.ModReceiveBag;
import cn.superion.materialDept.util.MainToolBar;

import flash.events.Event;

import mx.collections.ArrayCollection;
import mx.events.CollectionEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import spark.components.TextInput;
public  var iparentWin:ModReceive;
//条件对象
private static var _condition:Object={}

/**
 * 初始化
 * */
private function doInit():void
{
	fillCombo();
	fillForm();
	endBillDate.selectedDate = new Date();
}

/**
 * 填充表单
 * */
private function  fillForm():void{
	FormUtils.fillFormByItem(this,_condition);
}

/**
 * 仓库档案、当前状态
 * */
protected function fillCombo():void
{
	storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
	storageCode.selectedIndex=0;
	currentStatus.dataProvider = aryCurrentStatus;
}

/**
 * 确认查询事件处理方法
 * */
protected function btConfirm_clickHandler(event:Event):void
{
	var paramQuery:ParameterObject = new ParameterObject();
	//获取查询条件的值
	_condition = 
		{
			"storageCode":storageCode.selectedItem?storageCode.selectedItem.storageCode:"",
				"deptCode":AppInfo.currentUserInfo.deptCode,
				"beginBillNo":beginBillNo.text == null ? " ":beginBillNo.text,
				"endBillNo":endBillNo.text == null ? " ":endBillNo.text,
				"currentStatus":currentStatus.selectedItem?currentStatus.selectedItem.code:"",
				"beginBillDate":beginBillDate.selectedDate,
				"endBillDate":MainToolBar.addOneDay(endBillDate.selectedDate)
		};
	
	//将查询对象赋给ParameterObject的conditions
	paramQuery.conditions = _condition;
	var ro:RemoteObject = RemoteUtil.getRemoteObject("deptApplyImpl",function (rev:Object):void{
		if(rev.data && rev.data.length > 0){
			iparentWin.arrayAutoId=ArrayCollection(rev.data).toArray();
			iparentWin.findRdsById(rev.data[0]);
			btReturn_clickHandler();
			setToolBarPageBts(rev.data.length);
		}else{
			iparentWin.doInit();
			//清空当前表单
//			FormUtils.clearForm(this);
		}
	});
	ro.findDeliverListByCondition(paramQuery);
	PopUpManager.removePopUp(this);
}

/**
 * 处理回车键转到下一个控件
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.toNextControl(e,fcontrolNext);
}

/**
 * 退出
 * */
protected function btReturn_clickHandler():void
{
	PopUpManager.removePopUp(this);
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
