/**
 *		其他入库处理模块
 *		author:吴小娟   2011.02.23
 *		checked by
 **/
import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.DateUtil;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.ObjectUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialDept.receive.send.view.ReceiveOtherFilter;
import cn.superion.materialDept.util.DefaultPage;
import cn.superion.materialDept.util.MainToolBar;
import cn.superion.materialDept.util.MaterialDictShower;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
registerClassAlias("cn.superion.materialDept.entity.MaterialRdsDetailDept", MaterialRdsDetailDept);
import cn.superion.vo.material.MaterialRdsDetailDept;
registerClassAlias("cn.superion.materialDept.entity.MaterialRdsMasterDept", MaterialRdsMasterDept);
import cn.superion.vo.material.MaterialRdsMasterDept;
import cn.superion.base.config.ParameterObject;
import cn.superion.vo.material.MaterialProvideDetail;
import cn.superion.vo.material.MaterialProvideMaster;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.core.IFlexDisplayObject;
import mx.core.UIComponent;
import mx.events.CloseEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;
//工具栏中要显示组件数组
public var iaryDisplays:Array=[];
//工具栏中能使用组件数组
private var _aryEnableds:Array=[];
//菜单号
private const MENU_NO:String="0106";
//是否允许零出库
private const PARA_CODE:String="0601";
//服务端destination
public static const DESTINATION:String='sendImpl';
//保存类型
private var _strSaveType:String;
//零库存标志
private var _zeroStock:Boolean=false;
//保质期标志
private var _qualitySign:Boolean=false;
//批号标志
private var _batchSign:Boolean=false;
//是否执行查找库存
public var iqueryStockSign:Boolean=false;
//是否点击修改按钮
private var _btModifyBeClicked:Boolean=false;
//右键过滤，1表示可用，0不可用
public var imenuItemsEnableValues:Object=['1', '1'];
//当前主记录
public var imaterialRdsMasterDept:MaterialRdsMasterDept=new MaterialRdsMasterDept();
//条件对象
private static var _condition:Object={};


/**
 * 初始化
 * */
protected function doInit():void
{
	initToolBar();
	initPanel();
	initTextInputIcon();
	allowZeroStock();
}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	parentDocument.title="配送物资验收";
	//  显示组件：打印，输出，增加，修改，删除，保存，放弃，审核，增行，删行，查询，首张，上一张，下一张，末张，退出	
	iaryDisplays=[btToolBar.btQuery,btToolBar.btSave,btToolBar.btPrint, btToolBar.btExp, btToolBar.btExit];
	//  可用组件：增加，查询，退出
	_aryEnableds=[btToolBar.btQuery,btToolBar.btSave,btToolBar.btPrint, btToolBar.btExp, btToolBar.btExit];
	//  组件初始化
	MainToolBar.showSpecialBtn(btToolBar, iaryDisplays, _aryEnableds, true);
}

/**
 * 初始化面板
 * */
private function initPanel():void
{
	//  初始化不可编辑,增加项隐藏
//	invoiceType1.enabled=false;
//	invoiceType2.enabled=false;
//	FormUtils.setFormItemEditable(allPanel, false);
//	masterPanel.enabled=false;
//	rdType.enabled=false;
//	operationType.enabled=false;
//	addPanel.includeInLayout=false;
//	addPanel.visible=false;
//	//  仓库
//	var deptItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', AppInfo.currentUserInfo.deptCode);
//	storageCode.text=deptItem == null ? "" : deptItem.deptName;
//	//  默认选中蓝字
//	invoiceType1.selected=true;
//	//  进价，生产厂家文字样式为蓝色
//	tradePriceText.styleName="myFormItemStyle";
//	factoryCodeText.styleName="myFormItemStyle";
//	//  批号（放大镜）不可见
//	batch.visible=false;
//	batch.includeInLayout=false;
//	//  批号（文本框）可见
//	batch2.visible=true;
//	batch2.includeInLayout=true;
//	//  根据系统登录的选择条件，对界面上的 “拼音简码” 与 “五笔简码” 进行切换
//	if (AppInfo.currentUserInfo.inputCode == "PHO_INPUT")
//	{
//		this.txtPhoLabel.label="拼音简码";
//	}
//	else
//	{
//		this.txtPhoLabel.label="五笔简码";
//	}
	//初始化本地按钮
	var menuItemsName:Array=['其他入库单'];
	var functions:Array=[otherImportQuery];
	gdReceiveOtherList.contextMenu=initContextMenu(gdReceiveOtherList, menuItemsName, functions);
	gdReceiveOtherList.contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, menuItemEnabled);
}

/**
 * 初始化放大镜输入框
 * */
private function initTextInputIcon():void
{
//	deptCode.txtContent.editable=false;
//	personId.txtContent.editable=false;
//	factoryCode.txtContent.editable=false;
//	batch.txtContent.editable=false;
}

/**
 * 初始化是否允许零出库
 * */
private function allowZeroStock():void
{
	//选中的是红字单据时，查找当前系统参数，判断是否允许零出库
	var ro:RemoteObject=RemoteUtil.getRemoteObject('centerSysParamImpl', function(rev:Object):void
		{
			if (rev.data[0] == '1')
			{
				_zeroStock=true; //允许零出库
			}
			if (rev.data[0] == '0')
			{
				_zeroStock=false; //不允许零出库
			}
		});
	ro.findSysParamByParaCode(PARA_CODE);
}

/**
 * 放大镜输入框键盘处理方法
 * */
protected function textInputIcon_keyUpHandler(event:KeyboardEvent, fctrNext:Object):void
{
	FormUtils.textInputIconKeyUpHandler(event, imaterialRdsMasterDept, fctrNext);
}

/**
 * 右键过滤响应方法
 * */
private function otherImportQuery(e:Event):void
{
	var win:ReceiveOtherFilter=PopUpManager.createPopUp(this, ReceiveOtherFilter, true) as ReceiveOtherFilter;
//	win.iparentWin=this;
	PopUpManager.centerPopUp(win);
	win.y=65;
}

private function initContextMenu(comp:UIComponent, menuItemsName:Array, functions:Array):ContextMenu
{
	var contextMenu:ContextMenu=new ContextMenu();
	contextMenu.hideBuiltInItems();
	var menuItems:Array=[];
	for (var i:int=0; i < menuItemsName.length; i++)
	{
		var menuItem:ContextMenuItem=new ContextMenuItem(menuItemsName[i]);
		menuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, functions[i]);
		menuItems.push(menuItem);
	}
	contextMenu.customItems=menuItems;
	gdReceiveOtherList.contextMenu=contextMenu;
	return contextMenu;
}

