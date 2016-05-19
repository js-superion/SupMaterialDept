/**
 *	 入库汇总表查询模块
 *   author: 芮玉红  2011.02.24
 **/
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.base.config.AppInfo;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialDept.stat.receiveStat.ModReceiveStat;
import cn.superion.materialDept.util.MaterialDictShower;
import cn.superion.materialDept.util.RdTypeDict;

import mx.collections.ArrayCollection;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import spark.events.TextOperationEvent;

private static var _condition:Object={};
//上一级页面
public var parentWin:ModReceiveStat;	

/**
 * 初始化
 **/
private function doInit():void
{	
	fillCombox();
	fillForm();
	preventDefaultForm();
	
	if(AppInfo.currentUserInfo.deptList && AppInfo.currentUserInfo.deptList.length>0)
	{
		deptCode.dataProvider = AppInfo.currentUserInfo.deptList;
	}
	else
	{
		deptCode.dataProvider = new ArrayCollection([{deptCode:AppInfo.currentUserInfo.deptCode,deptName:AppInfo.currentUserInfo.deptName}]);
	}

}

/**
 * 填充表单
 * */
private function  fillForm():void{
	FormUtils.fillFormByItem(this,_condition);
	fillTextInputIcon(supplyDeptCode);
	fillTextInputIcon(rdType);
}

private function fillTextInputIcon(fctrl:Object):void{
	fctrl.text=_condition[fctrl.id+"Name"];
}
/**
 * 填充下拉框
 * */
private function fillCombox():void
{
	//业务类型
	operationType.dataProvider = new ArrayCollection([{operationType:null,operationTypeName:'全部'},
		{operationType:'107',operationTypeName:'领用入库'},
		{operationType:'109',operationTypeName:'其他入库'}]);
	operationType.textInput.editable=false;
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
		
	supplyDeptCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
		
	rdType.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
}

/**
 * 入库类别
 **/ 
protected function rdType_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showReceiveTypeDict(function(item:Object):void
	{
		rdType.txtContent.text=item.rdName;
		_condition['rdTypeName']=item.rdName;
		_condition['rdType']=item.rdCode;
	}, x, y);
}

/**
 *供应单位档案字典
 */
private function supplyDeptCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict((function(rev:Object):void
	{
		_condition['supplyDeptCodeName']=supplyDeptCode.txtContent.text=rev.deptName;
		_condition['supplyDeptCode']=rev.deptCode;
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
 *查询按钮处理方法
 **/
private function btQuery_clickHandler():void
{	
	//业务类型
	_condition['operationType']=operationType.selectedItem ? operationType.selectedItem.operationType : "";

	_condition['beginBillDate']=billDate.selected ? beginBillDate.selectedDate : null;
	_condition['endBillDate']=billDate.selected ? MaterialDictShower.addOneDay(endBillDate.selectedDate) : null;
	
	parentWin.dict["入库类别"]=rdType.txtContent.text;
	
	if (billDate.selected)
	{
		parentWin.dict["日期范围"]="从" + beginBillDate.text + "到" + endBillDate.text + "日";
	}
	
	var params:ParameterObject=new ParameterObject();
	params.conditions=_condition;
	PopUpManager.removePopUp(this);
	
	var ro:RemoteObject=RemoteUtil.getRemoteObject(parentWin.DESTINATION, function(rev:Object):void
	{
		setToolBarBts(rev);
		var group:Object=btGroup.selectedValue;
		parentWin.gdReceiveSat.groupField=group;
		parentWin.gdReceiveSat.dataProvider=rev.data;
	});
	ro.findReceiveStatListByCondition(params);
}


/**
 * 设置当前按钮是否显示
 */
private function setToolBarBts(rev:Object):void
{
	if (rev.data && rev.data.length)
	{
		parentWin.gdReceiveSat.sumRowLabelText="合计";
		parentWin.toolBar.btPrint.enabled=true;
		parentWin.toolBar.btExp.enabled=true;
	}
	else
	{
		parentWin.gdReceiveSat.sumRowLabelText="";
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
 * 放大镜键盘事件处理方法
 * */
private function queryIcon_keyUpHandler(event:KeyboardEvent,fcontrolNext:Object):void
{
	FormUtils.textInputIconKeyUpHandler(event,_condition,fcontrolNext);
}

/**
 * 关闭事件处理方法
 * */
private function closeWin():void
{
	PopUpManager.removePopUp(this);
}