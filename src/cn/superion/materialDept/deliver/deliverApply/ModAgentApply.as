/**
 *		 采购计划编制
 *		 作者: 朱玉峰 2011.06.18
 *		 修改：
 **/
import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialDept.deliver.deliverApply.view.AgentApplyQuery;
import cn.superion.materialDept.util.DefaultPage;
import cn.superion.materialDept.util.MaterialDictShower;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialPatsDetail;
import cn.superion.vo.material.MaterialPatsMaster;

import mx.collections.ArrayCollection;
import mx.containers.Form;
import mx.containers.FormItem;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.events.CloseEvent;
import mx.events.ListEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import spark.events.IndexChangeEvent;
import spark.events.TextOperationEvent;

private static const MENU_NO:String="0201";
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
	parentDocument.title="代销领用申请";

	//重新注册客户端对应的服务端类
	registerClassAlias("cn.superion.materialDept.entity.MaterialPatsMaster", MaterialPatsMaster);
	registerClassAlias("cn.superion.materialDept.entity.MaterialPatsDetail", MaterialPatsDetail);
//	//放大镜不可手动输入
//	preventDefaultForm();
	initPanel();
	initToolBar();
}


/**
 * 面板初始化
 */
private function initPanel():void
{
	storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
	storageCode.selectedIndex=0;
	setReadOnly(false);
	deptCode.width=inpNo.width;
	consultingDoctor.width=age.width;
	prepaymentsLeft.width=chargeType.width;

}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btAddRow, toolBar.btExp, toolBar.imageList1, toolBar.btAdd, toolBar.btModify, toolBar.btDelete, toolBar.btCancel, toolBar.btSave, toolBar.imageList2, toolBar.btDelRow, toolBar.btQuery, toolBar.imageList5, toolBar.btFirstPage, toolBar.btPrePage, toolBar.btNextPage, toolBar.btLastPage, toolBar.imageList6, toolBar.btExit];
	var laryEnables:Array=[toolBar.btAdd, toolBar.btQuery, toolBar.btExit];
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 表头设置只读或读写状态
 */
private function setReadOnly(boolean:Boolean):void
{
	inpNo.editable=boolean;
	patsDetail.visible=boolean;
	patsDetail.includeInLayout=boolean;
	storageCode.enabled=boolean;
}

/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{
	batchs.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
		{
			e.preventDefault();
		})
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
}

/**
 * 清空主记录
 */
