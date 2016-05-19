/**
 *		 采购计划编制
 *		 作者: 朱玉峰 2011.06.18
 *		 修改：
 **/
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.materialDept.deliver.deliverConfirm.view.AgentConfirmQuery;
import cn.superion.materialDept.util.DefaultPage;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialPatsDetail;
import cn.superion.vo.material.MaterialPatsMaster;

import mx.containers.FormItem;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.events.CloseEvent;
import mx.events.ListEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

private static const MENU_NO:String="0202";
public var DESTANATION:String="agentMaterialUsedImpl";
//主记录
public var _materialPatsMaster:MaterialPatsMaster=new MaterialPatsMaster();
//查询主记录ID列表
public var arrayAutoId:Array=new Array();
//当前页，翻页用
public var currentPage:int=0;

/**
 * 初始化当前窗口
 * */
public function doInit():void
{
	parentDocument.title="代销领用确认";
	//重新注册客户端对应的服务端类
	registerClassAlias("cn.superion.materialDept.entity.MaterialPatsMaster", MaterialPatsMaster);
	registerClassAlias("cn.superion.materialDept.entity.MaterialPatsDetail", MaterialPatsDetail);
	initPanel();
	initToolBar();
}

/**
 * 面板初始化
 */
private function initPanel():void
{
	setReadOnly(false);
}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.imageList1, toolBar.btVerify, toolBar.btAbandon, toolBar.imageList2, toolBar.btQuery, toolBar.imageList5, toolBar.btFirstPage, toolBar.btPrePage, toolBar.btNextPage, toolBar.btLastPage, toolBar.imageList6, toolBar.btExit];
	var laryEnables:Array=[toolBar.btQuery, toolBar.btExit];
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 表头设置只读或读写状态
 */
private function setReadOnly(boolean:Boolean):void
{
	FormUtils.setFormItemEditable(patsMaster, boolean);
}

/**
 * 清空表单
 */
public function clearForm(masterFlag:Boolean, detailFlag:Boolean):void
{
	if (masterFlag)
	{
		//清空主记录
		clearMaster();
	}
	if (detailFlag)
	{
		//清空明细
		clearDetail();
	}
}

/**
 * 清空明细
 */
private function clearDetail():void
{
	FormUtils.clearForm(_hgroup);
	FormUtils.clearForm(_bottom);
}

/**
 * 清空主记录
 */
public function clearMaster():void
{
	FormUtils.clearForm(patsMaster);
	dgDetail.dataProvider=null;
	_materialPatsMaster=new MaterialPatsMaster();
}

/**
 * 回车事件
 **/
private function toNextControl(event:KeyboardEvent, fctrlNext:Object):void
{
	FormUtils.toNextControl(event, fctrlNext);
}

/**
 * labelFunction事件
 */
private function nameSpecLBF(item:Object, column:DataGridColumn):String
{
	if (item.cancelAmount > 0)
	{
		item.amount=(Number(item.applyAmount) - Number(item.cancelAmount));
	}
	else
	{

		item.cancelAmount=Number(item.applyAmount) - Number(item.amount);
	}
	return item.cancelAmount;
}

/**
 * 已退数量事件
 */
protected function cancelAmount_keyDownHandler(event:KeyboardEvent):void
{
	// TODO Auto-generated method stub
	if (event.keyCode == Keyboard.ENTER)
	{
		var i:int=dgDetail.selectedIndex;
		if (i < dgDetail.dataProvider.length - 1)
		{
			dgDetail.selectedIndex=i + 1;
			FormUtils.fillFormByItem(patsDetail, dgDetail.selectedItem);
		}
		else
		{
			dgDetail.selectedIndex=0;
			FormUtils.fillFormByItem(patsDetail, dgDetail.selectedItem);
		}
		prepaymentsLeft.text="";
		cancelAmount.setFocus();
	}
}

/**
 * 申请数量事件
 */
protected function textinput1_changeHandler(event:Event):void
{
	if (dgDetail.selectedItem)
	{
		var i:int=dgDetail.selectedIndex;
		if (Number(cancelAmount.text) > dgDetail.selectedItem.applyAmount)
		{
			cancelAmount.text=dgDetail.selectedItem.applyAmount;
		}
		dgDetail.selectedItem.cancelAmount=((Number)(cancelAmount.text))
		dgDetail.invalidateList();
		dgDetail.selectedIndex=i;
	}
}

