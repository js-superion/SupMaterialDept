/**
 *	 保质期预警查询模块
 *   author: 芮玉红  2011.02.24
 **/
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.DateUtil;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialDept.stat.expiryAlarm.ModExpiryAlarm;
import cn.superion.materialDept.util.MaterialDictShower;

import com.adobe.utils.StringUtil;

import mx.controls.DateField;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import spark.events.TextOperationEvent;

private static var _condition:Object={};
//上一级页面
public var parentWin:ModExpiryAlarm;

/**
 *初始化方法
 * */
protected function doInit():void
{	
	fillForm();
	materialClass.txtContent.setFocus();
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
protected function materialClass_queryIconClickHandler(event:Event):void
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
 * 确定
 * 根据物资类型、过期天数、临近天数、供应单位、失效日期查找
 * */
protected function btQuery_clickHandler():void
{
	_condition['beginAvailDate']=btGroup.selectedValue == 'availDate' ? beginAvailDate.selectedDate : null;
	_condition['endAvailDate']=btGroup.selectedValue == 'availDate' ? MaterialDictShower.addOneDay(endAvailDate.selectedDate) : null;
	_condition['overdueNum']=btGroup.selectedValue == 'overdueNum' ? Number(StringUtil.trim(overdueNum.text).length == 0 ? 0 : Number(overdueNum.text)) : null
	_condition['anearNum']=btGroup.selectedValue == 'anearNum' ? Number(StringUtil.trim(nearNum.text).length == 0 ? 0 : Number(nearNum.text)) : null
	
	var paramQuery:ParameterObject=new ParameterObject();
	paramQuery.conditions=_condition;	
	paramQuery.page=1;
	paramQuery.itemsPerPage=10000;
	
	closeWin();
	
	var ro:RemoteObject=RemoteUtil.getRemoteObject(parentWin.DESTINATION, function(rev:Object):void
	{
		if(rev.data.length >  0)
		{
			setToolBarBts(rev);
			for (var i:int=0; i < rev.data.length; i++)
			{
				var item:Object=rev.data.getItemAt(i);
				item.tradeMoney=item.amount * item.tradePrice;
				item.storageName=item.storageCode==null ? "" : ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept',AppInfo.currentUserInfo.deptCode).deptName;
				//保质期天数
				item.qulityDays=DateUtil.getTimeSpans(item.madeDate,item.availDate);
				item.madeDate=item.madeDate==null ? "" :DateField.dateToString(item.madeDate,'YYYY-MM-DD');
				item.availDate=item.availDate==null ? "" :DateField.dateToString(item.availDate,'YYYY-MM-DD');
				
			}
			parentWin.materialClass = materialClass.txtContent.text;
			if(btGroup.selection)
			{
				parentWin.selectedRdoName = btGroup.selection.label;
				parentWin.selectedRdoValue = btGroup.selection == btAvailDate ? (beginAvailDate.text +" 到 "+ endAvailDate.text)
				: btOverdueNum ? overdueNum.text
				: btNearNum ? nearNum.text
				: "";
			}
		}
		parentWin.dgAvailDate.dataProvider=rev.data;
	});
	ro.findAvailDateListByCondition(paramQuery);
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
 * 关闭事件处理方法
 * */
private function closeWin():void
{
	PopUpManager.removePopUp(this);
}