/**
 *	 报损单据列表查询模块
 *   author: 芮玉红  2011.02.24
 **/
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialDept.list.rejectList.ModRejectList;
import cn.superion.materialDept.util.MaterialDictShower;

import com.adobe.utils.StringUtil;

import flash.events.Event;
import flash.events.KeyboardEvent;

import mx.collections.ArrayCollection;
import mx.managers.PopUpManager;


import spark.events.TextOperationEvent;

public var parentWin:ModRejectList;
//条件对象
private static var _condition:Object={};

/**
 * 初始化
 * */
protected function doInit():void
{
	fillForm();
	preventDefaultForm();
	beginBillNo.setFocus();	
	currentStatus.textInput.editable=false;
}

/**
 * 填充表单
 * */
private function  fillForm():void{
	FormUtils.fillFormByItem(this,_condition);
	fillTextInputIcon(factoryCode);
	fillTextInputIcon(outDeptCode);
}

private function fillTextInputIcon(fctrl:Object):void{
	fctrl.text=_condition[fctrl.id+"Name"];
}

/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{
	beginMaterialCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
		
	endMaterialCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
		
	personId.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
	
	outDeptCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
	factoryCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
}

/**
 * 物资档案字典
 * */
private function materialCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialDict((function(rev:Object):void
	{
		event.target.txtContent.text=rev.materialName;
		_condition[event.target.id]=rev.materialCode;
	}), x, y);
}

/**
 *部门档案字典
 */
private function deptCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict((function(rev:Object):void
	{
		outDeptCode.txtContent.text=rev.deptName;
		_condition['outDeptCode']=rev.deptCode;
		_condition['outDeptCodeName']=rev.deptName;
	}), x, y);
}

/**
 * 人员(经手人)档案字典
 * */
private function personId_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict((function(rev:Object):void
	{
		personId.txtContent.text=rev.personIdName;
		_condition['personId']=rev.personId;
	}), x, y);
}

/**
 *生产厂家字典
 */
private function factoryCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict((function(rev:Object):void
	{
		factoryCode.txtContent.text=rev.providerName;
		_condition['factoryCode']=rev.providerId;
		_condition['factoryCodeName']=rev.providerName;
	}), x, y);
}

/**
 * 确认查询事件处理方法
 * */
private function btQuery_clickHandler():void
{
	var paramQuery:ParameterObject=new ParameterObject();
	//报损单号	
	_condition['beginBillNo']=beginBillNo.text;
	_condition['endBillNo']=endBillNo.text;
	
	makeEmptyValueSame(_condition, 'beginBillNo', 'endBillNo');
	makeEmptyValueSame(_condition, 'beginMaterialCode', 'endMaterialCode');
	
    //报损日期
	_condition['beginBillDate']=billDate.selected ? beginBillDate.selectedDate : null;
    _condition['endBillDate']=billDate.selected ? MaterialDictShower.addOneDay(endBillDate.selectedDate): null;
		
	parentWin.dict["报损部门"]=outDeptCode.txtContent.text;
	if (billDate.selected)
	{
		parentWin.dict["日期范围"]="从 " + beginBillDate.text + " 到 " + endBillDate.text;
	}
	//当前状态
	_condition['currentStatus']=currentStatus.selectedItem ? currentStatus.selectedItem.currentStatus : "";
	
	paramQuery.conditions=_condition;
	closeWin();
	parentWin.gdRejectList.reQuery(paramQuery);
}

/**
 * 范围值有一个为空时，取另一个值
 * */
private function makeEmptyValueSame(fconditon:Object, fstrFieldStart:String, fstrFieldEnd:String):void
{
	if (fconditon[fstrFieldStart] == '')
	{
		fconditon[fstrFieldStart]=fconditon[fstrFieldEnd];
	}
	if (fconditon[fstrFieldEnd] == '')
	{
		fconditon[fstrFieldEnd]=fconditon[fstrFieldStart];
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
 * 处理确定按钮的回车事件
 * */
private function btConfirm_keyUpHandler(event:KeyboardEvent):void
{
	if (event.keyCode == Keyboard.ENTER)
	{
		btQuery_clickHandler();
	}
}

/**
 * 关闭事件处理方法
 * */
private function closeWin():void
{
	PopUpManager.removePopUp(this);
}