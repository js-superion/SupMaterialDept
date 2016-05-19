/**
 *	 入库单据列表查询模块
 *   author: 芮玉红  2011.02.23
 **/
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialDept.list.receiveList.ModReceiveList;
import cn.superion.materialDept.util.MaterialDictShower;

import mx.collections.ArrayCollection;
import mx.managers.PopUpManager;

import spark.events.TextOperationEvent;

[Bindable]
private var currentStatusArray:ArrayCollection=new ArrayCollection([{currentStatus: null, currentStatusName: '全部'}, {currentStatus: '0', currentStatusName: '新建状态'}, {currentStatus: '1', currentStatusName: '审核状态'}]);

//上级页面
public var parentWin:ModReceiveList;
//条件对象
private static var _condition:Object={};

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
	//业务类型
	operationType.dataProvider = new ArrayCollection([{operationType:null,operationTypeName:'全部'},
		{operationType:'107',operationTypeName:'领用入库'},
		{operationType:'109',operationTypeName:'其他入库'}]);
	operationType.setFocus();
	operationType.textInput.editable=false;
	
	currentStatus.textInput.editable=false;
}
/**
 * 填充表单
 * */
private function fillForm():void
{
	FormUtils.fillFormByItem(this, _condition);
	fillTextInputIcon(materialCode);
	fillTextInputIcon(supplyDeptCode);	
}

private function fillTextInputIcon(fctrl:Object):void
{
	fctrl.text=_condition[fctrl.id+ "Name"];

}

/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{
	materialCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
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
 *物资档案字典
 */
private function materialCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialDict((function(rev:Object):void
		{
			materialCode.txtContent.text=_condition['materialCodeName']=rev.materialName;
			_condition['materialCode']=rev.materialCode;
		}), x, y);
}

/**
 *人员档案字典
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
 *供应单位档案字典
 */
private function supplyDeptCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict((function(rev:Object):void
		{
		    supplyDeptCode.txtContent.text=_condition['supplyDeptCodeName']=rev.providerName;
			_condition['supplyDeptCode']=rev.providerCode;
		}), x, y);
}


/**
 * 确认查询事件处理方法
 * */
private function btQuery_clickHandler():void
{

	var paramQuery:ParameterObject=new ParameterObject();
	//业务类型
	_condition['operationType']=operationType.selectedItem ? operationType.selectedItem.operationType : "";
	//当前状态
	_condition['currentStatus']=currentStatus.selectedItem ? currentStatus.selectedItem.currentStatus : "";
	//入库单号
	_condition['billNo']=billNo.text;
	//进价范围
	_condition['beginTradePrice']=beginTradePrice.text == "" ? null : Number(beginTradePrice.text);
	_condition['endTradePrice']=endTradePrice.text == "" ? null : Number(endTradePrice.text);
	//单据日期范围
	_condition['beginBillDate']=billDate.selected ? beginBillDate.selectedDate : null ;
	_condition['endBillDate']=billDate.selected ? MaterialDictShower.addOneDay(endBillDate.selectedDate) : null;
	
	if (billDate.selected)
	{
		parentWin.dict["日期范围"]="从" + beginBillDate.text + "到" + endBillDate.text + "日";
	}
	
	paramQuery.conditions=_condition;
	closeWin();
	parentWin.dgReceiveList.reQuery(paramQuery);

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