public function clearMaster():void
{
	FormUtils.clearForm(patsMaster);
	dataGridDetail.dataProvider=null;
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
 * 数量key事件
 */
protected function amountKey(e:KeyboardEvent):void
{
	if (e.keyCode == Keyboard.ENTER)
	{
		if (!dataGridDetail.selectedItem)
		{
			return;
		}
		if ((dataGridDetail.selectedItem.applyAmount) <= 0)
		{
			return;
		}
		materialCode_queryIconClickHandler(e);
	}
}

/**
 * 仓库change事件
 */
protected function storageCode_changeHandler(event:IndexChangeEvent):void
{
	// TODO Auto-generated method stub
	_materialPatsMaster.storageCode=storageCode.selectedItem.storageCode;
}

/**
 * 物资编码Key事件
 */
protected function materialCode_keyDownHandler(event:KeyboardEvent):void
{
	// TODO Auto-generated method stub
	if (event.keyCode == Keyboard.ENTER)
	{
		materialCode_queryIconClickHandler(event)
	}
}

/**
 * 物资字典
 */
protected function materialCode_queryIconClickHandler(event:Event):void
{
	//打开物资字典
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 338;
	var lstorageCode:String='';
	lstorageCode=null;
	DictWinShower.showMaterialDictNew(lstorageCode, '', '', true, function(faryItems:Object):void
		{
			fillIntoGrid(faryItems);
		}, x, y);
}

/**
 * 自动完成表格回调
 * */
private function fillIntoGrid(fItem:Object):void
{
	var materialPlanDetail:MaterialPatsDetail=new MaterialPatsDetail();
	var laryDetails:ArrayCollection=dataGridDetail.dataProvider as ArrayCollection;
	//放大镜取出的值、赋值
	for (var i:int=0;i<fItem.length;i++)
	{
		materialPlanDetail=fillDetailForm(fItem[i]);
		laryDetails.addItem(materialPlanDetail);
	}
	dataGridDetail.dataProvider=laryDetails;
	dataGridDetail.selectedIndex=laryDetails.length - 1;
}

/**
 * 明细表单赋值
 */
private function fillDetailForm(faryItems:Object):MaterialPatsDetail
{
	var materialPatsDetail:MaterialPatsDetail=new MaterialPatsDetail();
	materialCode.text=faryItems.materialCode;
	//物资编码
	materialPatsDetail.materialCode=faryItems.materialCode;
	//物资Id
	materialPatsDetail.materialId=faryItems.materialId;
	//物资类型
	materialPatsDetail.materialClass=faryItems.materialClass;
	//物资名称
	materialPatsDetail.materialName=faryItems.materialName;
	//规格型号
	materialPatsDetail.materialSpec=faryItems.materialSpec;
	//单位
	materialPatsDetail.materialUnits=faryItems.materialUnits;
	//售价金额
	materialPatsDetail.retailMoney=faryItems.retailPrice;
	//售价
	materialPatsDetail.retailPrice=faryItems.retailPrice;
	//生产厂家
	materialPatsDetail.factoryCode=faryItems.factoryCode;
	;
	//生产日期
	materialPatsDetail.madeDate=faryItems.madeDate;
	//批号
	materialPatsDetail.batch=faryItems.batch;
	//有效日期
	materialPatsDetail.availDate=faryItems.availDate;
	//初始化申请数量
	materialPatsDetail.applyAmount=1;
	//退费标准
	materialPatsDetail.refundSign="0";
	//数用数量
	materialPatsDetail.amount=0;
	FormUtils.fillFormByItem(_hgroup, materialPatsDetail);
	var timer:Timer=new Timer(100, 1)
	timer.addEventListener(TimerEvent.TIMER, function(e:Event):void
		{
			applyAmount.setFocus();
		})
	timer.start();
	return materialPatsDetail;
}

/**
 * 给主记录赋值
 */
private function fillRdsMaster(rev:Object):void
{
	_materialPatsMaster.billType="1";
	_materialPatsMaster.storageCode=storageCode.selectedItem.storageCode;
	_materialPatsMaster.patientType="2";
	_materialPatsMaster.patientId=rev.patientId;
	_materialPatsMaster.inpNo=rev.inpNo;
	_materialPatsMaster.visitId=rev.visitId;
	_materialPatsMaster.personName=rev.patientName;
	_materialPatsMaster.sex=rev.sex;
	_materialPatsMaster.dateOfBirth=rev.dateOfBirth;
	_materialPatsMaster.age=(Number)(rev.age.slice(0, rev.age.length - 1));
	_materialPatsMaster.ageUnits=rev.age.slice(rev.age.length - 1, rev.age.length);
	_materialPatsMaster.idNo=rev.idNo;
	_materialPatsMaster.bedNo=rev.bedNo;
	_materialPatsMaster.chargeType=rev.chargeType;
	_materialPatsMaster.deptCode=rev.deptCode;
	_materialPatsMaster.wardCode=rev.wardCode;
	_materialPatsMaster.clinicDiag=rev.admDiagnose;
	_materialPatsMaster.clinicDiagName=rev.diagnoseName;
	_materialPatsMaster.applyDoctor=rev.doctorInCharge;
	_materialPatsMaster.applyDate=new Date();
	_materialPatsMaster.currentStatus="0";
}

/**
 * 申请数量事件
 */
protected function evaluate_changeHandler(event:Event):void
{
	if (!dataGridDetail.selectedItem)
	{
		return;
	}
	dataGridDetail.selectedItem.amount=Number(applyAmount.text);
	dataGridDetail.selectedItem.applyAmount=Number(applyAmount.text);
	dataGridDetail.selectedItem.retailMoney=Number(applyAmount.text) * dataGridDetail.selectedItem.retailPrice;
}

/**
 * 填充当前表单
 */
protected function gdItems_itemClickHandler(event:ListEvent):void
{
	// TODO Auto-generated method stub
	FormUtils.fillFormByItem(_hgroup, dataGridDetail.selectedItem);
	FormUtils.selectComboItem(storageCode, "operationType", dataGridDetail.selectedItem);
}

//打印
protected function printClickHandler(event:Event):void
{
	printReport("1");

}

//输出
protected function expClickHandler(event:Event):void
{
	printReport("0");

}


/**
 * 打印预览报表
 */
private function printReport(printSign:String):void
{ //{
	var _dataList:ArrayCollection=dataGridDetail.dataProvider as ArrayCollection;
	var dict:Dictionary=new Dictionary();
	for (var i:int=0; i < _dataList.length; i++)
	{
		var item:Object=_dataList.getItemAt(i);
		item.factoryName=item.factoryName == null ? "" : item.factoryName;
		item.availDate=item.availDate == null ? new Date() : item.availDate;
		item.nameSpec=item.materialName + "  " + (item.materialSpec == null ? "" : item.materialSpec);
	}
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="代销领用申请";
	dict["制表人"]=AppInfo.currentUserInfo.userName;
	dict["单据编号"]=_materialPatsMaster.billNo;
	dict["申请日期"]=DateField.dateToString(_materialPatsMaster.applyDate, "YYYY-MM-DD")
	dict["住院号"]=_materialPatsMaster.inpNo == null ? "" : _materialPatsMaster.inpNo;
	dict["姓名"]=patientName.text == null ? "" : patientName.text;
	dict["性别"]=sex.text == null ? "" : sex.text;
	dict["年龄"]=_materialPatsMaster.age;
	dict["费别"]=chargeType.text == null ? "" : chargeType.text;
	dict["科室"]=deptCode.text == null ? "" : deptCode.text;
	dict["病区"]=wardCode.text == null ? "" : wardCode.text;
	dict["医生"]=consultingDoctor.text == null ? "" : consultingDoctor.text;
	dict["余额"]=prepaymentsLeft.text == null ? "" : prepaymentsLeft.text;
	dict["制单人"]=maker.text == null ? "" : maker.text;
	dict["制单日期"]=makeDate.text == null ? "" : makeDate.text;
	dict["审核人"]=verifier.text == null ? "" : verifier.text;
	dict["审核日期"]=verifyDate.text == null ? "" : verifyDate.text;
	if (printSign == '1')
		ReportPrinter.LoadAndPrint("report/materialDept/deliver/deliverApply/agentApply.xml", _dataList, dict);
	if (printSign == '0')
		ReportViewer.Instance.Show("report/materialDept/deliver/deliverApply/agentApply.xml", _dataList, dict);
}

/**
 * 增加
 */
protected function addClickHandler(event:Event):void
{
	//新增权限
	if (!checkUserRole('01'))
	{
		return;
	}
	//增加按钮
	toolBar.addToPreState()
	//设置可写
	setReadOnly(true);
	//清空当前表单
	clearForm(true, true);
	inpNo.setFocus();

}

/**
 * 修改
 */
protected function modifyClickHandler(event:Event):void
{
	if (!checkUserRole('02'))
	{
		return;
	}
	toolBar.modifyToPreState();
	setReadOnly(true);
	dataGridDetail.selectedIndex=0;
	FormUtils.fillFormByItem(patsDetail, dataGridDetail.dataProvider[0]);
	applyAmount.text="";
	applyAmount.setFocus();
}


/**
 * 删除
 */
protected function deleteClickHandler(event:Event):void
{
	//删除权限
	if (!checkUserRole('03'))
	{
		return;
	}
	Alert.show("您确定要删除当前记录？", "提示信息", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
		{
			if (e.detail == Alert.YES)
			{
				var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
					{
						Alert.show("删除成功", "提示");
						//清空当前表单
						clearForm(true, true);
						//文本不可编辑
						initPanel();
						//按钮状态
						initToolBar();
					});
				ro.deleteApply(_materialPatsMaster.autoId);
			}
		});
}


