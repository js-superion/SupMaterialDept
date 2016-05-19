/** 
 *		 其他出库处理模块-过滤窗体
 *		 author:邢树斌  2011.01.19
 *		 checked by 
 **/
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.materialDept.deliver.deliverOther.ModDeliverOther;
import cn.superion.materialDept.util.MaterialDictShower;
import cn.superion.vo.material.MaterialRdsMaster;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

public var data:Object={};

/**
 * 处理键的keyUp事件
 * */
protected function keyUpCtrl(event:KeyboardEvent, ctrl:Object):void
{
	FormUtils.toNextControl(event,ctrl);
}

/**
 * 查询
 * */
protected function btQuery_clickHandler(event:MouseEvent):void
{
	var params:Object=FormUtils.getFields(hg1, []);
	var paramQuery:ParameterObject=new ParameterObject();
	params["storage"]=AppInfo.currentUserInfo.deptCode;
	params["beginBillDate"]=beginBillDate.selectedDate;
	params["endBillDate"]=MaterialDictShower.addOneDay(endBillDate.selectedDate);
	params["operationType"]=operationType.selectedItem.typeCode;
	params["operationNo"]=operationNo.text;
	paramQuery.conditions=params;
	paramQuery.itemsPerPage=5;
	paramQuery.page=1;
	paramQuery.conditions=params;
	var ro:RemoteObject=RemoteUtil.getRemoteObject("deptOtherDeliverImpl", function(rev:Object):void
	{
		if (rev == null || rev.data.length < 1)
		{
			Alert.show("没有检索到相关数据！", "提示信息");
			gridOtherMaster.dataProvider=null;
			gridOtherDetail.dataProvider=null;
			return;
		}
		
		var array:ArrayCollection=(rev.data) as ArrayCollection;
		for (var i:int=0; i < array.length; i++)
		{
			var item:Object=array[i];
			if (item.operationType == "201")
			{
				item.operationType="领用出库";
			}
			else if (item.operationType == "202")
			{
				item.operationType="销售出库";
			}
			else if (item.operationType == "203")
			{
				item.operationType="调拨出库";
			}
			else if (item.operationType == "204")
			{
				item.operationType="盘亏出库";
			}
			else if (item.operationType == "205")
			{
				item.operationType="报损出库";
			}
			else if (item.operationType == "209")
			{
				item.operationType="其他出库";
			}
			item.deptCode=codeToName("dept", item.deptCode, BaseDict.deptDict);
			item.personId=codeToName("personId", item.personId, BaseDict.personIdDict);
		}
		gridOtherMaster.dataProvider=array;
	});
	ro.findRdsMasterOtherByCondition(paramQuery);
	
}

/**
 * 根据编码查找当前字典中的名称
 * */
private function codeToName(columnName:String, columnValue:String, baseDict:ArrayCollection):String
{
	var nameValue:String=columnValue;
	for each (var item:Object in baseDict)
	{
		if (columnValue == item[columnName])
		{
			nameValue=item[columnName + "Name"];
			break;
		}
	}
	return nameValue;
}
/**
 * 填充仓库名称
 * */
private function fillStorageCodeTxt():void
{
	var lobjItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', AppInfo.currentUserInfo.deptCode);
	if (lobjItem)
	{
		AppInfo.currentUserInfo.deptName=lobjItem.deptName
	}
	storage.text=AppInfo.currentUserInfo.deptName;
}

/**
 * 主记录表体单击功能
 * */
protected function gridOtherMaster_clickHandler(event:MouseEvent):void
{
	var obj:Object=gridOtherMaster.selectedItem;
	if (obj == null)
		return;
	if (obj.autoId == null)
		return;
	var ro:RemoteObject=RemoteUtil.getRemoteObject("deptOtherDeliverImpl", function(rev:Object):void
	{
		if (rev == null || rev.data.length < 1)
		{
			Alert.show("没有检索到相关数据！", "提示信息");
			return;
		}
		else
		{
			var array:ArrayCollection=(rev.data) as ArrayCollection;
			for (var i:int=0; i < array.length; i++)
			{
				var item:Object=array[i];
				
				item.factoryCode=codeToName("provider", item.factoryCode, BaseDict.providerDict);
				
			}
			gridOtherDetail.dataProvider=array;
		}
	});
	ro.findRdsDetailByMainAutoId(obj.autoId);
}
/**
 * 确认事件响应方法
 * */
private function btConfirmHandler():void
{
	var lmasterItem:Object=gridOtherMaster.selectedItem;
	if (lmasterItem == null)
	{
		return;
	}
	data.parentWin.findRdsById(lmasterItem.autoId);
	PopUpManager.removePopUp(this);
	return;
}