/**
 * 响应右键弹出事件
 * 根据imenuItemsEnableValues中的值，分别对应右键菜单项是否可用
 * */
private function menuItemEnabled(e:ContextMenuEvent):void
{
	var aryMenuItems:Array=e.target.customItems;
	for (var i:int=0; i < aryMenuItems.length; i++)
	{
		aryMenuItems[i].enabled=imenuItemsEnableValues[i] == "1" ? true : false;
	}
}

/**
 * 根据主记录ID查询其他入库单据主记录和明细记录列表
 * 参数：fstrId 主记录id
 * */
public function getDataByAutoId(fstrId:String):void
{
	var remoteObj:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
		{
			//当前状态为0、业务类型不为104时，修改、删除、审核按钮亮化
			if(rev.data==null||rev.data.length<=0||rev.data[0]==null||rev.data[1]==null)
			{
				return;
			}
			if (rev.data[0].currentStatus == '0' && rev.data[0].operationType != '104')
			{
				btToolBar.btModify.enabled=true;
				btToolBar.btDelete.enabled=true;
				btToolBar.btVerify.enabled=true;
			}
			//当前状态为0、业务类型为104时，修改、删除按钮灰化，审核按钮亮化
			else if (rev.data[0].currentStatus == '0' && rev.data[0].operationType == '104')
			{
				btToolBar.btModify.enabled=false;
				btToolBar.btDelete.enabled=false;
				btToolBar.btVerify.enabled=true;
			}
			//当前状态为1时，修改、删除、审核按钮灰化
			else
			{
				btToolBar.btModify.enabled=false;
				btToolBar.btDelete.enabled=false;
				btToolBar.btVerify.enabled=false;
			}
			//主界面赋值
			var lrdsMaster:MaterialRdsMasterDept = rev.data[0] as MaterialRdsMasterDept;
			imaterialRdsMasterDept=lrdsMaster;
			fillPanelByItem(imaterialRdsMasterDept, rev.data[1]);
		});
	remoteObj.findRdsDetailById(fstrId);
}

/**
 * 根据主记录和明细记录填充页面
 * 参数：
 *    fmaterialRdsMaster 主记录
 *    faryDetails 明细记录
 * */
public function fillPanelByItem(fmaterialRdsMasterDept:MaterialRdsMasterDept, faryDetails:Object=null):void
{
	if (faryDetails == null)
	{
		faryDetails=new ArrayCollection();
	}
	if(fmaterialRdsMasterDept==null)
	{
		Alert.show("操作错误，请重新进入系统！","提示");
		return;
	}
	FormUtils.fillFormByItem(allPanel, fmaterialRdsMasterDept);
//	if (fmaterialRdsMasterDept.invoiceType == '1')
//	{
//		invoiceType1.selected=true;
//		invoiceType2.selected=false;
//	}
//	if (fmaterialRdsMasterDept.invoiceType == '2')
//	{
//		invoiceType1.selected=false;
//		invoiceType2.selected=true;
//	}
//	if (fmaterialRdsMasterDept.invoiceType == null)
//	{
//		invoiceType.selection=invoiceType1.selected == true ? invoiceType1 : invoiceType2;
//	}
//	//  仓库
//	var storageCodeItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', AppInfo.currentUserInfo.deptCode);
//	storageCode.text=storageCodeItem == null ? "" : storageCodeItem.deptName;
//	// 入库类别
//	FormUtils.selectComboItem(rdType, 'receviceType', fmaterialRdsMasterDept.rdType);
//	// 部门
//	var deptItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', fmaterialRdsMasterDept.deptCode);
//	deptCode.txtContent.text=deptItem == null ? "" : deptItem.deptName;
//	// 经手人
//	var personItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', fmaterialRdsMasterDept.personId);
//	personId.txtContent.text=personItem == null ? "" : personItem.personIdName;
	// 列表收发存明细
	gdReceiveOtherList.dataProvider=faryDetails;
	// 制单人
	var makerItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', fmaterialRdsMasterDept.maker);
//	maker.text=makerItem == null ? "" : makerItem.personIdName;
	// 审核人
	var verifierItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', fmaterialRdsMasterDept.verifier);
//	verifier.text=verifierItem == null ? "" : verifierItem.personIdName;
}

/**
 * 设置主记录id数组到控制栏中
 * 参数：faryIds id数组
 * */
public function setIdsArrayToToolBar(faryIds:ArrayCollection):void
{
	if (faryIds == null || faryIds.length == 0)
	{
		return;
	}
	btToolBar.arc=faryIds;
	btToolBar.callback=getDataByAutoId;
}

/**
 * 自动完成表格回填
 * */
private function showItemDict(fmaterialItem:Object):void
{
	var laryDetails:ArrayCollection=gdReceiveOtherList.dataProvider as ArrayCollection;
	laryDetails=laryDetails || new ArrayCollection();
	var lmaterialNew:MaterialRdsDetailDept=new MaterialRdsDetailDept();
	initObject(lmaterialNew);
	ObjectUtils.mergeObject(fmaterialItem, lmaterialNew);
//	lmaterialNew.madeDate=madeDate.selectedDate;
//	lmaterialNew.availDate=availDate.selectedDate;
//	FormUtils.fillFormByItem(addPanel, lmaterialNew);
//	//生产厂家
//	factoryCode.txtContent.text=lmaterialNew.factoryName;
//	//现存量
//	currentStockAmount.text=fmaterialItem.stockAmount;
//	//选中蓝单时动态改变批号和有效期限颜色
//	_qualitySign=fmaterialItem.qualitySign == '1' ? true : false;
//	_batchSign=fmaterialItem.batchSign == '1' ? true : false;
//	if (_batchSign && invoiceType1.selected || invoiceType2.selected)
//	{
//		batchText.styleName="myFormItemStyle";
//	}
//	else
//	{
//		batchText.styleName="";
//	}
//	if (_qualitySign && invoiceType1.selected)
//	{
//		madeDateText.styleName="myFormItemStyle";
//		availDateText.styleName="myFormItemStyle";
//	}
//	else
//	{
//		madeDateText.styleName="";
//		availDateText.styleName="";
//	}
//	laryDetails.addItem(lmaterialNew);
//	gdReceiveOtherList.dataProvider=laryDetails;
//	gdReceiveOtherList.selectedItem=lmaterialNew;
//	btToolBar.btDelRow.enabled=true;
//	phoInputCode.text="";
//	//数量设置焦点
//	amount.setFocus();
}

