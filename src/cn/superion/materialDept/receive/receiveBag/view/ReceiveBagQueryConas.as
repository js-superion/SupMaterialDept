/**
 *		  物品发放处理模块 设定查询条件窗体
 *		 author:吴小娟   2011.03.14
 *		 checked by
 **/
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.cssd.daily.deliver.ModDeliver;
import cn.superion.cssd.daily.sterilization.ModSterilization;
import cn.superion.cssd.util.MainToolBar;
import cn.superion.cssd.util.MaterialDictShower;
import cn.superion.dataDict.DictWinShower;

import mx.collections.ArrayCollection;
import mx.events.CloseEvent;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

public var iparentWin:ModDeliver;
//条件对象
private static var _condition:Object={};

/**
 * 初始化
 * */
protected function doInit():void
{
	initTextInputIcon();
	fillForm();
	beginBillNo.setFocus();
}

/**
 * 填充表单
 * */
private function fillForm():void
{
	FormUtils.fillFormByItem(this, _condition);
	fillTextInputIcon(deptCode);
	fillTextInputIcon(personId);
	packageName.text=_condition["packageName"];
	if(!_condition['endBillDate'])
	{
		return;
	}
	endBillDate.selectedDate=new Date(_condition['endBillDate'].getFullYear(), _condition['endBillDate'].getMonth(), _condition['endBillDate'].getDate() - 1);
}

/**
 * 填充放大镜
 * */
private function fillTextInputIcon(fctrl:Object):void
{
	fctrl.text=_condition[fctrl.id + "Name"];
}

/**
 * 初始化放大镜输入框
 * */
private function initTextInputIcon():void
{
	deptCode.txtContent.editable=false;
	personId.txtContent.editable=false;
//	deliverPerson.txtContent.editable=false;
	beginPackageId.txtContent.editable=false;
	endPackageId.txtContent.editable=false;
	packageName.txtContent.editable=false;
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
	// 单据编号
	_condition["beginBillNo"]=beginBillNo.text;
	_condition["endBillNo"]=endBillNo.text;
	//单据日期
	if (chkBillDate.selected)
	{
		//开始单据日期
		_condition['beginBillDate']=beginBillDate.selectedDate;
		//结束单据日期
		var ldateEndBillDate:Date=new Date();
		ldateEndBillDate.setTime(endBillDate.selectedDate.getTime() + 24 * 60 * 60 * 1000);
		_condition['endBillDate']=ldateEndBillDate;
	}
	else
	{
		_condition['beginBillDate']=null;
		_condition['endBillDate']=null;
	}
	//当前状态
	if (currentStatus.selectedItem != null && currentStatus.selectedIndex > -1)
	{
		_condition['currentStatus']=currentStatus.selectedItem.currentStatus;
	}
	paramQuery.conditions=_condition;
	//关闭查询框
	PopUpManager.removePopUp(this);
	var ro:RemoteObject=RemoteUtil.getRemoteObject(ModDeliver.DESTINATION, function(rev:Object):void
		{
			if (rev.data && rev.data.length > 0)
			{
				var laryIds:Array=rev.data;
				var len:Number=laryIds.length;
				var laryEnableds:Array=[];
				//只有一张物品发放处理单时，分页按钮灰化，打印、输出、增加、查询、退出按钮亮化
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
			iparentWin.gridDetail.dataProvider=[];
		});
	ro.findMasterIdListByCondition(paramQuery);
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
 * 部门字典
 * */
protected function deptCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict(function(rev:Object):void
	{
		deptCode.txtContent.text=rev.deptName;
		_condition.deptCode=rev.deptCode;
		_condition['deptCodeName']=rev.deptName;
	}, x, y);
}

/**
 * 人员档案字典
 * */
protected function personId_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict(function(rev:Object):void
	{
		personId.txtContent.text=rev.personIdName;
		_condition.personId=rev.personId;
		_condition['personIdName']=rev.personIdName;
	}, x, y);
}

/**
 * 送货人档案字典
 * */
protected function deliverPerson_queryIconClickHandler(event:Event):void
{
	
}

/**
 * 物品包档案字典
 * */
protected function beginPackageId_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	MaterialDictShower.showCssdPackageDictChooser(function(rev:Object):void
	{
		beginPackageId.txtContent.text=rev.packageId;
		_condition.beginPackageId=rev.packageId;
	}, x, y);
}

/**
 * 物品包档案字典
 * */
protected function endPackageId_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	MaterialDictShower.showCssdPackageDictChooser(function(rev:Object):void
	{
		endPackageId.txtContent.text=rev.packageId;
		_condition.endPackageId=rev.packageId;
	}, x, y);
}

/**
 * 物品包档案字典
 * */
protected function packageName_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	MaterialDictShower.showCssdPackageDictChooser(function(rev:Object):void
	{
		packageName.txtContent.text=rev.packageName;
		_condition.packageId=rev.packageId;
		_condition['packageName']=rev.packageName;
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