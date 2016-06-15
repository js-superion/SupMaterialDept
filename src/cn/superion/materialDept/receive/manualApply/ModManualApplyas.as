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
import cn.superion.materialDept.receive.manualApply.view.PurchaseApplyQueryCon;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialPlanDetail;
import cn.superion.vo.material.MaterialPlanMaster;
import cn.superion.vo.material.MaterialProvideDetail;
import cn.superion.vo.material.MaterialProvideMaster;

import flash.external.ExternalInterface;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.events.CloseEvent;
import mx.events.FlexEvent;
import mx.events.ListEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;

import spark.events.IndexChangeEvent;
import spark.events.TextOperationEvent;

private static const MENU_NO:String="0107";
public var DESTANATION:String="deptApplyImpl";

//主记录
public var _materialPlanMaster:MaterialProvideMaster=new MaterialProvideMaster();

//查询主记录ID列表
public var arrayAutoId:Array=new Array();
//当前页，翻页用
public var currentPage:int=0;
[Bindable]
public var _dataProvider:ArrayCollection = new ArrayCollection();
/**
 * 初始化当前窗口
 * */
public function doInit():void
{
	//重新注册客户端对应的服务端类
	registerClassAlias("cn.superion.material.entity.MaterialProvideMaster", MaterialProvideMaster);
	registerClassAlias("cn.superion.material.entity.MaterialProvideDetail", MaterialProvideDetail);
	//放大镜不可手动输入
	preventDefaultForm();
	initToolBar();
	
	var result:ArrayCollection =ObjectUtil.copy(AppInfo.currentUserInfo.storageList) as ArrayCollection;
	var newArray:ArrayCollection = new ArrayCollection();
	for each(var it:Object in result){
		if(it.type == '1'||it.type == '3'){
			newArray.addItem(it);
		}
	}
	storageCode.dataProvider=newArray;//AppInfo.currentUserInfo.storageList;
	storageCode.selectedIndex=0;
	
	deptCode.textInput.editable=false;
	
	deptCode.dataProvider = AppInfo.currentUserInfo.deptList;
	//
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
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.btAdd, toolBar.btModify, toolBar.btDelete, toolBar.btCancel, toolBar.btSave, toolBar.btVerify, toolBar.btAddRow, toolBar.btDelRow, toolBar.btQuery, toolBar.btFirstPage, toolBar.btPrePage, toolBar.btNextPage, toolBar.btLastPage, toolBar.btExit, toolBar.imageList1, toolBar.imageList2, toolBar.imageList3, toolBar.imageList5, toolBar.imageList6];
	var laryEnables:Array=[toolBar.btAdd, toolBar.btQuery, toolBar.btExit];
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 表头设置只读或读写状态
 */
private function setReadOnly(boolean:Boolean):void
{
//	FormUtils.setFormItemEditable(allPanel, boolean);
	addPanel.visible=boolean;
	addPanel.includeInLayout=boolean;
}

/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{

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
	FormUtils.clearForm(addPanel);
}

/**
 * 清空主记录
 */
public function clearMaster():void
{
	FormUtils.clearForm(allPanel);
	gridDetail.dataProvider=null;
	billDate.selectedDate=new Date;
	_materialPlanMaster=new MaterialProvideMaster();
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
protected function amountKey(e:KeyboardEvent, fcontrolNext:*):void
{
	if (e.keyCode == Keyboard.ENTER)
	{
		if (!gridDetail.selectedItem)
		{
			return;
		}
		if ((gridDetail.selectedItem.amount) <= 0)
		{
			return;
		}
		fcontrolNext.setFocus();
	}
}


/**
 * 物资编码KeyUp事件
 */
protected function materialCode_keyUpHandler(event:KeyboardEvent):void
{
	// TODO Auto-generated method stub
	if (event.keyCode != Keyboard.ENTER)
	{
		return;
	}
}

/**
 * 供应商字典
 */
protected function productCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict(function(rev:Object):void
		{
			event.target.text=rev.providerName;
			if (gridDetail.selectedItem)
			{
				gridDetail.selectedItem.salerCode=rev.providerId;
				gridDetail.selectedItem.salerName=rev.providerName;
			}
			gridDetail.invalidateList();
		}, x, y);
}

/**
 * 部门字典
 */
protected function deptCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict(function(rev:Object):void
		{
			event.target.text=rev.deptName;
			_materialPlanMaster.deptCode=rev.deptCode;
		}, x, y);
}

/**
 * 人物档案字典
 */
protected function personId_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict(function(rev:Object):void
		{
			event.target.text=rev.personIdName;
			_materialPlanMaster.personId=rev.personId;
		}, x, y);
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
	DictWinShower.showMaterialDictNew(lstorageCode, '', '', true, function(faryItems:Array):void
		{
			fillIntoGrid(faryItems);
		}, x, y);
}