/**
 * 重置对象中的所有NaN为0
 * */
private function initObject(fobj:Object):void
{
	var lobjShadow:Object=ObjectUtils.reCreateASimpleObject(fobj);
	for (var field:String in lobjShadow)
	{
		if (isNaN(fobj[field]))
		{
			fobj[field]=0;
		}
	}
}

/**
 * 打印输出
 * @param 参数说明
 * 		  lstrPurview 权限编号;
 * 		  isPrintSign 打印输出标识。直接打印：1，输出：0。
 */
protected function btToolBar_printExpClickHandler(lstrPurview:String, isPrintSign:String):void
{
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, lstrPurview))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}
	var _dataList:ArrayCollection=gdReceiveOtherList.dataProvider as ArrayCollection;
	var dict:Dictionary=new Dictionary();
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
//	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
//	dict["主标题"]="其他入库处理";
//	dict["制表人"]=AppInfo.currentUserInfo.userName;
//	dict["仓库"]=storageCode.text;
//	dict["入库类别"]=rdType.selectedItem.receviceTypeName;
//	dict["入库单号"]=billNo.text;
//	dict["入库日期"]=billDate.text;
//	dict["业务类型"]=operationType.text;
//	dict["业务号"]=operationNo.text;
//	dict["部门"]=deptCode.txtContent.text;
//	dict["业务员"]=personId.txtContent.text;
//	dict["备注"]=remark.text;
//	dict["制单人"]="　" + maker.text;
//	dict["审核人"]="　" + verifier.text;
//	dict["审核日期"]="　" + verifyDate.text;
//	dict["记账人"]="　" + accounter.text;
	var lstrReportFile:String="report/materialDept/receive/receiveOther.xml";
	if (isPrintSign == '1')
	{
		ReportPrinter.LoadAndPrint(lstrReportFile, _dataList, dict);
		return;
	}
	ReportViewer.Instance.Show(lstrReportFile, _dataList, dict);
}

/**
 * 增加其他入库单事件响应方法
 * */
protected function btToolBar_addClickHandler(event:Event):void
{
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, "01"))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}
	//未点击修改按钮
	_btModifyBeClicked=false;
	//右键过滤（其他入库单）灰化
	imenuItemsEnableValues=['0', '0'];
	//设置可以查询现存量
	iqueryStockSign=true;
	//可用组件：放弃、保存、增行、删行、退出按钮可用
	_aryEnableds=[btToolBar.btCancel, btToolBar.btSave, btToolBar.btAddRow, btToolBar.btDelRow, btToolBar.btExit];
	MainToolBar.showSpecialBtn(btToolBar, iaryDisplays, _aryEnableds, true);
	imaterialRdsMasterDept=new MaterialRdsMasterDept();
	fillPanelByItem(imaterialRdsMasterDept);
//	rdType.selectedIndex=1;
//	//设置可以编辑
//	invoiceType1.enabled=true;
//	invoiceType2.enabled=true;
//	FormUtils.setFormItemEditable(masterPanel, true);
//	FormUtils.setFormItemEditable(addPanel, true);
//	masterPanel.enabled=true;
//	addPanel.includeInLayout=true;
//	addPanel.visible=true;
//	billNo.setFocus();
//	amount.text="";
//	operationType.text="其他入库";
//	billDate.text=DateUtil.dateToString(new Date(), 'YYYY-MM-DD');
}

/**
 * 修改其他入库单事件响应方法
 * */
protected function btToolBar_modifyClickHandler(event:Event):void
{
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, "02"))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}
	//点击修改按钮
	_btModifyBeClicked=true;
	//记录修改之前按钮状态
	btToolBar.holdTurnPageRawState();
	//设置可以查询现存量
	iqueryStockSign=true;
	//文本可以编辑
//	invoiceType1.enabled=true;
//	invoiceType2.enabled=true;
//	FormUtils.setFormItemEditable(masterPanel, true);
//	FormUtils.setFormItemEditable(addPanel, true);
//	masterPanel.enabled=true;
//	addPanel.visible=true;
//	addPanel.includeInLayout=true;
//	if (invoiceType1.selected)
//	{
//		tradePrice.enabled=true;
//		tradePriceText.styleName="myFormItemStyle";
//		factoryCode.enabled=true;
//		factoryCodeText.styleName="myFormItemStyle";
//		batchText.styleName="";
//		batch.visible=false;
//		batch.includeInLayout=false;
//		batch2.visible=true;
//		batch2.includeInLayout=true;
//		madeDate.enabled=true;
//		madeDateText.styleName="";
//		availDate.enabled=true;
//		availDateText.styleName="";
//	}
//	else
//	{
//		tradePrice.enabled=false;
//		tradePrice.editable=false;
//		tradePriceText.styleName="";
//		factoryCode.enabled=false;
//		factoryCodeText.styleName="";
//		madeDate.enabled=false;
//		madeDateText.styleName="";
//		availDate.enabled=false;
//		availDateText.styleName="";
//		batchText.styleName="myFormItemStyle";
//		batch2.visible=false;
//		batch2.includeInLayout=false;
//		batch.visible=true;
//		batch.includeInLayout=true;
//	}
	//可用组件：放弃、保存、增行、删行、退出按钮可用
	var _aryEnableds:Array=[btToolBar.btCancel, btToolBar.btSave, btToolBar.btAddRow, btToolBar.btDelRow, btToolBar.btExit]
	MainToolBar.showSpecialBtn(btToolBar, iaryDisplays, _aryEnableds, true);
	//
	if (gdReceiveOtherList.dataProvider.length > 0)
	{
		gdReceiveOtherList.selectedIndex=gdReceiveOtherList.dataProvider.length - 1;
//		amount.text=gdReceiveOtherList.selectedItem.amount;
//		materialName.text=gdReceiveOtherList.selectedItem.materialName;
//		tradePrice.text=gdReceiveOtherList.selectedItem.tradePrice;
//		factoryCode.text=gdReceiveOtherList.selectedItem.factoryName;
//		madeDate.text=DateUtil.dateToString(gdReceiveOtherList.selectedItem.madeDate, 'YYYY-MM-DD');
//		batch2.text=gdReceiveOtherList.selectedItem.batch;
//		batch.text=gdReceiveOtherList.selectedItem.batch;
//		availDate.text=DateUtil.dateToString(gdReceiveOtherList.selectedItem.availDate, 'YYYY-MM-DD');
//		detailRemark.text=gdReceiveOtherList.selectedItem.detailRemark;
//		currentStockAmount.text=gdReceiveOtherList.selectedItem.currentStockAmount;
	}
}

