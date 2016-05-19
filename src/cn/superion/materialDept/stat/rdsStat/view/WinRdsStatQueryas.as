/**
 *	 收发汇总表查询模块
 *   author: 芮玉红  2011.02.24
 **/
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialDept.stat.rdsStat.ModRdsStat;

import mx.events.CalendarLayoutChangeEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import spark.events.TextOperationEvent;

private static var _condition:Object={};
//上一级页面
public var parentWin:ModRdsStat;


private function doInit():void
{
	materialClass.txtContent.setFocus();
	fillForm();
	preventDefaultForm();
}

/**
 * 填充表单
 * */
private function  fillForm():void{
	FormUtils.fillFormByItem(this,_condition);
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

private function billDateFrom_changeHandler(event:CalendarLayoutChangeEvent):void
{
	if (beginBillDate.selectedDate)
	{
		endBillDate.selectedDate=beginBillDate.selectedDate
		endBillDate.selectableRange={rangeStart: beginBillDate.selectedDate, rangeEnd: new Date()}
	}
}

/**
 * 查询按钮处理事件
 * */
private function btQuery_clickHandler():void
{
	_condition['beginYearMonth']=billDate.selected ? DateField.dateToString(beginBillDate.selectedDate, "YYYY-MM"): null;
	_condition['endYearMonth']=billDate.selected ?  DateField.dateToString(endBillDate.selectedDate, "YYYY-MM") : null;
	
	_condition['beginCurrentStockAmount']=beginCurrentStockAmount.text == "" ? null : (Number)(beginCurrentStockAmount.text);
	_condition['endCurrentStockAmount']=endCurrentStockAmount.text == "" ? null : (Number)(endCurrentStockAmount.text);
	
	var paramQuery:ParameterObject=new ParameterObject();
	paramQuery.conditions=_condition;
	
	PopUpManager.removePopUp(this);
	
	var ro:RemoteObject=RemoteUtil.getRemoteObject(parentWin.DESTINATION, function(rev:Object):void
	{
		setToolBarBts(rev);
		for(var i:int=0;i<rev.data.length;i++)
		{
			var item:Object=rev.data.getItemAt(i);
			item.storageName=item.storageCode==null ? "" : ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept',item.storageCode).deptName;
			item.nameSpecFactory = item.materialName + " "+(item.materialSpec == null ? "" : item.materialSpec)+" "+(item.factoryName == null ? "" : item.factoryName.substr(0,6));

		}		
		parentWin.dgRdsStatList.dataProvider=rev.data;
	});
	ro.findRdsStatListByCondition(paramQuery);
}

/**
 * 设置当前按钮是否显示
 */
private function setToolBarBts(rev:Object):void
{
	if (rev.data && rev.data.length)
	{
		parentWin.toolBar.btPrint.enabled=true;
		parentWin.toolBar.btExp.enabled=true;
	}
	else
	{
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
protected function queryIcon_keyUpHandler(event:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.textInputIconKeyUpHandler(event, _condition, fcontrolNext);
}

/**
 * 关闭事件处理方法
 * */
private function closeWin():void
{
	PopUpManager.removePopUp(this);
}