/**
 * 自动完成表格回调
 * */
private function fillIntoGrid(fItem:Array):void
{
//	amount.setFocus();
	
	var laryDetails:ArrayCollection=gridDetail.dataProvider as ArrayCollection;
	//放大镜取出的值、赋值
	for(var i:int=0;i<fItem.length;i++)
	{
		var materialPlanDetail:MaterialPlanDetail=new MaterialPlanDetail();
		materialPlanDetail=fillDetailForm(fItem[i]);
		laryDetails.addItem(materialPlanDetail);
	}
	gridDetail.dataProvider=laryDetails;
	gridDetail.selectedIndex=laryDetails.length - 1;
}

/**
 * 明细表单赋值
 */
private function fillDetailForm(faryItems:Object):MaterialPlanDetail
{
	var materialPlanDetail:MaterialPlanDetail=new MaterialPlanDetail();
	//物资编码
	materialPlanDetail.materialCode=faryItems.materialCode;
	//物资Id
	materialPlanDetail.materialId=faryItems.materialId;
	//物资类型
	materialPlanDetail.materialClass=faryItems.materialClass;
	//物资名称
	materialPlanDetail.materialName=faryItems.materialName;
	//规格型号
	materialPlanDetail.materialSpec=faryItems.materialSpec;
	//单位
	materialPlanDetail.materialUnits=faryItems.materialUnits;
	//进价
	materialPlanDetail.tradePrice=faryItems.tradePrice;
	materialPlanDetail.tradeMoney=faryItems.tradePrice;
	//售价金额
	materialPlanDetail.retailMoney=faryItems.retailPrice;
	//售价
	materialPlanDetail.retailPrice=faryItems.retailPrice;
	//现存量
	materialPlanDetail.currentStockAmount=faryItems.safeStockAmount;
	//全院现存量
	materialPlanDetail.totalCurrentStockAmount=faryItems.safeStockAmount;
	//初始数量
	materialPlanDetail.amount=1;
	materialPlanDetail.chargeSign = faryItems.chargeSign;//收费标示；
	materialPlanDetail.classOnAccount = faryItems.accountClass;//会计分类；
	//需求日期
	materialPlanDetail.requireDate=new Date;
	//已生成订单数	ORDER_AMOUNT
	materialPlanDetail.orderAmount=0;
	//订货日期
	materialPlanDetail.adviceBookDate=new Date;
	return materialPlanDetail;
}

/**
 * 给主记录赋值
 */
private function fillRdsMaster():void
{
	_materialPlanMaster.billNo=billNo.text == "" ? null : billNo.text;
	_materialPlanMaster.billDate=billDate.selectedDate;
	_materialPlanMaster.remark=remark.text == "" ? null : remark.text;
	_materialPlanMaster.accountRemain = 0;
	_materialPlanMaster.manualSign = '1';
	_materialPlanMaster.deptCode = deptCode.selectedItem.deptCode;//2013.01.24
	_materialPlanMaster.storageCode = storageCode.selectedItem.storageCode;
	var lstBloodRdsDetail:ArrayCollection=gridDetail.dataProvider as ArrayCollection;
	for (var i:int=0; i <= lstBloodRdsDetail.length - 1; i++)
	{
		_materialPlanMaster.totalCosts=_materialPlanMaster.totalCosts + Number(lstBloodRdsDetail[i].tradeMoney);
	}
}


protected function gridDetail_clickHandler(event:MouseEvent):void
{
	// TODO Auto-generated method stub
	if (!gridDetail.selectedItem)
	{
		return;
	}
	FormUtils.fillFormByItem(addPanel, gridDetail.selectedItem);
//	var salerCodeObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict, 'provider', salerCode.text);
}

/**
 * 填充当前表单
 */