/**
 * 保存
 */
protected function saveClickHandler(event:Event):void
{
	var arry:ArrayCollection=dataGridDetail.dataProvider as ArrayCollection;
	//保存权限
	if (!checkUserRole('04'))
	{
		return;
	}
	if (patientName.text == "")
	{
		Alert.show("病人信息不能为空!", "提示");
		return;
	}
	if (arry.length <= 0)
	{
		Alert.show("申请物资不能为空！", "提示");
		return;
	}
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
		{
			setReadOnly(false);
			findRdsById(rev.data[0].autoId);
			toolBar.saveToPreState();
			Alert.show("保存成功", "提示");
		});
	ro.saveApply(_materialPatsMaster, arry);
}

/**
 * 更具数据状态显示不同的按钮
 */
protected function stateButton(currentStatus:String):void
{
	var state:Boolean=(currentStatus == "1" ? false : true);
	toolBar.btModify.enabled=state;
	toolBar.btDelete.enabled=state;
	toolBar.btVerify.enabled=state;
	toolBar.btPrint.enabled=true;
	toolBar.btExp.enabled=true;
}

/**
 * 放弃
 */
protected function cancelClickHandler(event:Event):void
{
	Alert.show("您是否放弃当前操作吗？", "提示", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
		{
			if (e.detail == Alert.NO)
			{
				return;
			}
			//清空当前表单
			clearForm(true, true);
			//按钮状态
			initToolBar();
			//设置文本不可编辑
			setReadOnly(false);
		})
}