/**
 * 删除其他入库单事件响应方法
 * */
protected function btToolBar_deleteClickHandler(event:Event):void
{
//	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, "03"))
//	{
//		Alert.show("您无此按钮操作权限！", "提示");
//		return;
//	}
//	Alert.show("您是否要删除当前单据：" + billNo.text + " ？", "提示信息", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
//		{
//			if (e.detail == Alert.YES)
//			{
//				var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
//					{
//						if (!rev.success)
//						{
//							Alert.show(rev.error, '提示信息');
//							return;
//						}
//						//保存后直接删除 && 查找后只有一张其他入库单时删除
//						if(btToolBar.arc == null || btToolBar.arc.length == 1)
//						{
//							btToolBar.turnPageBtnStatus(false);
//							//可用按钮组：增加，查询，退出
//							_aryEnableds=[btToolBar.btAdd, btToolBar.btQuery, btToolBar.btExit];
//							MainToolBar.showSpecialBtn(btToolBar, iaryDisplays, _aryEnableds, true);
//							fillPanelByItem(new MaterialRdsMasterDept());
//							billDate.text=DateUtil.dateToString(new Date(), 'YYYY-MM-DD');
//							return;
//						}
//						//查找后有多张其他入库单时删除，显示下一张其他入库单
//						btToolBar.deleteSuccess=true;
//						if(btToolBar.arc.length == 0)
//						{
//							fillPanelByItem(new MaterialRdsMasterDept());
//							billDate.text=DateUtil.dateToString(new Date(), 'YYYY-MM-DD');
//						}
//					})
//				ro.deleteRds(imaterialRdsMasterDept.autoId);
//			}
//		});
}

/**
 * 保存其他入库单事件响应方法
 * */
protected function btToolBar_saveClickHandler(event:Event):void
{
//	registerClassAlias("cn.superion.materialDept.entity.MaterialRdsMasterDept", MaterialRdsMasterDept);
	//表头输入项
//	imaterialRdsMasterDept.invoiceType=invoiceType1.selected ? '1' : '2';
//	imaterialRdsMasterDept.storageCode=AppInfo.currentUserInfo.deptCode;
//	imaterialRdsMasterDept.rdType=rdType.selectedItem.receviceType;
//	imaterialRdsMasterDept.billNo=billNo.text;
//	imaterialRdsMasterDept.billDate=billDate.selectedDate;
//	imaterialRdsMasterDept.operationType="109";
//	imaterialRdsMasterDept.operationNo=operationNo.text;
//	imaterialRdsMasterDept.remark=remark.text;
	//判断是增加还是修改
//	if (imaterialRdsMasterDept.autoId == "" || imaterialRdsMasterDept.autoId == null)
//	{
//		_strSaveType="add";
//	}
//	else
//	{
//		_strSaveType="update";
//	}
	//表体
	var materialProvideMaster:MaterialProvideMaster = gdReceiveOther.selectedItem as MaterialProvideMaster;
	materialProvideMaster.sendStatus = '3';
	var materialProvideDetails:ArrayCollection=gdReceiveOtherList.dataProvider as ArrayCollection;
	if (materialProvideDetails.length == 0)
	{
		Alert.show("列表中没有物资档案信息，请录入物资明细！", "提示信息");
		return;
	}
//	for each (var lmaterialRdsDetail:MaterialRdsDetailDept in laryMaterialRdsDetails)
//	{
//		if (lmaterialRdsDetail.amount == 0)
//		{
//			Alert.show(lmaterialRdsDetail.materialName + "数量不能为空或零，请输入数量！", "提示信息", Alert.OK, null, function(e:CloseEvent):void
//				{
//					if (e.detail == Alert.OK)
//					{
//						amount.setFocus();
//					}
//				});
//			gdReceiveOtherList.selectedIndex=laryMaterialRdsDetails.getItemIndex(lmaterialRdsDetail);
//			return;
//		}
//		if (lmaterialRdsDetail.tradePrice == 0&&invoiceType1.selected)
//		{
//			Alert.show(lmaterialRdsDetail.materialName + "进价不能为空或零，请输入进价！", "提示信息");
//			tradePriceText.styleName="myFormItemStyle";
//			gdReceiveOtherList.selectedIndex=laryMaterialRdsDetails.getItemIndex(lmaterialRdsDetail);
//			return;
//		}
//		if (lmaterialRdsDetail.factoryCode == null&&invoiceType1.selected)
//		{
//			Alert.show(lmaterialRdsDetail.materialName + "生产厂家不能为空，请输入生产厂家！", "提示信息");
//			factoryCodeText.styleName="myFormItemStyle";
//			gdReceiveOtherList.selectedIndex=laryMaterialRdsDetails.getItemIndex(lmaterialRdsDetail);
//			batch2.text=gdReceiveOtherList.selectedItem.batch;
//			return;
//		}
//		if (lmaterialRdsDetail.batch == null && lmaterialRdsDetail.batchSign == "1" && invoiceType1.selected)
//		{
//			Alert.show(lmaterialRdsDetail.materialName + "实行批号管理，请输入批号！", "提示信息");
//			batchText.styleName="myFormItemStyle";
//			gdReceiveOtherList.invalidateList();
//			gdReceiveOtherList.selectedIndex=laryMaterialRdsDetails.getItemIndex(lmaterialRdsDetail);
//			FormUtils.fillFormByItem(addPanel, gdReceiveOtherList.selectedItem);
//			batch2.text=gdReceiveOtherList.selectedItem.batch;
//			return;
//		}
//		if (!lmaterialRdsDetail.madeDate && lmaterialRdsDetail.qualitySign == "1" && invoiceType1.selected || !lmaterialRdsDetail.availDate && lmaterialRdsDetail.qualitySign == "1" && invoiceType1.selected)
//		{
//			Alert.show(lmaterialRdsDetail.materialName + "实行保质期管理，请输入生产日期和有效期限！", "提示信息");
//			madeDateText.styleName="myFormItemStyle";
//			availDateText.styleName="myFormItemStyle";
//			gdReceiveOtherList.selectedIndex=laryMaterialRdsDetails.getItemIndex(lmaterialRdsDetail);
//			batch2.text=gdReceiveOtherList.selectedItem.batch;
//			return;
//		}
//		if (lmaterialRdsDetail.batch == "" && invoiceType2.selected)
//		{
//			Alert.show(lmaterialRdsDetail.materialName + "批号不能为空,请输入！", "提示信息");
//			gdReceiveOtherList.selectedIndex=laryMaterialRdsDetails.getItemIndex(lmaterialRdsDetail);
//			return;
//		}
//		//进价金额
//		lmaterialRdsDetail.tradeMoney=Number(lmaterialRdsDetail.tradePrice) * Number(lmaterialRdsDetail.amount);
//		//售价金额
//		lmaterialRdsDetail.retailMoney=Number(lmaterialRdsDetail.retailPrice) * Number(lmaterialRdsDetail.amount);
//	}
//	if (_strSaveType == "add")
//	{
//		imaterialRdsMasterDept.maker="";
//		imaterialRdsMasterDept.makeDate=null;
//	}
//	imaterialRdsMasterDept.verifier="";
//	imaterialRdsMasterDept.verifyDate=null;
//	imaterialRdsMasterDept.accounter="";

	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
		{
			if (!rev.success)
			{
				Alert.show(rev.error, "提示信息");
				return;
			}
			findRdsById1(gdReceiveOtherList.selectedItem.autoId);
			Alert.show("保存成功！","提示");
			//右键过滤其他入库单菜单亮化
//			imenuItemsEnableValues=['1', '1'];
			//入库单号为空，保存时系统自动生成返回
//			billNo.text=billNo.text == "" ? rev.data[0].billNo : billNo.text;
//			//主界面赋值
//			imaterialRdsMasterDept=rev.data[0] as MaterialRdsMasterDept;
//			fillPanelByItem(rev.data[0], rev.data[1]);
//			//表头不可编辑
//			invoiceType1.enabled=false;
//			invoiceType2.enabled=false;
//			FormUtils.setFormItemEditable(allPanel, false);
//			addPanel.visible=false;
//			addPanel.includeInLayout=false;
			//设置不可以查询现存量
//			iqueryStockSign=false;
//			//修改后保存，按钮恢复的状态
//			if (_btModifyBeClicked)
//			{
//				btToolBar.recoverToPreState();
//			}
//			//当前状态为0时，打印、输出、增加、修改、删除、审核、查找、退出按钮亮化
//			if (rev.data[0].currentStatus == '0')
//			{
//				_aryEnableds=[btToolBar.btPrint, btToolBar.btExp, btToolBar.btAdd, btToolBar.btModify, btToolBar.btDelete, btToolBar.btVerify, btToolBar.btQuery, btToolBar.btExit];
//				MainToolBar.showSpecialBtn(btToolBar, iaryDisplays, _aryEnableds, true);
//				return;
//			}
//			//此时打印、输出、增加、查找、退出按钮亮化
//			_aryEnableds=[btToolBar.btPrint, btToolBar.btExp, btToolBar.btAdd, btToolBar.btQuery, btToolBar.btExit];
//			MainToolBar.showSpecialBtn(btToolBar, iaryDisplays, _aryEnableds, true);
		})
	ro.updateSendMaterial(materialProvideMaster, materialProvideDetails);
}

