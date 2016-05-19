/**
 *	 出库汇总表查询模块
 *   author: 芮玉红  2011.02.24
 **/

import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialDept.stat.deliverStat.ModDeliverStat;
import cn.superion.materialDept.util.MainToolBar;
import cn.superion.materialDept.util.MaterialDictShower;
import cn.superion.materialDept.util.RdTypeDict;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import spark.events.TextOperationEvent;

private static var _condition:Object={};
//上一级页面
public var parentWin:ModDeliverStat;

/**
 * 初始化
 **/
private function doInit():void
{
	fillCombox();
	fillForm();
	preventDefaultForm();
	billDate.setFocus();	
}

/**
 * 填充下拉框
 * */
private function fillCombox():void
{
	//业务类型
	operationType.dataProvider = new ArrayCollection([{operationType:null,operationTypeName:'全部'},
		{operationType:'202',operationTypeName:'销售出库'},
		{operationType:'209',operationTypeName:'其他出库'}]);
	operationType.textInput.editable=false;

}

/**
 * 填充表单
 * */
private function  fillForm():void{
	FormUtils.fillFormByItem(this,_condition);
	fillTextInputIcon(rdType);
}


private function fillTextInputIcon(fctrl:Object):void{
	fctrl.text=_condition[fctrl.id+"Name"];
}


/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{
	materialClass.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
	
	materialCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
		
	rdType.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
}

/**
 * 出库类别
 * */
protected function rdType_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeliverTypeDict((function(rev:Object):void
	{
		rdType.txtContent.text=_condition['rdTypeName']=rev.rdName;
		_condition['rdType']=rev.rdCode;
	}), x, y);
}

/**
 *物资分类字典
 */
private function materialClass_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialClassDict((function(rev:Object):void
	{
		materialClass.txtContent.text=rev.className;
		_condition['materialClass']=rev.classCode;
	}), x, y);
}

/**
 * 物资档案字典
 * */
private function materialCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialDict((function(rev:Object):void
	{
		materialCode.txtContent.text=rev.materialName;
		_condition['materialCode']=rev.materialCode;
	}), x, y);
}

/**
 * 放大镜键盘事件处理方法
 * */
private function queryIcon_keyUpHandler(event:KeyboardEvent,fcontrolNext:Object):void
{
	FormUtils.textInputIconKeyUpHandler(event,_condition,fcontrolNext);
}

/**
 *查询按钮处理方法
 **/
private function btQuery_clickHandler():void
{
	//业务类型
	_condition['operationType']=operationType.selectedItem ? operationType.selectedItem.operationType : "";
	
	_condition['beginBillDate']=billDate.selected ?beginBillDate.selectedDate : null;
	_condition['endBillDate']=billDate.selected ? MaterialDictShower.addOneDay(endBillDate.selectedDate) : null;
	
	var params:ParameterObject=new ParameterObject();
	params.conditions=_condition;
	PopUpManager.removePopUp(this);
	
	var ro:RemoteObject=RemoteUtil.getRemoteObject(parentWin.DESTINATION, function(rev:Object):void
	{
		setToolBarBts(rev);
		for (var i:int=0; i < rev.data.length; i++)
		{
			var item:Object=rev.data.getItemAt(i);
			item.salerName=item.salerName == null ? "" : item.salerName.substr(0,6);
			item.nameSpec = item.materialName + " "+(item.materialSpec == null ? "" : item.materialSpec)+" "+(item.salerName == null ? "" : item.salerName);
			item.storageName=item.storageCode==null ? "" : ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict,'dept',item.storageCode).deptName;

		}
		var group:Object=btGroup.selectedValue;
		parentWin.gdDeliver.groupField=group;
		parentWin.gdDeliver.dataProvider=rev.data;
	});
	ro.findDeliverStatListByCondition(params);
}

/**
 * 设置当前按钮是否显示
 */
private function setToolBarBts(rev:Object):void
{
	if (rev.data && rev.data.length)
	{
		parentWin.gdDeliver.sumRowLabelText="合计";
		parentWin.toolBar.btPrint.enabled=true;
		parentWin.toolBar.btExp.enabled=true;
	}
	else
	{
		parentWin.gdDeliver.sumRowLabelText="";
		parentWin.toolBar.btPrint.enabled=false;
		parentWin.toolBar.btExp.enabled=false;
	}
}
/**
 * 处理回车键转到下一个控件
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.toNextControl(e,fcontrolNext);
}

/**
 * 关闭事件处理方法
 * */
private function closeWin():void
{
	PopUpManager.removePopUp(this);
}