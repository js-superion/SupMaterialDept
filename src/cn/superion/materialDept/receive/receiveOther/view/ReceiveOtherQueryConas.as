/** 
 *		  其他入库处理模块 设定查询条件窗体  
 *		 author:吴小娟   2011.02.25
 *		 checked by 
 **/
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialDept.receive.receiveOther.ModReceiveOther;
import cn.superion.materialDept.util.MainToolBar;

import mx.collections.ArrayCollection;
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
	initTextInputIcon();
	fillForm();
	operationType.setFocus();	
}

/**
 * 填充表单
 * */
private function  fillForm():void{
	FormUtils.fillFormByItem(this,_condition);
	if(!_condition['endBillDate'])
	{
		return;
	}
	endBillDate.selectedDate=new Date(_condition['endBillDate'].getFullYear(), _condition['endBillDate'].getMonth(), _condition['endBillDate'].getDate() - 1);
}

/**
 * 初始化放大镜输入框
 * */
private function initTextInputIcon():void
{
	materialCode.txtContent.editable=false;
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
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.toNextControl(e, fcontrolNext);
}

/**
 * 取消按钮事件响应方法
 * */
protected function btReturn_clickHandler(event:MouseEvent):void
{
	PopUpManager.removePopUp(this);
}

/**
 * 确定查询事件处理方法
 * */
protected function btConfirm_clickHandler():void
{
	var paramQuery:ParameterObject=new ParameterObject();
	//业务类型
	if (operationType.selectedItem != null && operationType.selectedIndex > -1)
	{
		_condition['operationType']=operationType.selectedItem.operationType;
	}
	// 入库单号
	_condition["beginBillNo"]=beginBillNo.text;
	_condition["endBillNo"]=endBillNo.text;
	//入库日期
	if (chkImportDate.selected)
	{
		//开始入库日期
		_condition['beginBillDate']=beginBillDate.selectedDate;
		//结束入库日期
		var ldateEndBillDate:Date=new Date();
		ldateEndBillDate.setTime(endBillDate.selectedDate.getTime() + 24 * 60 * 60 * 1000);
		_condition['endBillDate']=ldateEndBillDate;
	}
	else
	{
		_condition['beginBillDate']=null;
		_condition['endBillDate']=null;
	}
	//入库类别
	if (rdType.selectedItem != null && rdType.selectedIndex > -1)
	{
		_condition['rdType']=rdType.selectedItem.receviceType;
	}
	//进价
	_condition['beginTradePrice']=beginTradePrice.text == "" ? null : parseFloat(beginTradePrice.text);
	_condition['endTradePrice']=endTradePrice.text == "" ? null : parseFloat(endTradePrice.text);
	//当前状态
	if (currentStatus.selectedItem != null && currentStatus.selectedIndex > -1)
	{
		_condition['currentStatus']=currentStatus.selectedItem.currentStatus;
	}
	paramQuery.conditions=_condition;
	//关闭查询框
	PopUpManager.removePopUp(this);
	var ro:RemoteObject=RemoteUtil.getRemoteObject(ModReceiveOther.DESTINATION, function(rev:Object):void
		{
			if (rev.data && rev.data.length > 0)
			{
				//右键过滤（其他入库单）灰化
				iparentWin.imenuItemsEnableValues=['0', '0'];
				//设置不可以查询现存量
				iparentWin.iqueryStockSign=false;
				var laryIds:Array=rev.data;
				var len:Number=laryIds.length;
				var laryEnableds:Array=[];
				//只有一张其他入库单时，分页按钮灰化，打印、输出、增加、查询、退出按钮亮化
				if (len == 1)
				{
					laryEnableds=[iparentWin.btToolBar.btPrint, iparentWin.btToolBar.btExp, iparentWin.btToolBar.btAdd, iparentWin.btToolBar.btQuery, iparentWin.btToolBar.btExit];
					MainToolBar.showSpecialBtn(iparentWin.btToolBar, iparentWin.iaryDisplays, laryEnableds, true);
				}
				//下一张、末张、打印、输出、增加、查询、退出按钮亮化
				else
				{
					laryEnableds=[iparentWin.btToolBar.btPrint, iparentWin.btToolBar.btExp, iparentWin.btToolBar.btAdd, iparentWin.btToolBar.btQuery, iparentWin.btToolBar.btNextPage, iparentWin.btToolBar.btLastPage, iparentWin.btToolBar.btExit];
					MainToolBar.showSpecialBtn(iparentWin.btToolBar, iparentWin.iaryDisplays, laryEnableds, true);
				}
				iparentWin.getDataByAutoId(laryIds[0]);
				iparentWin.setIdsArrayToToolBar(laryIds);
				return;
			}
			iparentWin.btToolBar.btFirstPage.enabled=false;
			iparentWin.btToolBar.btPrePage.enabled=false;
			iparentWin.btToolBar.btNextPage.enabled=false;
			iparentWin.btToolBar.btLastPage.enabled=false;
			FormUtils.clearForm(iparentWin.allPanel);
			//  仓库
			var storageCodeItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', AppInfo.currentUserInfo.deptCode);
			iparentWin.storageCode.text=storageCodeItem == null ? "" : storageCodeItem.deptName;
			iparentWin.gdReceiveOtherList.dataProvider=[];
		});
	ro.findRdsMasterListByCondition(paramQuery);
}

/**
 * 入库日期选择
 * */
protected function chkImportDate_changeHandler(event:Event):void
{
	if (chkImportDate.selected)
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
 * 物资档案字典
 * */
protected function materialCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialDict(function(rev:Object):void
		{
			materialCode.txtContent.text=rev.materialCode;
			_condition.materialCode=rev.materialCode;
		}, x, y);
}

/**
 * 确定回车事件处理方法
 * */
protected function btConfirm_keyUpHandler(event:KeyboardEvent):void
{
	if (event.keyCode == Keyboard.ENTER)
	{
		btConfirm_clickHandler();
	}
}