/**
 * 填充当前表单
 */
protected function dgDetail_itemClickHandler():void
{
	// TODO Auto-generated method stub
	if (dgDetail.selectedItem)
	{
		FormUtils.fillFormByItem(_hgroup, dgDetail.selectedItem);
		prepaymentsLeft.text="";
		prepaymentsLeft.setFocus();
	}
}

/**
 * 打印
 */ 
protected function printClickHandler(event:Event):void
{
	printReport("1");

}

/**
 * 输出
 */ 
protected function expClickHandler(event:Event):void
{
	printReport("0");

}

/**
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	var _dataList:ArrayCollection=dgDetail.dataProvider as ArrayCollection;
	var dict:Dictionary=new Dictionary();
	for (var i:int=0; i < _dataList.length; i++)
	{
		var item:Object=_dataList.getItemAt(i);
		item.factoryName=item.factoryName==null?"":item.factoryName;
		item.availDate=item.availDate==null?new Date():item.availDate;
		item.nameSpec=item.materialName + "  " + (item.materialSpec == null ? "" : item.materialSpec);
	}
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="代销领用确定";
	dict["制表人"]=AppInfo.currentUserInfo.userName;
	dict["单据编号"]=_materialPatsMaster.billNo;
	dict["申请日期"]=DateField.dateToString(_materialPatsMaster.applyDate, "YYYY-MM-DD")
	dict["住院号"]=_materialPatsMaster.inpNo==null?"":_materialPatsMaster.inpNo;
	dict["姓名"]=personName.text==null?"":personName.text;
	dict["性别"]=sex.text==null?"":sex.text;
	dict["年龄"]=_materialPatsMaster.age;
	dict["费别"]=chargeType.text==null?"":chargeType.text;
	dict["科室"]=deptCode.text==null?"":deptCode.text;
	dict["病区"]=wardCode.text==null?"":wardCode.text;
	dict["医生"]=personIdName.text==null?"":personIdName.text;
	dict["余额"]=prepaymentsLeft.text==null?"":prepaymentsLeft.text;
	dict["制单人"]=maker.text==null?"":maker.text;
	dict["制单日期"]=makeDate.text==null?"":makeDate.text;
	dict["审核人"]=verifier.text==null?"":verifier.text;
	dict["审核日期"]=verifyDate.text==null?"":verifyDate.text;
	if (printSign == '1')
		ReportPrinter.LoadAndPrint("report/materialDept/deliver/deliverConfirm/agentConfirm.xml", _dataList, dict);
	if (printSign == '0')
		ReportViewer.Instance.Show("report/materialDept/deliver/deliverConfirm/agentConfirm.xml", _dataList, dict);

}

/**
 * 审核按钮
 */
protected function toolBar_verifyClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	var details:ArrayCollection=dgDetail.dataProvider as ArrayCollection;
	Alert.show('确定要审核这条单据吗？', '提示', Alert.YES | Alert.NO, null, function(e:*):void
		{
			if (e.detail == Alert.YES)
			{
				var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
					{
						Alert.show("审核成功！", "提示");
						findRdsById(_materialPatsMaster.autoId);
					});
				ro.verify(_materialPatsMaster.autoId, dgDetail.dataProvider);
			}
			else
			{
				return;
			}
		})
}

/**
 * 作废按钮
 */
protected function toolBar_abandonClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	Alert.show('是否弃审?', '提示', Alert.YES | Alert.NO, null, function(e:*):void
		{
			if (e.detail == Alert.YES)
			{
				var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
					{
						Alert.show("弃审成功！", "提示");
						findRdsById(_materialPatsMaster.autoId);
					});
				ro.cancelVerify(_materialPatsMaster.autoId);
			}
			else
			{
				return;
			}
		})
}

/**
 * 更具数据状态显示不同的按钮
 */
protected function stateButton(currentStatus:String):void
{
	var state:Boolean=(currentStatus == "1" ? false : true);
	toolBar.btVerify.enabled=state;
	toolBar.btPrint.enabled=true;
	toolBar.btExp.enabled=true;
	toolBar.btAbandon.enabled=(currentStatus == "1" ? true : false);
	cancelAmount.enabled=(currentStatus == "1" ? false : true);
}


/**
 * 查询
 */
protected function queryClickHandler(event:Event):void
{
	var queryWin:AgentConfirmQuery=PopUpManager.createPopUp(this, AgentConfirmQuery, true) as AgentConfirmQuery;
	queryWin.data={parentWin: this};
	PopUpManager.centerPopUp(queryWin);
}