protected function gdItems_itemClickHandler(event:ListEvent):void
{
	// TODO Auto-generated method stub
	FormUtils.fillFormByItem(addPanel, gridDetail.selectedItem);
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
 * 计算当前页
 * */
private function preparePrintData(faryData:ArrayCollection):void
{
	var rdBillNo:String=""
	var pageNo:int=0;
	for (var i:int=0; i < faryData.length; i++)
	{
		var item:Object=faryData.getItemAt(i);
		if (item.rdBillNo != rdBillNo)
		{
			rdBillNo=item.rdBillNo
			pageNo++;
		}
		item.factoryName=!item.factoryName ? '' : item.factoryName
		item.pageNo=pageNo;
		item.factoryName=item.factoryName.substr(0, 6);
		item.nameSpec=item.materialName + " " + (item.materialSpec == null ? "" : item.materialSpec) + " " + (item.salerName == null ? "" : item.salerName);
	}
}

/**
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	var _dataList:ArrayCollection=gridDetail.dataProvider as ArrayCollection;
	var dict:Dictionary=new Dictionary();
	preparePrintData(_dataList);
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="采购申请处理";
	dict["制表人"]=AppInfo.currentUserInfo.userName;
	dict["单据编号"]=billNo.text;
	dict["单据日期"]=DateField.dateToString(DateField.stringToDate(billDate.text, "YYYY-MM-DD"), "YYYY-MM-DD");
	dict["制单人"]=maker.text;
	dict["审核人"]=verifier.text;
	if (printSign == '1')
		ReportPrinter.LoadAndPrint("report/material/purchase/purchaseApply.xml", _dataList, dict);
	if (printSign == '0')
		ReportViewer.Instance.Show("report/material/purchase/purchaseApply.xml", _dataList, dict);
}
/**
 * 增加
 */
protected function addClickHandler(event:Event):void
{
	//新增权限
//	if (!checkUserRole('01'))
//	{
//		return;
//	}
	//增加按钮
	toolBar.addToPreState()
	//设置可写
	setReadOnly(true);
	billNo.text = billDate.text = remark.text = '';
	gridDetail.dataProvider = null;
	//清空当前表单
	addRowClickHandler(null);
	_materialPlanMaster=new MaterialProvideMaster();
	storageCode_changeHandler(null);

}

/**
 * 修改
 */
protected function modifyClickHandler(event:Event):void
{
//	if (!checkUserRole('02'))
//	{
//		return;
//	}
	toolBar.modifyToPreState();
	setReadOnly(true);
}


/**
 * 删除
 */
protected function deleteClickHandler(event:Event):void
{
	//删除权限
//	if (!checkUserRole('03'))
//	{
//		return;
//	}
	if(_materialPlanMaster.currentStatus == '1'){
		Alert.show("已审核的单据不能删除", "提示");
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
				ro.deleteApply(_materialPlanMaster.autoId);
			}
		});
}


/**
 * 仓库改变时
 * */
protected function storageCode_changeHandler(event:IndexChangeEvent):void
{
	// TODO Auto-generated method stub
//	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION,function(rev:Object):void{
//		if(rev.data.length>0){
//			deptCode.text = rev.data[0][1];
//		}
//		else
//		{
//			deptCode.text = "";
//		}
//	});
//	ro.findDeptByStorageCode(storageCode.selectedItem.storageCode);
}

/**
 * 保存
 */
protected function saveClickHandler(event:Event):void
{
	//保存权限
//	if (!checkUserRole('04'))
//	{
//		return;
//	}
	if (!validateMaster())
	{
		return;
	}
	toolBar.btSave.enabled=false;
	fillRdsMaster();
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
		{
			initToolBar();
			setReadOnly(false);
			findRdsById(rev.data[0].autoId);
			Alert.show("保存成功", "提示");
		});
	ro.saveApply(_materialPlanMaster, gridDetail.dataProvider);
}


/**
 * 更具数据状态显示不同的按钮
 */
protected function stateButton(currentStatus:String):void
{
	var state:Boolean=(currentStatus == "2" ? false : true);
	toolBar.btAdd.enabled=true;
	toolBar.btModify.enabled=state;
	toolBar.btDelete.enabled=state;
	toolBar.btVerify.enabled=state;
	toolBar.btPrint.enabled=!state;
	toolBar.btExp.enabled=!state;
}

/**
 * 保存前验证主记录
 */
private function validateMaster():Boolean
{
	var state:Boolean=true;
	if (deptCode.textInput.text == '')
	{
		Alert.show("请输入部门", "提示");
		return state=false;
	}
	if (remark.text == '')
	{
		Alert.show("请输入申请原因", "提示");
		return state=false;
	}
	
	var lstBloodRdsDetail:ArrayCollection=gridDetail.dataProvider as ArrayCollection;
	for (var i:int=0; i <= lstBloodRdsDetail.length - 1; i++)
	{
		if (lstBloodRdsDetail[i].materialName =='')
		{
			Alert.show("第" + (i + 1) + "条物品名称为空", "提示");
			gridDetail.selectedIndex=i;
			return state=false;
		}
		
		if (lstBloodRdsDetail[i].detailRemark ==''||lstBloodRdsDetail[i].detailRemark ==null)
		{
			Alert.show("第" + (i + 1) + "条备注为空，请输入具体说明或相关注意事项", "提示");
			gridDetail.selectedIndex=i;
			return state=false;
		}
		
//		if (lstBloodRdsDetail[i].materialSpec =='')
//		{
//			Alert.show("第" + (i + 1) + "条物品规格不能为空", "提示");
//			gridDetail.selectedIndex=i;
//			return state=false;
//		}
		
		if ((Number)(lstBloodRdsDetail[i].amount) <= 0)
		{
			Alert.show("第" + (i + 1) + "条物品数量不能<=0,请重新输入", "提示");
			gridDetail.selectedIndex=i;
			return state=false;
		}
	}
	return state;
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
 * 审核
 */
protected function verifyClickHandler(event:Event):void
{
	//审核权限
//	if (!checkUserRole('06'))
//	{
//		return;
//	}
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
		{
			Alert.show("审核成功", "提示");
			findRdsById(_materialPlanMaster.autoId);
			
		});
	_materialPlanMaster.currentStatus = '2';
	_materialPlanMaster.invoiceType = '1';
	ro.verifyApply(_materialPlanMaster.autoId,"2");
}

