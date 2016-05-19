/** 
 *		 库存盘点模块 设定查询条件窗体  
 *		 author:宋盐兵   2011.01.19
 *		 modified by 邢树斌  2011.02.19
 *       modified by 吴小娟  2011.07.06
 *		 checked by 
 **/
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.base.util.StringUtils;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialDept.other.check.ModCheck;

import com.adobe.utils.StringUtil;

import flash.events.Event;

import flexlib.scheduling.util.DateUtil;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import spark.events.TextOperationEvent;

public var parentWin:ModCheck;
//条件对象
private static var _condition:Object={}

/**
 * 初始化
 * */
private function doInit():void
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
	materialClass.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
	
	materialName.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
}

/**
 * 填充表单
 * */
private function  fillForm():void{	
	FormUtils.fillFormByItem(this,_condition);
	storageCode.text= AppInfo.currentUserInfo.deptName;
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
 * 物资类别字典
 * */
protected function materialClass_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialClassDict(function(item:Object):void
	{
		materialClass.txtContent.text=item.className;
		_condition.materialClass=item.classCode;
	}, x, y);
}

/**
 * 物资档案字典
 * */
protected function materialName_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialDict(function(item:Object):void
	{		
		materialName.txtContent.text=item.materialName;
		_condition.materialName=item.materialName;
	}, x, y);
}

/**
 * 确认查询事件处理方法
 * */
protected function btConfirm_clickHandler(event:MouseEvent):void
{
	var paramQuery:ParameterObject=new ParameterObject();
	_condition["storageCode"]=AppInfo.currentUserInfo.deptCode;
	// 盘点单号
	_condition["beginBillNo"]=StringUtils.Trim(beginBillNo.text);
	_condition["endBillNo"]=StringUtils.Trim(endBillNo.text);
	makeEmptyValueSame(_condition, 'beginBillNo', 'endBillNo');
	// 盘点日期
	_condition["beginBillDate"]=billDate.selected ? beginBillDate.selectedDate : null;
	_condition["endBillDate"]=billDate.selected ? addOneDay(endBillDate.selectedDate) : null;
	
	paramQuery.conditions=_condition;
	PopUpManager.removePopUp(this);
	var ro:RemoteObject=RemoteUtil.getRemoteObject(ModCheck.DESTANATION, function(rev:Object):void
	{
		if (rev.data && rev.data.length > 0)
		{
			parentWin.arrayAutoId=ArrayCollection(rev.data).toArray();
			
			parentWin.findCheckById(rev.data[0]);
			
			setToolBarPageBts(rev.data.length);
			return;
		}
		parentWin.doInit();
		//清空当前表单
		parentWin.clearForm(true, true);
	});
	ro.findCheckMasterListByCondition(paramQuery);
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
 * 返回主页面
 * */
protected function btReturn_clickHandler():void
{
	PopUpManager.removePopUp(this);
}

