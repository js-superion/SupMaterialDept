/**
 *	高值耗材入库查询查询条件窗体
 *	author:芮玉红
 *  checked by：
 **/

import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialDept.util.MainToolBar;
import cn.superion.materialDept.util.MaterialDictShower;

import mx.collections.ArrayCollection;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

public var parentWin:*;

private var _destination:String="deptReceiveValueImpl";
private var paramsObj:Object={};
private var salerClass:String="";

protected function doInit():void
{

	salerCode.txtContent.editable=false;
	personId.txtContent.editable=false;
	
	salerClass=ExternalInterface.call("getSalerClass");
}

/**
 * 处理回车键转到下一个控件
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.toNextControl(e, fcontrolNext);
}



protected function salerCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	MaterialDictShower.showProviderDict(function(item:Object):void
	{
		salerCode.txtContent.text=item.providerName;
		paramsObj['salerCode']=item.providerId;
	}, x, y,null,salerClass,false); 
}

protected function personId_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict(function(item:Object):void
	{
		personId.txtContent.text=item.personIdName;
		paramsObj['personId']=item.personId;
	}, x, y);
}



/**
 * 取消按钮事件响应方法
 * */
protected function closeWin():void
{
	PopUpManager.removePopUp(this);
}



protected function btConfirm_clickHandler(event:MouseEvent):void
{
	var params:Object={};

	params["storageCode"]="V"+AppInfo.currentUserInfo.deptCode;
	
	if (paramsObj['salerCode'])
	{
		params['salerCode']=paramsObj['salerCode'];
	}
	if (paramsObj['deptCode'])
	{
		params['deptCode']=paramsObj['deptCode'];
	}
	if (paramsObj['personId'])
	{
		params['personId']=paramsObj['personId'];
	}


	if (currentStatus.selectedItem)
	{
		params['currentStatus']=currentStatus.selectedItem.currentStatus;
	}
	if (billDate.selected)
	{
		params['beginBillDate']=beginBillDate.selectedDate;
		params['endBillDate']=MainToolBar.addOneDay(endBillDate.selectedDate);
	}
	else
	{
		params['beginBillDate']=null;
		params['endBillDate']=null;
	}

	var paramsQuery:ParameterObject=new ParameterObject();
	paramsQuery.conditions=params;

	var ro:RemoteObject=RemoteUtil.getRemoteObject(_destination, function(rev:Object):void
	{
		if (rev.data && rev.data.length > 0)
		{
			parentWin.arrayAutoId=ArrayCollection(rev.data).toArray();

			parentWin.findRdsById(rev.data[0]);

			setToolBarPageBts(rev.data.length);
		}
		else
		{
			parentWin.doInit();
			//清空当前表单
			parentWin.clearForm(true, true);
		}
	});
	ro.findRdsMasterListByCondition(paramsQuery);
	PopUpManager.removePopUp(this);
}

/**
 * 设置当前按钮是否显示
 */
private function setToolBarPageBts(flenth:int):void
{
	parentWin.toolBar.queryToPreState()

	if (flenth < 2)
	{
		parentWin.toolBar.btFirstPage.enabled=false
		parentWin.toolBar.btPrePage.enabled=false
		parentWin.toolBar.btNextPage.enabled=false
		parentWin.toolBar.btLastPage.enabled=false
		return;
	}
	parentWin.toolBar.btFirstPage.enabled=false
	parentWin.toolBar.btPrePage.enabled=false
	parentWin.toolBar.btNextPage.enabled=true
	parentWin.toolBar.btLastPage.enabled=true
}

/**
 * 取消
 */
protected function btReturn_clickHandler(event:MouseEvent):void
{
	PopUpManager.removePopUp(this);
}