/**
 * 增行
 */
protected function addRowClickHandler(event:Event):void
{
	materialCode_queryIconClickHandler(event)
}

/**
 * 删行
 */
protected function delRowClickHandler(event:Event):void
{
	//光标所在位置
	var laryDetails:ArrayCollection=dataGridDetail.dataProvider as ArrayCollection;
	var i:int=laryDetails.getItemIndex(dataGridDetail.selectedItem);
	if (i < 0)
	{
		return
	}
	Alert.show("您是否删除吗？", "提示", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
		{
			if (e.detail == Alert.NO)
			{
				return;
			}
			clearDetail();
			laryDetails.removeItemAt(i);
			dataGridDetail.dataProvider=laryDetails;
			dataGridDetail.selectedIndex=i == 0 ? 0 : (i - 1);
			FormUtils.fillFormByItem(_hgroup, dataGridDetail.selectedItem);
		})
}

/**
 * 查询
 */
protected function queryClickHandler(event:Event):void
{
	var queryWin:AgentApplyQuery=PopUpManager.createPopUp(this, AgentApplyQuery, true) as AgentApplyQuery;
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
			dataGridDetail.dataProvider=rev.data[1];
			stateButton(rev.data[0].currentStatus);
			prepaymentsLeft.text=rev.data[2];
		});
	ro.findApplyDetailById(fstrAutoId);
}

/**
 * 按照住院号 查找病人详细信息
 */
protected function inpNo_keyUpHandler(event:KeyboardEvent):void
{
	// TODO Auto-generated method stub
	if (event.keyCode == Keyboard.ENTER)
	{
		var ro:RemoteObject=RemoteUtil.getRemoteObject("agentMaterialUsedImpl", function(rev:Object):void
			{
				if (rev.data[0] == null)
				{
					//清空当前表单
					clearForm(true, true);
					return;
				}
				fillRdsMaster(rev.data[0]);
				masterEvaluate(rev);
				storageCode.setFocus();
				storageCode.openDropDown();

			});
		ro.findByPatientId(inpNo.text);
	}
}

/**
 * 查询批号
 */
protected function batch_queryIconClickHandler():void
{
	if (dataGridDetail.selectedItem)
	{
		var x:int=0;
		var y:int=this.parentApplication.screen.height - 345;
		MaterialDictShower.showBatchNoChooser(dataGridDetail.selectedItem.materialId, storageCode.selectedItem.storageCode, null, function(rev:Object):void
			{
				if (dataGridDetail.selectedItem)
				{
					batchs.text=rev.batch;
					dataGridDetail.selectedItem.batch=rev.batch;
					dataGridDetail.selectedItem.availDate=rev.availDate;
					dataGridDetail.selectedItem.factoryCode=rev.factoryCode;
					dataGridDetail.selectedItem.factoryName=rev.factoryName;
				}
			}, x, y);
	}

}

/**
 * 给主记录文本赋值
 */
protected function masterEvaluate(rev:Object):void
{
	FormUtils.fillFormByItem(patsMaster, rev.data[0]);
	FormUtils.selectComboItem(storageCode,'storageCode',rev.data[0].storageCode);
	var aplyDoctor:String=rev.data[0].doctorInCharge == null ? rev.data[0].applyDoctor : rev.data[0].doctorInCharge;
	var consultingDoctor1:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', aplyDoctor);
	var deptcode:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', rev.data[0].deptCode);
	var wardcode:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', rev.data[0].wardCode);
	consultingDoctor.text=consultingDoctor1 == null ? null : consultingDoctor1.personIdName;
	deptCode.text=deptcode == null ? null : deptcode.deptName;
	wardCode.text=wardcode == null ? null : wardcode.deptName;
	patientName.text=rev.data[0].personName == null ? patientName.text : rev.data[0].personName;
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
	if (this.parentDocument is WinModual)
	{
		PopUpManager.removePopUp(this.parentDocument as IFlexDisplayObject);
		return;
	}
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