/**
 * 首页
 */
protected function firstPageClickHandler(event:Event):void
{
	//定位到数组第一个
	if (arrayAutoId.length < 1)
	{
		return;
	}
	currentPage=0;
	var strAutoId:String=arrayAutoId[currentPage] as String;
	findRdsById(strAutoId);

	toolBar.firstPageToPreState()
}

/**
 * 下一页
 */
protected function nextPageClickHandler(event:Event):void
{
	if (arrayAutoId.length < 1)
	{
		return;
	}
	currentPage++;
	if (currentPage >= arrayAutoId.length)
	{
		currentPage=arrayAutoId.length - 1;
	}

	var strAutoId:String=arrayAutoId[currentPage] as String;
	findRdsById(strAutoId);

	toolBar.nextPageToPreState(currentPage, arrayAutoId.length - 1);
}

/**
 * 上一页
 */
protected function prePageClickHandler(event:Event):void
{
	if (arrayAutoId.length < 1)
	{
		return;
	}
	currentPage--;
	if (currentPage <= 0)
	{
		currentPage=0;
	}

	var strAutoId:String=arrayAutoId[currentPage] as String;
	findRdsById(strAutoId);

	toolBar.prePageToPreState(currentPage);
}

/**
 * 末页
 */
protected function lastPageClickHandler(event:Event):void
{
	if (arrayAutoId.length < 1)
	{
		return;
	}
	currentPage=arrayAutoId.length - 1;

	var strAutoId:String=arrayAutoId[currentPage] as String;
	findRdsById(strAutoId);

	toolBar.lastPageToPreState();
}

/**
 * 翻页调用此函数
 * */
public function findRdsById(fstrAutoId:String):void
{
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
		{
			if (rev.data.length <= 0)
			{
				return;
			}
			_materialPatsMaster=rev.data[0];
			masterEvaluate(rev);
			dgDetail.dataProvider=rev.data[1];
			stateButton(rev.data[0].currentStatus);
			dgDetail.selectedIndex=0;
			FormUtils.fillFormByItem(patsDetail, dgDetail.selectedItem);
			prepaymentsLeft.text=rev.data[2]
			cancelAmount.setFocus();

		});
	ro.findApplyDetailById(fstrAutoId);
}

/**
 * 给主记录文本赋值
 */
protected function masterEvaluate(rev:Object):void
{
	FormUtils.fillFormByItem(patsMaster, rev.data[0]);
	var aplyDoctor:String=rev.data[0].doctorInCharge == null ? rev.data[0].applyDoctor : rev.data[0].doctorInCharge;
	var consultingDoctor1:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', aplyDoctor);
	var deptcode:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', rev.data[0].deptCode);
	var wardcode:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', rev.data[0].wardCode);
	personIdName.text=consultingDoctor1 == null ? null : consultingDoctor1.personIdName;
	deptCode.text=deptcode == null ? null : deptcode.deptName;
	wardCode.text=wardcode == null ? null : wardcode.deptName;
	personName.text=rev.data[0].personName == null ? personName.text : rev.data[0].personName;
	FormUtils.fillFormByItem(_bottom, rev.data[0]);
	maker.text=codeToName(rev.data[0].maker);
	verifier.text=codeToName(rev.data[0].verifier);
}

/**
 * 批号
 */
private function batchLBF(item:Object, column:DataGridColumn):String
{
	if (item.batch == '0')
	{
		item.batchName='';
	}
	else
	{
		item.batchName=item.batch;
	}
	return item.batchName;
}

/**
 * 退出
 */
protected function exitClickHandler(event:Event):void
{
	PopUpManager.removePopUp(this.parentDocument as IFlexDisplayObject);
	DefaultPage.gotoDefaultPage();
}

/**
 * 当前角色权限认证
 */
public static function checkUserRole(role:String):Boolean
{
	//判断具有操作权限  -- 应用程序编号，菜单编号，权限编号
	// 01：增加                02：修改            03：删除
	// 04：保存                05：打印            06：审核
	// 07：弃审                08：输出            09：输入
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, role))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return false;
	}
	return true;
}

/**
 * 转换人名
 */
protected function codeToName(name:String):String
{
	var makerItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', name);
	var maker:String=makerItem == null ? "" : makerItem.personIdName;
	return maker;
}