/**
 * 增行
 */
protected function addRowClickHandler(event:Event):void
{
	var _details:ArrayCollection = gridDetail.dataProvider as ArrayCollection;
	var materialPlanDetail:MaterialProvideDetail=new MaterialProvideDetail();
	materialPlanDetail.materialName = "";
	materialPlanDetail.amount = 1;
	materialPlanDetail.materialClass = '0';
	materialPlanDetail.materialId = '0';
	materialPlanDetail.materialCode = '0';
	materialPlanDetail.tradeMoney = 0;
	materialPlanDetail.tradePrice = 0;
	materialPlanDetail.urgentSign = '1';
	materialPlanDetail.checkAmount = 0;
	materialPlanDetail.planAmount = 0;
	materialPlanDetail.retailMoney =0;
	materialPlanDetail.retailPrice = 0;
	materialPlanDetail.sendAmount = 0;
	materialPlanDetail.wholeSaleMoney = 0;
	materialPlanDetail.wholeSalePrice = 0;
//	materialPlanDetail.
	_details.addItem(materialPlanDetail);
	gridDetail.dataProvider = _details;
	gridDetail.selectedIndex =_details.length-1;
	gridDetail.verticalScrollPosition = _details.length + 1;
	gridDetail.editedItemPosition={columnIndex:1,rowIndex:_details.length - 1}
	
//	materialCode_queryIconClickHandler(event)
}

/**
 * 删行
 */
protected function delRowClickHandler(event:Event):void
{
	//光标所在位置
	var laryDetails:ArrayCollection=gridDetail.dataProvider as ArrayCollection;
	var i:int=laryDetails.getItemIndex(gridDetail.selectedItem);
	if (i < 0)
	{
		return
	}
	clearDetail();
	laryDetails.removeItemAt(i);
	gridDetail.dataProvider=laryDetails;
	gridDetail.invalidateList();
	gridDetail.selectedIndex=gridDetail.dataProvider.length - 1;
	gridDetail.selectedIndex=i == 0 ? 0 : (i - 1);
	FormUtils.fillFormByItem(addPanel, gridDetail.selectedItem);
}

/**
 * 查询
 */
protected function queryClickHandler(event:Event):void
{
	var queryWin:PurchaseApplyQueryCon=PopUpManager.createPopUp(this, PurchaseApplyQueryCon, true) as PurchaseApplyQueryCon;
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
			_materialPlanMaster=rev.data[0];
			masterEvaluate(_materialPlanMaster);
			gridDetail.dataProvider=rev.data[1];
			stateButton(rev.data[0].currentStatus);
		});
	ro.findApplyDetailById(fstrAutoId);
}

/**
 * 给主记录赋值
 */
protected function masterEvaluate(mpm:MaterialProvideMaster):void
{
	FormUtils.fillFormByItem(this, mpm);
	var bm:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', mpm.deptCode);
	//领用部门
	var _index:int=ArrayCollUtils.findItemIndexInArray(deptCode.dataProvider,'deptCode',mpm.deptCode);
	deptCode.selectedIndex=_index;
	var yw:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', mpm.personId);
	maker.text=shiftTo(mpm.maker);
	verifier.text=shiftTo(mpm.verifier);
	remark1.text = mpm.checkAmountSign=='8'?"不同意":mpm.checkAmountSign=='9'?"同意":"未处理";
	remark2.text = (mpm.check2=='2'?"同意":mpm.check2=='1'?"不同意":"未处理")+(mpm.remark2?mpm.remark2:"");
	remark3.text = (mpm.check3=='2'?"同意":mpm.check3=='1'?"不同意":"未处理")+(mpm.remark3?mpm.remark3:"");
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
protected function shiftTo(name:String):String
{
	var makerItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', name);
	var maker:String=makerItem == null ? "" : makerItem.personIdName;
	return maker;
}