/**
 * 放弃其他入库单事件响应方法
 * */
protected function btToolBar_cancelClickHandler(event:Event):void
{
	//右键过滤其他入库单菜单亮化
	imenuItemsEnableValues=['1', '1'];
	//此时增加、查找、退出按钮可用
	_aryEnableds=[btToolBar.btAdd, btToolBar.btExit, btToolBar.btQuery];
	MainToolBar.showSpecialBtn(btToolBar, iaryDisplays, _aryEnableds, true);
//	invoiceType1.enabled=false;
//	//放弃时默认选中蓝字
//	invoiceType1.selected=true;
//	tradePrice.enabled=true;
//	tradePriceText.styleName="myFormItemStyle";
//	factoryCode.enabled=true;
//	factoryCodeText.styleName="myFormItemStyle";
//	batchText.styleName="";
//	batch.visible=false;
//	batch.includeInLayout=false;
//	batch2.visible=true;
//	batch2.includeInLayout=true;
//	invoiceType2.enabled=false;
//	FormUtils.setFormItemEditable(allPanel, false);
//	rdType.selectedIndex=0;
//	operationType.enabled=false;
//	addPanel.includeInLayout=false;
//	addPanel.visible=false;
	var autoi:String=null;
	if(imaterialRdsMasterDept.autoId==null||imaterialRdsMasterDept.autoId=='')
	{
		autoi="zt"
	}
	else
	{
		autoi=imaterialRdsMasterDept.autoId
	}
	//增加其他入库单，未保存直接放弃
	if (!_btModifyBeClicked)
	{
		//清空表头和表体
		FormUtils.clearForm(allPanel);
		//  仓库
		var storageCodeItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', AppInfo.currentUserInfo.deptCode);
//		storageCode.text=storageCodeItem == null ? "" : storageCodeItem.deptName;
//		phoInputCode.text='';
		gdReceiveOtherList.dataProvider=[];
		getDataByAutoId(autoi);
		return;
	}
	//修改其他入库单，未保存直接放弃，清空表头和表体
	FormUtils.clearForm(allPanel);
	//  仓库
	var deptItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', AppInfo.currentUserInfo.deptCode);
//	storageCode.text=deptItem == null ? "" : deptItem.deptName;
//	phoInputCode.text='';
	gdReceiveOtherList.dataProvider=[];
	btToolBar.recoverToPreState();
	btToolBar.btPrint.enabled=false;
	btToolBar.btExp.enabled=false;
	getDataByAutoId(autoi);
}

/**
 * 审核其他入库单事件响应方法
 * */
protected function btToolBar_verifyClickHandler(event:Event):void
{
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, "06"))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
		{
			Alert.show("审核成功！","提示");
			imaterialRdsMasterDept=rev.data[0] as MaterialRdsMasterDept;
			var verifierItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', imaterialRdsMasterDept.verifier);
//			verifier.text=verifierItem == null ? "" : verifierItem.personIdName;
//			verifyDate.text=DateUtil.dateToString(imaterialRdsMasterDept.verifyDate, 'YYYY-MM-DD');
			btToolBar.btModify.enabled=false;
			btToolBar.btDelete.enabled=false;
			btToolBar.btVerify.enabled=false;
		})
	ro.verifyRds(imaterialRdsMasterDept.autoId);
}

