/**
 *	 病人费用列表查询模块
 *   author: 芮玉红  2011.02.23
 **/
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialDept.list.patientFeeList.ModPatientFeeList;
import cn.superion.materialDept.util.MaterialDictShower;

import com.adobe.utils.StringUtil;

import flash.events.Event;

import mx.collections.ArrayCollection;
import mx.managers.PopUpManager;

import spark.events.TextOperationEvent;

public var parentWin:*;
//条件对象
private static var _condition:Object={};


private function doInit():void
{	
	fillForm();
	inpNo.setFocus();
	preventDefaultForm();
	
}

/**
 * 填充表单
 * */
private function  fillForm():void{
	FormUtils.fillFormByItem(this,_condition);
	fillTextInputIcon(accounter);
	fillTextInputIcon(deptCode);
}

private function fillTextInputIcon(fctrl:Object):void{
	fctrl.text=_condition[fctrl.id+"Name"];
}

/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{	
	deptCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
	
	materialClass.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
	accounter.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
}

/**
 *部门档案字典
 */
private function deptCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict((function(rev:Object):void
	{
		deptCode.txtContent.text=_condition['deptCodeName']=rev.deptName;
		_condition['deptCode']=rev.deptCode;
	}), x, y);
}

/**
 *物资档案字典
 */
private function materialCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialDict((function(rev:Object):void
	{
		event.target.txtContent.text=rev.materialCode;
		_condition[event.target.id]=rev.materialCode;
	}), x, y);
}

/**
 *物资分类档案字典
 */
private function materialClass_queryIconClickHandler():void
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
 *人员(记账人)档案字典
 */
private function accounter_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict((function(rev:Object):void
	{
		event.target.text=_condition['accounterName']=rev.personIdName;
		_condition['accounter']=rev.personId;
	}), x, y);
}


/**
 * 确认查询事件处理方法
 * */
private function btQuery_clickHandler():void
{
	//住院号
	_condition["inpNo"]=inpNo.text;	
	//病人姓名
	_condition["personName"]=personName.text;	
    //记账日期范围
	_condition['beginAccountDate']=accountDate.selected ? beginAccountDate.selectedDate : null;
	_condition['endAccountDate']=accountDate.selected ? MaterialDictShower.addOneDay(endAccountDate.selectedDate) : null;
	
	makeEmptyValueSame(_condition, 'beginMaterialCode', 'endMaterialCode');
	parentWin.dict["入住科室"]=deptCode.txtContent.text;
	if (accountDate.selected)
	{
		parentWin.dict["日期范围"]="从 " + beginAccountDate.text + " 到 " + endAccountDate.text;
	}
	
	//单价
	_condition['beginRetailPrice']=(beginRetailPrice.text == "" ? null : (Number)(beginRetailPrice.text));
	_condition['endRetailPrice']=(endRetailPrice.text == "" ? null : (Number)(endRetailPrice.text));
	
	var params:ParameterObject=new ParameterObject();
	params.conditions=_condition;
	closeWin();
	parentWin.dgPatientFeeList.reQuery(params);

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
private function queryIcon_keyUpHandler(event:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.textInputIconKeyUpHandler(event, _condition, fcontrolNext);
}

/**
 * 确定按钮的回车事件
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
