/**
 *	 流水账查询模块
 *   author: 芮玉红  2011.02.24
 **/
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialDept.stat.currentAccountStat.ModCurrentAccountStat;
import cn.superion.materialDept.util.MaterialDictShower;
import cn.superion.materialDept.util.RdTypeDict;

import com.adobe.utils.StringUtil;

import flash.events.Event;

import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import spark.events.TextOperationEvent;

private static var _condition:Object={};
//上级页面
public var parentWin:ModCurrentAccountStat;

/**
 * 初始化
 * */
private function doInit():void
{
	fillCombox();
	fillForm();
	preventDefaultForm();
}

/**
 * 填充下拉框
 * */
private function fillCombox():void
{
	//业务类型赋值
	operationType.dataProvider=BaseDict.operationTypeDict;
	operationType.textInput.editable=false;
}

/**
 * 填充表单
 * */
private function fillForm():void
{
	FormUtils.fillFormByItem(this, _condition);
	fillTextInputIcon(supplyDeptCode);
}

private function fillTextInputIcon(fctrl:Object):void
{
	fctrl.text=_condition[fctrl.id + "Name"]
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

	supplyDeptCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
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
 *供应单位档案字典
 */
private function supplyDeptCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict((function(rev:Object):void
		{
			_condition['supplyDeptCodeName']=supplyDeptCode.txtContent.text=rev.providerName;
			_condition['supplyDeptCode']=rev.providerId;
		}), x, y);
}

/**
 *人员(业务员)档案字典
 */
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
 * 处理回车键转到下一个控件
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.toNextControl(e, fcontrolNext);
}

/**
 * 放大镜键盘事件处理方法
 * */
private function queryIcon_keyUpHandler(event:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.textInputIconKeyUpHandler(event, _condition, fcontrolNext);
}

/**
 * 确定按钮处理方法
 * */
private function btQuery_clickHandler():void
{
	_condition['operationType']=operationType.selectedItem ? operationType.selectedItem.operationType : "";
	parentWin.dict["业务类型"]=operationType.selectedItem ? operationType.selectedItem.operationTypeName : "";

	_condition["beginBillNo"]=beginBillNo.text;
	_condition["endBillNo"]=endBillNo.text;

	makeEmptyValueSame(_condition, 'beginBillNo', 'endBillNo');
	makeEmptyValueSame(_condition, 'beginMaterialCode', 'endMaterialCode');

	_condition['beginBillDate']=billDate.selected ? beginBillDate.selectedDate : null;
	_condition['endBillDate']=billDate.selected ? MaterialDictShower.addOneDay(endBillDate.selectedDate) : null;

	parentWin.dict["物资分类"]=materialClass.txtContent.text;
	if (billDate.selected)
	{
		parentWin.dict["日期范围"]="从" + beginBillDate.text + "到" + endBillDate.text + "日";
	}

	var paramQuery:ParameterObject=new ParameterObject();
	paramQuery.conditions=_condition;
	PopUpManager.removePopUp(this);

	var ro:RemoteObject=RemoteUtil.getRemoteObject(parentWin.DESTINATION, function(rev:Object):void
		{
			setToolBarBts(rev);
			for (var i:int=0; i < rev.data.length; i++)
			{
				var item:Object=rev.data.getItemAt(i);
				item.invoiceTypeName=item.invoiceType=='1' ? '普通发票' : '专用发票';
				item.nameSpecFactory=item.materialName + " " + (item.materialSpec == null ? "" : item.materialSpec) + " " + (item.factoryName == null ? "" : item.factoryName.substr(0, 6));
				item.storageName=item.storageCode==null ? "" : ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', item.storageCode).deptName;
			}
			parentWin.gdCurrentAccount.dataProvider=rev.data;
		});
	ro.findCurrentAccountListByCondition(paramQuery);
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
 * 设置工具栏的可用按钮
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
 * 关闭事件处理方法
 * */
private function closeWin():void
{
	PopUpManager.removePopUp(this);
}