/**
 * 增行按钮事件响应方法
 * */
protected function btToolBar_addRowClickHandler(event:Event):void
{
	//清空表头隐藏输入项
//	FormUtils.setFormItemEditable(addPanel, true);
//	FormUtils.clearForm(addPanel);
//	phoInputCode.text='';
//	phoInputCode.setFocus();
}

/**
 * 删行按钮事件响应方法
 * */
protected function btToolBar_delRowClickHandler(event:Event):void
{
	if (!gdReceiveOtherList.selectedItem)
	{
		Alert.show('请选中要删除的一行数据', '提示信息');
		return;
	}
	var laryMaterialRdsDetails:ArrayCollection=gdReceiveOtherList.dataProvider as ArrayCollection;
	var lintDelIndex:int=laryMaterialRdsDetails.getItemIndex(gdReceiveOtherList.selectedItem);
	laryMaterialRdsDetails.removeItemAt(lintDelIndex);
	gdReceiveOtherList.dataProvider=laryMaterialRdsDetails;
	gdReceiveOtherList.invalidateList();
	if (gdReceiveOtherList.dataProvider.length > 0)
	{
		gdReceiveOtherList.selectedIndex=gdReceiveOtherList.dataProvider.length - 1;
		//清空表头隐藏输入项
//		FormUtils.clearForm(addPanel);
//		phoInputCode.text='';
		return;
	}
	//清空表头隐藏输入项
//	FormUtils.clearForm(addPanel);
//	phoInputCode.text='';
	btToolBar.btDelRow.enabled=false;
}

/**
 * 查询按钮响应方法
 * */
protected function btToolBar_queryClickHandler(event:Event):void
{
//	var queryWin:ReceiveOtherQueryCon=ReceiveOtherQueryCon(PopUpManager.createPopUp(this, ReceiveOtherQueryCon, true));
//	queryWin.iparentWin=this;
//	PopUpManager.centerPopUp(queryWin);
	var paramQuery:ParameterObject=new ParameterObject();
	_condition['sendNo']=sendNo.text == "" ? null : sendNo.text;
	_condition['sendStatus']='2';
	paramQuery.conditions=_condition;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
	{
		if (rev.data && rev.data.length > 0)
		{
			var masters:ArrayCollection=rev.data as ArrayCollection;
			//主记录赋值
			gdReceiveOther.dataProvider=masters;
			gdReceiveOther.selectedIndex = 0;
			findRdsById1(rev.data[0].autoId);
		}
	});
	ro.findSendMaterialEntityListByCondition(paramQuery);
	
}

/**
 * 查询明细调用此函数
 * */
public function findRdsById1(fstrAutoId:String):void
{
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
	{
//		gdProviderDetail.editable=false;
		
		if (rev.data && rev.data.length > 0 && rev.data[0] && rev.data[0].length > 0)
		{
//			ObjectUtils.mergeObject(rev.data[0], _materialRdsMaster)
			var details:ArrayCollection=rev.data[0] as ArrayCollection;
			//主记录赋值
//s			fillMaster(_materialRdsMaster);
//			//明细赋值
//			var laryRawData:ArrayCollection=MainToolBar.aryColTransfer(details, MaterialRdsDetail);
			//			for each(var item:Object in laryRawData){
			//				item.checkAmount = item.amount; //实发数量默认 = 申请数量
			//			}
//			for each(var item:Object in laryRawData){
//				for each(var itemc:Object in rev.data[1]){
//					if(item.materialId == itemc.materialId){
//						item.detailRemark = itemc.detailRemark;
//					}
//				}
//			}
//			gdProviderDetail.dataProvider=laryRawData;
//			if (_materialRdsMaster.currentStatus == '1')
//			{
//				gdRdsDetail.dataProvider=rev.data[1];
//			}
//			stateButton(_materialRdsMaster.currentStatus);
//			storageCode.enabled=false;
//			toolBar.btAdd.enabled=true;
//			if(_vis){
//				toolBar.btModify.enabled = false;
//			}
			gdReceiveOtherList.dataProvider = details;
		}
		
	});
	ro.findSendDetailByAutoId(fstrAutoId);
}

/**
 * 退出按钮响应方法
 * */
protected function btToolBar_exitClickHandler(event:Event):void
{
	if (this.parentDocument is WinModual)
	{
		PopUpManager.removePopUp(this.parentDocument as IFlexDisplayObject);
		return;
	}
	DefaultPage.gotoDefaultPage();

}

/**
 * 部门档案字典
 * */
protected function deptCode_queryIconClickHandler():void
{
	if (!imaterialRdsMasterDept)
	{
		return;
	}
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict(function(rev:Object):void
		{
	//		deptCode.txtContent.text=rev.deptName;
			imaterialRdsMasterDept.deptCode=rev.deptCode;
		}, x, y);
}

/**
 * 人员档案字典
 * */
protected function personId_queryIconClickHandler():void
{
	if (!imaterialRdsMasterDept)
	{
		return;
	}
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict(function(rev:Object):void
		{
//			personId.txtContent.text=rev.personIdName;
			imaterialRdsMasterDept.personId=rev.personId;
		}, x, y);
}

/**
 * 生产厂家字典
 * */
protected function factoryCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict(function(rev:Object):void
		{

//			factoryCode.txtContent.text=rev.providerName;
			if (gdReceiveOtherList.selectedItem)
			{
				gdReceiveOtherList.selectedItem.factoryCode=rev.providerId;
			}
			gdReceiveOtherList.invalidateList();
		}, x, y);
}

/**
 * 处理回车键转到下一个控件
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.toNextControl(e, fcontrolNext);
}

/**
 * 切换单据类型时，文字颜色变化、文本框是否可见
 * */
