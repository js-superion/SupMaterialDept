/** 
 *		 库存盘点模块 盘库条件窗体  
 *		 author:宋盐兵   2011.01.19
 *		 modified by 邢树斌  2011.02.19
 * 		 modified by 吴小娟  2011.07.06
 *		 checked by 
 **/
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.base.util.StringUtils;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialDept.other.check.ModCheck;

import flexlib.scheduling.util.DateUtil;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
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
		_condition.materialClass=item.classCode;
		materialClass.txtContent.text=item.className;
	});
}

/**
 * 物资档案字典
 * */
protected function materialName_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialDict(function(rev:Object):void
	{
		materialName.txtContent.text=rev.materialName;
		_condition.materialName=rev.materialName;
	});
}

/**
 * 确认查询事件处理方法
 * */
protected function btConfirm_clickHandler(event:MouseEvent):void
{
	var paramQuery:ParameterObject=new ParameterObject();
	// 仓库编码
	_condition["storageCode"]=AppInfo.currentUserInfo.deptCode;
	// 有效期限
	_condition["beginAvailDate"]=isAvailDate.selected ? beginAvailDate.selectedDate : null;
	_condition["endAvailDate"]=isAvailDate.selected ? addOneDay(endAvailDate.selectedDate) : null;
	// 临近天数
	_condition["anearNum"]=anearNum.text == "" ? null : parseInt(anearNum.text);
	paramQuery.conditions=_condition;
	PopUpManager.removePopUp(this);
	var ro:RemoteObject=RemoteUtil.getRemoteObject(ModCheck.DESTANATION, function(rev:Object):void
	{
		var laryList:ArrayCollection=parentWin.gdCheckDetail.dataProvider as ArrayCollection;
		for(var i:int=0;i<rev.data.length;i++)
		{
			laryList.addItem(rev.data[i]);
		}
		parentWin.gdCheckDetail.dataProvider=laryList;
	});
	ro.findCheckMaterial(paramQuery);

}

/**
 * 给指定日期+(24*3600*1000-1000);
 * */
private function addOneDay(date:Date):Date{
	return DateUtil.addTime(new Date(date), DateUtil.DAY_IN_MILLISECONDS - 1000);
}

/**
 * 账面为零是否盘点复选框回车事件处理方法
 * */
protected function checkSign_keyUpHandler(e:KeyboardEvent):void
{
	if (e.keyCode == Keyboard.ENTER)
	{
		checkSign.selected=!checkSign.selected;
	}
}

/**
 * 账面为零是否盘点复选框事件处理方法
 * */
protected function checkSign_changeHandler(event:Event):void
{
	_condition.checkZeroSign=checkSign.selected?"1":"0"
}

/**
 * 是否受托代销物资复选框事件处理方法
 * */
protected function agentSign_changeHandler(event:Event):void
{
	_condition.agentSign =agentSign.selected?"1":"0"
}

/**
 * 返回主页面
 * */
protected function btReturn_clickHandler():void
{
	PopUpManager.removePopUp(this);
}
