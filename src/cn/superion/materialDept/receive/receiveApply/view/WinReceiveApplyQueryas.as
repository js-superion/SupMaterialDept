import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.LoadModuleUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialDept.receive.receiveApply.ModReceiveApply;
import cn.superion.materialDept.util.MainToolBar;
import cn.superion.vo.material.MaterialApplyDetail;
import cn.superion.vo.material.MaterialApplyMaster;
import cn.superion.base.util.StringUtils;

import flashx.textLayout.events.DamageEvent;

import mx.collections.ArrayCollection;
import mx.events.CollectionEvent;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.modules.ModuleLoader;
import mx.rpc.remoting.RemoteObject;

import spark.components.ComboBox;

public  var iparentWin:ModReceiveApply;
//条件对象
private static var _condition:Object={}

/**
 * 初始化
 * */
private function doInit():void
{
	fillForm();
	//
	endBillDate.selectedDate = new Date();
	deptCode1.dataProvider = iparentWin.deptCode.dataProvider;
	deptCode1.textInput.editable=false;
}

/**
 * 填充表单
 * */
private function  fillForm():void{
	FormUtils.fillFormByItem(this,_condition);
}

/**
 * 处理回车键转到下一个控件
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.toNextControl(e,fcontrolNext);
}

/**
 * 查询确认
 * */
protected function btQuery_clickHandler(event:MouseEvent):void
{
	var para:ParameterObject = new ParameterObject();
	//获取查询条件的值
	_condition = 
		{
		//	"beginBillNo":beginBillNo.text == null ? " ":beginBillNo.text,
		//		"endBillNo":endBillNo.text == null ? " ":endBillNo.text,
				"beginMaterialCode":beginMaterialCode.text == null ? " ":beginMaterialCode.text,
//				"endMaterialCode":endMaterialCode.text == null ? " ":endMaterialCode.text,
				"currentStatus":currentStatus.selectedItem?currentStatus.selectedItem.code.toString():"",
				"beginBillDate":beginBillDate.selectedDate,
				"endBillDate":MainToolBar.addOneDay(endBillDate.selectedDate),
				"deptCode":deptCode1.selectedItem.deptCode
		};
	if(beginBillNo.text != null && StringUtils.Trim(beginBillNo.text) != ''){
		if(endBillNo.text != null && StringUtils.Trim(endBillNo.text) != ''){
			_condition['beginBillNo'] = beginBillNo.text;
			_condition['endBillNo'] = endBillNo.text;
		}else{
			_condition['billNo'] = beginBillNo.text;
		}
	}
	
	//将查询对象赋给ParameterObject的conditions
	para.conditions = _condition;
	var ro:RemoteObject = RemoteUtil.getRemoteObject(ModReceiveApply.DESTANATION,function (rev:Object):void{
		if (rev.data && rev.data.length > 0)
		{
			iparentWin.arrayAutoId=ArrayCollection(rev.data).toArray();
			
			iparentWin.findRdsById(rev.data[0]);
			
			setToolBarPageBts(rev.data.length);
			cancel_clickHandler();
		}
		else
		{
			iparentWin.doInit();
			//清空当前表单
			iparentWin.clearForm(true, true);
		}
	});
	ro.findApplyMasterListByCondition(para);
}

/**
 * 设置当前按钮是否显示
 */
private function setToolBarPageBts(flenth:int):void
{
	iparentWin.toolBar.queryToPreState()
	
	if (flenth < 2)
	{
		iparentWin.toolBar.btFirstPage.enabled=false
		iparentWin.toolBar.btPrePage.enabled=false
		iparentWin.toolBar.btNextPage.enabled=false
		iparentWin.toolBar.btLastPage.enabled=false
		return;
	}
	iparentWin.toolBar.btFirstPage.enabled=false
	iparentWin.toolBar.btPrePage.enabled=false
	iparentWin.toolBar.btNextPage.enabled=true
	iparentWin.toolBar.btLastPage.enabled=true
}
/**
 * 退出
 * */
protected function cancel_clickHandler():void
{
	PopUpManager.removePopUp(this);
}