protected function invoiceType_clickHandler(event:MouseEvent):void
{
//	var fId:String=event.target.id;
//	if (fId == 'invoiceType1')
//	{
//		tradePrice.enabled=true;
//		tradePrice.editable=true;
//		tradePriceText.styleName="myFormItemStyle";
//		factoryCode.enabled=true;
//		factoryCodeText.styleName="myFormItemStyle";
//		batchText.styleName="";
//		batch.visible=false;
//		batch.includeInLayout=false;
//		batch2.visible=true;
//		batch2.includeInLayout=true;
//		madeDate.enabled=true;
//		madeDateText.styleName="";
//		availDate.enabled=true;
//		availDateText.styleName="";
//	}
//	else
//	{
//		tradePrice.enabled=false;
//		tradePrice.editable=false;
//		tradePriceText.styleName="";
//		factoryCode.enabled=false;
//		factoryCodeText.styleName="";
//		madeDate.enabled=false;
//		madeDateText.styleName="";
//		availDate.enabled=false;
//		availDateText.styleName="";
//		batchText.styleName="myFormItemStyle";
//		batch2.visible=false;
//		batch2.includeInLayout=false;
//		batch.visible=true;
//		batch.includeInLayout=true;
//	}
}

/**
 * 切换单据类型
 * */
protected function invoiceType_changeHandler(event:Event):void
{
//	if (gdReceiveOtherList.dataProvider.length == 0)
//	{
//		return;
//	}
//	Alert.show('切换单据类型将清空页面数据', '提示信息', Alert.YES | Alert.NO, null, function(e:CloseEvent):void
//		{
//			if (e.detail == Alert.YES)
//			{
//				FormUtils.clearForm(addPanel);
//				gdReceiveOtherList.dataProvider=[];
//				invoiceType.selection=event.target.selection == invoiceType1 ? invoiceType1 : invoiceType2;
//				return;
//			}
//			invoiceType.selection=event.target.selection == invoiceType1 ? invoiceType2 : invoiceType1;
//		});
}

/**
 * 批号字典
 * */
protected function batch_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	if (!gdReceiveOtherList.selectedItem)
	{
		Alert.show('列表中没有物资档案信息，请录入物资明细', '提示信息', Alert.OK, null, function(e:CloseEvent):void
			{
				if (e.detail == Alert.OK)
				{
	//				phoInputCode.setFocus();
				}
			});
		return;
	}
	MaterialDictShower.showBatchNoChooser(gdReceiveOtherList.selectedItem.materialId, AppInfo.currentUserInfo.deptCode, null, function(rev:Object):void
		{

//			batch.txtContent.text=rev.batch;
//			//将批号字典调出数据写入文本框和列表
//			materialName.text=rev.materialName;
//			tradePrice.text=rev.tradePrice;
//			factoryCode.txtContent.text=rev.factoryName;
//			madeDate.text=DateUtil.dateToString(rev.madeDate, 'YYYY-MM-DD');
//			availDate.text=DateUtil.dateToString(rev.availDate, 'YYYY-MM-DD');
			if (gdReceiveOtherList.selectedItem)
			{
				gdReceiveOtherList.selectedItem.batch=rev.batch;
				gdReceiveOtherList.selectedItem.madeDate=rev.madeDate;
				gdReceiveOtherList.selectedItem.availDate=rev.availDate;
			}
			gdReceiveOtherList.invalidateList();
		}, x, y);
}

/**
 * 数量失去焦点时，判断是否允许零出库
 * */
protected function amount_focusOutHandler(event:FocusEvent):void
{
//	if (Number(amount.text) < 0 && !_zeroStock && invoiceType2.selected && Number(0 - Number(amount.text)) > Number(currentStockAmount.text) && Number(currentStockAmount.text) <= 0 && gdReceiveOtherList.selectedIndex > -1)
//	{
//		Alert.show("该物资不允许零出库！", "提示信息", Alert.OK, null, function(e:CloseEvent):void
//			{
//				if (e.detail == Alert.OK)
//				{
//					FormUtils.clearForm(addPanel);
//					var _gd:ArrayCollection=gdReceiveOtherList.dataProvider as ArrayCollection;
//					var _index:int=_gd.getItemIndex(gdReceiveOtherList.selectedItem);
//					_gd.removeItemAt(_index);
//					gdReceiveOtherList.dataProvider=_gd;
//					gdReceiveOtherList.invalidateList();
//					if (gdReceiveOtherList.dataProvider.length > 0)
//					{
//						gdReceiveOtherList.selectedIndex=gdReceiveOtherList.dataProvider.length - 1;
//						phoInputCode.setFocus();
//						return;
//					}
//					gdReceiveOtherList.dataProvider=[];
//					phoInputCode.setFocus();
//				}
//			});
//		return;
//	}
//	if (Number(amount.text) < 0 && !_zeroStock && invoiceType2.selected && Number(0 - Number(amount.text)) > Number(currentStockAmount.text) && Number(currentStockAmount.text) > 0 && gdReceiveOtherList.selectedIndex > -1)
//	{
//		Alert.show("该物资不允许零出库！", "提示信息", Alert.OK, null, function(e:CloseEvent):void
//			{
//				if (e.detail == Alert.OK)
//				{
//					amount.text="";
//					gdReceiveOtherList.selectedItem.amount=amount.text;
//					gdReceiveOtherList.invalidateList();
//					amount.setFocus();
//				}
//			});
//		return;
//	}
}

/**
 * 根据选中的单据类型，判断回车键转到下一个控件
 * */
protected function amount_keyUpHandler(event:KeyboardEvent):void
{
//	if (amount.text == "")
//	{
//		return;
//	}
//	if (invoiceType1.selected)
//	{
//		toNextControl(event, tradePrice);
//	}
//	else
//	{
//		toNextControl(event, batch);
//	}
}

/**
 * 列表双击事件，对该条记录进行修改
 * */
protected function gdReceiveOtherList_doubleClickHandler(event:Event):void
{
	btToolBar_modifyClickHandler(event);
}

/**
 * 将列表中选中的内容回写入表格中
 * */
