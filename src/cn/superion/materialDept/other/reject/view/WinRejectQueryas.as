/**
 *		 物资报损处理查询条件窗体
 *		 author:吴小娟   2011.02.26
 * 		 modify:吴小娟   2011.07.05
 *		 checked by：
 **/
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialDept.other.reject.ModReject;

import com.adobe.utils.StringUtil;

import flash.events.Event;

import flexlib.scheduling.util.DateUtil;

import mx.collections.ArrayCollection;
import mx.events.CollectionEvent;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import spark.events.TextOperationEvent;


public var parentWin:ModReject;
//条件对象
private static var _condition:Object={};

/**
 * 初始化
 * */
protected function doInit():void
{
	//阻止表单输入
	preventDefaultForm();
	fillForm();
}

/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{
	outDeptCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})

	personId.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})

	materialClass.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})

	beginMaterialCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})

	endMaterialCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
}

/**
 * 填充表单
 * */
private function fillForm():void
{
	FormUtils.fillFormByItem(this, _condition);
	fillTextInputIcon(outDeptCode);
}

/**
 * 填充放大镜
 * */
private function fillTextInputIcon(fctrl:Object):void
{
	fctrl.text=_condition[fctrl.id + "Name"];
}

/**
 * 放大镜输入框键盘处理方法
 * */
protected function textInputIcon_keyUpHandler(event:KeyboardEvent, fctrNext:Object):void
{
	FormUtils.textInputIconKeyUpHandler(event, _condition, fctrNext);
}

/**
 * 处理回车键转到下一个控件
 * */
private function toNextCtrl(event:KeyboardEvent, fctrlNext:Object):void
{
	FormUtils.toNextControl(event, fctrlNext);
}

/**
 * 关闭事件响应方法
 * */
protected function closeWin():void
{
	PopUpManager.removePopUp(this);
}

/**
 * 部门字典(报损部门)
 * */
protected function outDeptCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict(function(rev:Object):void
	{
		outDeptCode.txtContent.text=rev.deptName;
		_condition.outDeptCode=rev.deptCode;
		_condition['outDeptCodeName']=rev.deptName;
	}, x, y);
}

/**
 * 人员字典(经手人)
 * */
protected function personId_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict(function(rev:Object):void
	{
		personId.txtContent.text=rev.personIdName;
		_condition.personId=rev.personId;
	}, x, y);
}

/**
 * 物资分类字典
 * */
protected function materialClass_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialClassDict(function(rev:Object):void
	{
		materialClass.txtContent.text=rev.className;
		_condition.materialClass=rev.classCode;
	}, x, y);
}

/**
 * 物资档案字典(物资编码)
 * */
protected function materialCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialDict(function(rev:Object):void
	{
		event.target.text=rev.materialCode;
		_condition[event.target.id]=rev.materialCode;
	}, x, y);
}

/**
 * 确定按钮
 * */
protected function btConfirm_clickHandler(event:MouseEvent):void
{
	var paramQuery:ParameterObject=new ParameterObject();
	// 报损单号
	_condition["beginBillNo"]=beginBillNo.text;
	_condition["endBillNo"]=endBillNo.text;
	makeEmptyValueSame(_condition, 'beginBillNo', 'endBillNo');
	makeEmptyValueSame(_condition, 'beginMaterialCode', 'endMaterialCode');
	//报损日期
	_condition["beginBillDate"]=billDate.selected ? beginBillDate.selectedDate : null;
	_condition["endBillDate"]=billDate.selected ? addOneDay(endBillDate.selectedDate) : null;
	//当前状态
	if (currentStatus.selectedItem != null && currentStatus.selectedIndex > -1)
	{
		_condition['currentStatus']=currentStatus.selectedItem.currentStatus;
	}
	paramQuery.conditions=_condition;
	PopUpManager.removePopUp(this);
	var ro:RemoteObject=RemoteUtil.getRemoteObject(ModReject.DESTINATION, function(rev:Object):void
	{
		if (rev.data && rev.data.length > 0)
		{
			parentWin.arrayAutoId=ArrayCollection(rev.data).toArray();

			parentWin.findRdsById(rev.data[0]);

			setToolBarPageBts(rev.data.length);
			return;
		}
		parentWin.doInit();
		//清空当前表单
		parentWin.clearForm(true, true);
	});
	ro.findRejectMasterListByCondition(paramQuery);
}

/**
 * 范围值有一个为空时，取另一个值
 * */
private function makeEmptyValueSame(fconditon:Object, fstrFieldStart:String, fstrFieldEnd:String):void
{
	fconditon[fstrFieldStart]=fconditon[fstrFieldStart] || "";
	fconditon[fstrFieldEnd]=fconditon[fstrFieldEnd] || "";
	fconditon[fstrFieldStart]=StringUtil.trim(fconditon[fstrFieldStart]);
	fconditon[fstrFieldEnd]=StringUtil.trim(fconditon[fstrFieldEnd]);
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
 * 给指定日期+(24*3600*1000-1000);
 * */
private function addOneDay(date:Date):Date{
	return DateUtil.addTime(new Date(date), DateUtil.DAY_IN_MILLISECONDS - 1000);
}

/**
 * 设置当前按钮是否显示
 */
private function setToolBarPageBts(flenth:int):void
{
	parentWin.toolBar.queryToPreState();
	if (flenth < 2)
	{
		parentWin.toolBar.btFirstPage.enabled=false;
		parentWin.toolBar.btPrePage.enabled=false;
		parentWin.toolBar.btNextPage.enabled=false;
		parentWin.toolBar.btLastPage.enabled=false;
		return;
	}
	parentWin.toolBar.btFirstPage.enabled=false;
	parentWin.toolBar.btPrePage.enabled=false;
	parentWin.toolBar.btNextPage.enabled=true;
	parentWin.toolBar.btLastPage.enabled=true;
}

/**
 * 取消按钮
 * */
protected function btReturn_clickHandler(event:MouseEvent):void
{
	PopUpManager.removePopUp(this);
}

/**
 * 回车确认查询
 * */
protected function btConfirm_keyUpHandler(event:KeyboardEvent):void
{
	if (event.keyCode == Keyboard.ENTER)
	{
		btConfirm_clickHandler(null);
	}
}