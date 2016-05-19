/**
 *		  其他入库处理模块 设定右键过滤查询窗体
 *		 author:吴小娟   2011.02.25
 *		 checked by
 **/
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.materialDept.receive.receiveOther.ModReceiveOther;
import cn.superion.materialDept.util.RdTypeDict;
import cn.superion.vo.material.MaterialRdsMasterDept;

import mx.collections.ArrayCollection;
import mx.core.FlexGlobals;
import mx.events.ListEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

public var iparentWin:ModReceiveOther;
//条件对象
private static var _condition:Object={};

/**
 * 初始化
 * */
protected function doInit():void
{
	initPanel();
	fillForm();	
	billNo.setFocus();
}

/**
 * 初始化面板
 * */
private function initPanel():void
{
	this.width=FlexGlobals.topLevelApplication.width - 8;
	gdReceiveOtherList.grid.addEventListener(ListEvent.ITEM_CLICK, itemClickEventHandler);
}

/**
 * 填充表单
 * */
private function  fillForm():void{
	FormUtils.fillFormByItem(this,_condition);
}

/**
 * 鼠标单击查询收发存明细列表
 * */
public function itemClickEventHandler(event:ListEvent):void
{
	if (!gdReceiveOtherList.grid.selectedItem)
	{
		return;
	}
	var lstrAutoId:String=gdReceiveOtherList.grid.selectedItem.autoId;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(ModReceiveOther.DESTINATION, function(rev:Object):void
		{
			if (rev.data && rev.data.length > 0)
			{
				gdReceiveOtherDetailList.dataProvider=rev.data;
				return;
			}
			gdReceiveOtherDetailList.dataProvider=new ArrayCollection();
		})
	ro.findRdsDetailByMainAutoId(lstrAutoId);
}

/**
 * 查询盘盈入库事件响应方法
 * */
protected function btQuery_clickHandler():void
{
	var paramQuery:ParameterObject=new ParameterObject();
	// 单据编号
	_condition["billNo"]=billNo.text;
	//单据日期
	if (chkBillDate.selected)
	{

		_condition['beginBillDate']=beginBillDate.selectedDate;
		var ldateEndBillDate:Date=new Date();
		ldateEndBillDate.setTime(endBillDate.selectedDate.getTime() + 24 * 60 * 60 * 1000);
		_condition['endBillDate']=ldateEndBillDate;
	}
	else
	{
		_condition['beginBillDate']=null;
		_condition['endBillDate']=null;
	}
	paramQuery.conditions=_condition;
	gdReceiveOtherList.config(paramQuery, ModReceiveOther.DESTINATION, 'findRdsMasterByCondition', function(rev:Object):void
		{
			gdReceiveOtherList.grid.dataProvider=rev.data;
		}, null, true);
}

/**
 * 单据日期选择
 * */
protected function chkBillDate_changeHandler(event:Event):void
{
	if (chkBillDate.selected)
	{
		beginBillDate.enabled=true;
		endBillDate.enabled=true;
	}
	else
	{
		beginBillDate.enabled=false;
		endBillDate.enabled=false;
	}
}

/**
 * 处理回车键转到下一个控件
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.toNextControl(e, fcontrolNext);
}

/**
 * 确定查询事件响应方法
 * */
protected function btConfirm_clickHandler(event:MouseEvent):void
{
	var laryRdsMaster:MaterialRdsMasterDept=gdReceiveOtherList.grid.selectedItem as MaterialRdsMasterDept;
	var laryRdsDetails:ArrayCollection=gdReceiveOtherDetailList.dataProvider as ArrayCollection;
	PopUpManager.removePopUp(this);
	if(!gdReceiveOtherList.grid.selectedItem)
	{
		return;
	}
	iparentWin.fillPanelByItem(laryRdsMaster, laryRdsDetails);
	//右键过滤（其他入库单）菜单灰化
	iparentWin.imenuItemsEnableValues=['0', '0'];
	//审核按钮亮化
	iparentWin.btToolBar.btVerify.enabled=true;
	iparentWin.imaterialRdsMasterDept.autoId=gdReceiveOtherList.grid.selectedItem.autoId;
}

protected function btQuery_keyUpHandler(event:KeyboardEvent):void
{
	if (event.keyCode == Keyboard.ENTER)
	{
		btQuery_clickHandler();
	}
}

private function labelFun(item:Object, column:DataGridColumn):*
{
	if (column.headerText == "收发类别")
	{
		var receviceTypeItem:*=ArrayCollUtils.findItemInArrayByValue(RdTypeDict.receviceTypeDict, 'receviceType', item.rdType);
		if (!receviceTypeItem)
		{
			item.receviceTypeName="";
		}
		else
		{
			item.receviceTypeName=receviceTypeItem.receviceTypeName;
		}
		return item.receviceTypeName;
	}
}