protected function gdReceiveOtherList_clickHandler():void
{
	if (!gdReceiveOtherList.selectedItem)
	{
		return;
	}
	findRdsById1(gdReceiveOtherList.selectedItem.autoId);
//	//选中蓝单时动态改变批号和有效期限颜色
//	if (gdReceiveOtherList.selectedItem.batchSign && gdReceiveOtherList.selectedItem.batchSign == '1' && invoiceType1.selected)
//	{
//		batchText.styleName="myFormItemStyle";
//	}
//	else
//	{
//		batchText.styleName="";
//	}
//	if (gdReceiveOtherList.selectedItem.qualitySign && gdReceiveOtherList.selectedItem.qualitySign == '1' && invoiceType1.selected)
//	{
//		madeDateText.styleName="myFormItemStyle";
//		availDateText.styleName="myFormItemStyle";
//	}
//	else
//	{
//		madeDateText.styleName="";
//		availDateText.styleName="";
//	}
//	//选中列表的数据回填隐藏表头
//	FormUtils.fillFormByItem(addPanel, gdReceiveOtherList.selectedItem);
//	if (invoiceType1.selected)
//	{
//		batch2.text=gdReceiveOtherList.selectedItem.batch;
//	}
//	else
//	{
//		batch.txtContent.text=gdReceiveOtherList.selectedItem.batch;
//	}
//	factoryCode.txtContent.text=gdReceiveOtherList.selectedItem.factoryName;
//	//查询时列表中现存量不需要重新获取
//	if (!iqueryStockSign)
//	{
//
//		currentStockAmount.text=gdReceiveOtherList.selectedItem.currentStockAmount;
//		return;
//	}
//	//增加、修改时列表中现存量从服务端重新获取
//	var lstrStorageCode:String=AppInfo.currentUserInfo.deptCode;
//	var ro:RemoteObject=RemoteUtil.getRemoteObject("commMaterialServiceImpl", function(rev:Object):void
//		{
//			currentStockAmount.text=rev.data[0].currentStockAmount;
//			gdReceiveOtherList.selectedItem.currentStockAmount=Number(currentStockAmount.text);
//		});
//	ro.findCurrentStockByIdStorage(gdReceiveOtherList.selectedItem.materialId, lstrStorageCode);
}

/**
 * 文本档与列表同步更新
 * */
protected function changeHandler(event:Event):void
{
//	if (gdReceiveOtherList.selectedIndex > -1 && gdReceiveOtherList.selectedItem)
//	{
//		if (event.currentTarget == amount && invoiceType2.selected && Number(amount.text) != 0)
//		{
//			var lintCurrentPos:int=amount.selectionActivePosition;
//			var lintOldLength:int=amount.text.length;
//			var lnumNewValue:Number=-1 * Math.abs(Number(amount.text));
//			if (isNaN(lnumNewValue))
//			{
//				amount.text="0";
//			}
//			else
//			{
//				amount.text=lnumNewValue.toString();
//			}
//			if (lintOldLength != amount.text.length)
//			{
//				lintCurrentPos++;
//			}
//			amount.selectionBeginIndex=lintCurrentPos;
//			amount.selectionEndIndex=lintCurrentPos;
//		}
//		FormUtils.changHandler(event, gdReceiveOtherList.selectedItem);
//		// 金额 = 数量 * 进价
//		gdReceiveOtherList.selectedItem.tradeMoney=gdReceiveOtherList.selectedItem.amount * gdReceiveOtherList.selectedItem.tradePrice;
//		if (invoiceType1.selected)
//		{
//			gdReceiveOtherList.selectedItem.batch=batch2.text;
//		}
//		else
//		{
//			gdReceiveOtherList.selectedItem.batch=batch.txtContent.text;
//		}
//		gdReceiveOtherList.invalidateList();
//		return;
//	}
//	Alert.show('列表中没有物资档案信息，请录入物资明细！', '提示信息', Alert.OK, null, function(e:CloseEvent):void
//		{
//			if (e.detail == Alert.OK)
//			{
//				amount.text="";
//				tradePrice.text="";
//				batch2.text="";
//				batch.txtContent.text="";
//				detailRemark.text="";
//				phoInputCode.setFocus();
//			}
//		});
}
//供应商ID转换成名称
private function labelFun(item:Object, salerCode:DataGridColumn):*
{
	var s:Object=BaseDict.providerDict;
	if (salerCode.headerText == "生产厂家")
	{
		var factoryCodeItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict, 'provider', item.factoryCode);
		if (!factoryCodeItem)
		{
			return '';
		}
		else
		{
			return factoryCodeItem.providerName;
		}
	}
}

/**
 * 数量进行改变事件
 */
public function amount_ChangeHandler(event:Event):void
{
	var lRdsDetail:MaterialProvideDetail=gdReceiveOtherList.selectedItem as MaterialProvideDetail;
	if (!lRdsDetail)
	{
		return;
	}
//	var isCharDuplication:Boolean = false;
//	var trimedText:String = mx.utils.StringUtil.trim(packageAmount.text); 
//	for(var i:int = 1; i < trimedText.length;i ++){
//		if(trimedText.charAt(i) == '-'){
//			isCharDuplication = true;
//			break;
//		}
//	}
//	if(isCharDuplication){
//		packageAmount.text = '-';
//		packageAmount.selectRange(1,packageAmount.text.length);;
//		return;	
//	}
//	if(isNaN(Number(trimedText)) || trimedText == '' ){
//		lRdsDetail.amount = 0;
//	}else{
	lRdsDetail.checkAmount=isNaN(lRdsDetail.checkAmount) ? 1 : lRdsDetail.checkAmount;
//		lRdsDetail.amount=parseFloat(packageAmount.text) * lRdsDetail.amountPerPackage;
//	}
//	lRdsDetail.packageAmount = parseFloat(packageAmount.text);
//	lRdsDetail.acctAmount = lRdsDetail.amount;
	//
	lRdsDetail.tradeMoney=Number((lRdsDetail.checkAmount * lRdsDetail.tradePrice).toFixed(3));
	
//	if(_isShow){
//		lRdsDetail.factTradeMoney=Number((lRdsDetail.amount * lRdsDetail.factTradePrice).toFixed(3));
//		
//		lRdsDetail.wholeSaleMoney=Number((lRdsDetail.amount * lRdsDetail.wholeSalePrice).toFixed(3));
//		lRdsDetail.inviteMoney= Number((lRdsDetail.amount * lRdsDetail.invitePrice).toFixed(3));
//		
//		lRdsDetail.retailMoney= Number((lRdsDetail.amount * lRdsDetail.retailPrice).toFixed(3));
//	}else{
//		lRdsDetail.factTradeMoney=Number((lRdsDetail.amount * lRdsDetail.factTradePrice).toFixed(2));
//		
//		lRdsDetail.wholeSaleMoney=Number((lRdsDetail.amount * lRdsDetail.wholeSalePrice).toFixed(2));
//		lRdsDetail.inviteMoney= Number((lRdsDetail.amount * lRdsDetail.invitePrice).toFixed(2));
//		
//		lRdsDetail.retailMoney= Number((lRdsDetail.amount * lRdsDetail.retailPrice).toFixed(2));
//	}
	
}