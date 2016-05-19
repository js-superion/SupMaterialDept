/**
 *		 其他出库处理
 *		 作者: 朱玉峰 2011.06.18
 *		 修改：
 **/
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialDept.deliver.deliverOther.view.WinDeliverOtherFilter;
import cn.superion.materialDept.deliver.deliverOther.view.WinDeliverOtherQuery;
import cn.superion.materialDept.util.DefaultPage;
import cn.superion.materialDept.util.MaterialDictShower;
import cn.superion.materialDept.util.RdTypeDict;
import cn.superion.materialDept.util.ToolBar;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialPatsDetail;
import cn.superion.vo.material.MaterialRdsDetailDept;
import cn.superion.vo.material.MaterialRdsMasterDept;

import flash.events.ContextMenuEvent;
import flash.ui.ContextMenu;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.core.IFlexDisplayObject;
import mx.core.UIComponent;
import mx.events.CloseEvent;
import mx.events.IndexChangedEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import spark.events.TextOperationEvent;

private static const MENU_NO:String="0304";
public var DESTANATION:String="deptOtherDeliverImpl";
private const PARA_CODE:String="0601"; //是否允许零出库
private var _zeroStock:Boolean=false; //零库存标志

public var menuItemsName:Array=null;
public var functions:Array=null;
public var menuItemsEnableValues:Object=['0', '0']; //1表可用，0不可用
//主记录
public var _materialRdsMasterDept:MaterialRdsMasterDept=new MaterialRdsMasterDept();

//查询主记录ID列表
public var arrayAutoId:Array=new Array();
//当前页，翻页用
public var currentPage:int=0;

/**
 * 初始化当前窗口
 * */
public function doInit():void
{
	parentDocument.title="其他出库处理";
	//重新注册客户端对应的服务端类
	registerClassAlias("cn.superion.materialDept.entity.MaterialRdsMasterDept", MaterialRdsMasterDept);
	//放大镜不可手动输入
	preventDefaultForm();
	//判断是否可以零出库
	checkCanZeroStock();
	setReadOnly(false);
	initPanel();
	initToolBar();
}

/**
 * 面板初始化
 */
private function initPanel():void
{
	//填充出库
	fillStorageCodeTxt();
	//出库类别
	fillCombox();
	//初始化主记录
	_materialRdsMasterDept.invoiceType="1";
	_materialRdsMasterDept.operationType="209";
	operationType.text="其他出库";
	
	menuItemsName=['其他出库单'];
	functions=[callbackApply];
	dgDeliverBillList.contextMenu=initContextMenu(dgDeliverBillList, menuItemsName, functions);
	dgDeliverBillList.contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, menuItemEnabled);
}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.imageList1, toolBar.btAdd, toolBar.btModify, toolBar.btDelete, toolBar.btCancel, toolBar.btSave, toolBar.btVerify, toolBar.imageList2, toolBar.btAddRow, toolBar.btDelRow, toolBar.imageList3, toolBar.btQuery, toolBar.imageList5, toolBar.btFirstPage, toolBar.btPrePage, toolBar.btNextPage, toolBar.btLastPage, toolBar.imageList6, toolBar.btExit];
	var laryEnables:Array=[toolBar.btAdd, toolBar.btQuery, toolBar.btExit];
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
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
	dgDeliverBillList.contextMenu=contextMenu;
	return contextMenu;
}
/**
 * 响应右键弹出事件
 * 根据menuItemsEnableValues中的值，分别对应右键菜单项是否可用
 * */
private function menuItemEnabled(e:ContextMenuEvent):void
{
	var aryMenuItems:Array=e.target.customItems;
	for (var i:int=0; i < aryMenuItems.length; i++)
	{
		aryMenuItems[i].enabled=menuItemsEnableValues[i] == "1" ? true : false;
	}
}
/**
 * 表头设置只读或读写状态
 */
private function setReadOnly(boolean:Boolean):void
{
	var i:String=boolean==true?"1":"0";
	masterGroup.enabled=boolean;
	hiddenVGroup.visible=boolean;
	hiddenVGroup.includeInLayout=boolean;
	menuItemsEnableValues=[i,i];
}

/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{
	deptCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
		{
			e.preventDefault();
		})
	personId.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
		{
			e.preventDefault();
		})
	phoInputCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
		{
			e.preventDefault();
		})
	batch.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
		{
			e.preventDefault();
		})
	factoryName.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
		{
			e.preventDefault();
		})
}

/**
 * 填充仓库名称
 * */
private function fillStorageCodeTxt():void
{
	var lobjItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', AppInfo.currentUserInfo.deptCode);
	if (lobjItem)
	{
		AppInfo.currentUserInfo.deptName=lobjItem.deptName
	}
	storageCode.text=AppInfo.currentUserInfo.deptName;
	_materialRdsMasterDept.storageCode=AppInfo.currentUserInfo.deptCode;
}

/**
 * 填充下拉框
 * */
private function fillCombox():void
{
	// 出库类型
	rdType.dataProvider=RdTypeDict.deliverTypeDict;
	rdType.selectedIndex=3;
	_materialRdsMasterDept.rdType=rdType.selectedItem.deliverTypeCode;
	_materialRdsMasterDept.rdFlag="2";

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
	FormUtils.clearForm(hiddenVGroup);
}

/**
 * 清空主记录
 */
public function clearMaster():void
{
	FormUtils.clearForm(masterOne);
	invoiceType1.selected=true;
	dgDeliverBillList.dataProvider=null;
	_materialRdsMasterDept=new MaterialRdsMasterDept();
	rdType.selectedIndex=3;
	billNo.text="";
	billDate.selectedDate=new Date();
	FormUtils.clearForm(_bottom);
}

/**
 * 回车事件
 **/
private function toNextControl(event:KeyboardEvent, fctrlNext:Object):void
{
	FormUtils.toNextControl(event, fctrlNext);
}

/**
 * 有效日期改变事件响应方法
 * */
protected function availDateChangHandler(event:Event):void
{
	if (dgDeliverBillList.selectedIndex > -1 && dgDeliverBillList.selectedItem)
	{
		dgDeliverBillList.selectedItem.availDate=availDate.selectedDate;
		dgDeliverBillList.invalidateList();
		return;
	}
}
/**
 * SuperDataGrid事件
 */ 
protected function dgDeliverBillList_itemClickHandler(event:ListEvent):void
{
	// TODO Auto-generated method stub.
	if(!dgDeliverBillList.selectedItem)
	{
		return;
	}
	FormUtils.fillFormByItem(hiddenVGroup,dgDeliverBillList.selectedItem);
	phoInputCode.text=dgDeliverBillList.selectedItem.materialCode;
	var ro:RemoteObject=RemoteUtil.getRemoteObject("deptCommMaterialServiceImpl", function(rev:Object):void
	{
		currentStockAmount.text=rev.data[0].totalCurrentStockAmount;
	});
	ro.findCurrentStockById(dgDeliverBillList.selectedItem.materialId);
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
 * 数量事件
 */
protected function amount_changeHandler(event:Event):void
{
	// TODO Auto-generated method stub
	if (!dgDeliverBillList.selectedItem)
	{
		return;
	}
	var amou:Number=Number(amount.text);
	var amout:int;
	var ro:RemoteObject=RemoteUtil.getRemoteObject("deptCommMaterialServiceImpl", function(rev:Object):void
	{
		amout=rev.data[0].totalCurrentStockAmount;
		if (((Number)(amount.text)) > amout)
		{
			if(_zeroStock==false)
			{
				Alert.show("输入数量已超出、现存量！", "提示");
				return;
			}
		}
		if (amount.text == "" || amount.text == null)
		{
			return;
		}
		var strn:String=amount.text == null ? "" : amount.text;
		var strm1:String="";
		if (invoiceType2.selected == true)
		{
			for (var i:int=0; i < strn.length; i++)
			{
				if (i == 0)
				{
					strm1=strm1.concat(strn.charAt(i));
				}
				else
				{
					if (strn.charAt(i) != "-")
					{
						strm1=strm1.concat(strn.charAt(i));
					}
				}
			}
			if (strm1.length == 0)
			{
				if (strm1.charAt(0) == '-')
				{
					return;
				}
			}
			if (Number(strm1) > 0)
			{
				dgDeliverBillList.selectedItem.amount=Number(strm1 == "-" ? 0 : strm1) * -1;
				dgDeliverBillList.selectedItem.tradeMoney=dgDeliverBillList.selectedItem.tradePrice * dgDeliverBillList.selectedItem.amount;
				dgDeliverBillList.selectedItem.retailMoney=dgDeliverBillList.selectedItem.retailPrice * dgDeliverBillList.selectedItem.amount;
				return;
			}
			dgDeliverBillList.selectedItem.amount=Number(strm1 == "-" ? 0 : strm1);
			dgDeliverBillList.selectedItem.tradeMoney=dgDeliverBillList.selectedItem.tradePrice * dgDeliverBillList.selectedItem.amount;
			dgDeliverBillList.selectedItem.retailMoney=dgDeliverBillList.selectedItem.retailPrice * dgDeliverBillList.selectedItem.amount;
		}
		if (amount.text.charAt(0) == "-")
		{
			return;
		}
		if (Number(amount.text) < 0)
		{
			return;
		}
		for (var j:int=0; j < strn.length; j++)
		{
			if (j == 0)
			{
				strm1=strm1.concat(strn.charAt(j));
			}
			else
			{
				if (strn.charAt(j) != "-")
				{
					strm1=strm1.concat(strn.charAt(j));
				}
			}
		}
		dgDeliverBillList.selectedItem.amount=Number(strm1);
		dgDeliverBillList.selectedItem.tradeMoney=dgDeliverBillList.selectedItem.tradePrice * dgDeliverBillList.selectedItem.amount;
		dgDeliverBillList.selectedItem.retailMoney=dgDeliverBillList.selectedItem.retailPrice * dgDeliverBillList.selectedItem.amount;
	});
	ro.findCurrentStockById(dgDeliverBillList.selectedItem.materialId);
}

/**
 * 进价事件
 */
protected function tradePrice_changeHandler(event:TextOperationEvent):void
{
	// TODO Auto-generated method stub
	if (!dgDeliverBillList.selectedItem)
	{
		return;
	}
	var tp:Number=Number(tradePrice.text);
	dgDeliverBillList.selectedItem.tradePrice=tp;
	dgDeliverBillList.selectedItem.tradeMoney=tp * dgDeliverBillList.selectedItem.amount;
}

/**
 * 备注事件
 */
protected function detailRemark_changeHandler(event:TextOperationEvent):void
{
	// TODO Auto-generated method stub
	if (!dgDeliverBillList.selectedItem)
	{
		return;
	}
	dgDeliverBillList.selectedItem.detailRemark=detailRemark.text;
}
/**
 * 获取是否可以零库存
 * */
private function checkCanZeroStock():void{
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
 * 部门字典响应方法
 * */
protected function deptCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict(function(rev:Object):void
		{
			deptCode.txtContent.text=rev.deptName;
			_materialRdsMasterDept.deptCode=rev.deptCode;
		}, x, y);
}

/**
 * 业务员字典响应方法
 * */
protected function personId_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict(function(rev:Object):void
		{
			personId.txtContent.text=rev.personIdName;
			_materialRdsMasterDept.personId=rev.personId;
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
	lstorageCode=_materialRdsMasterDept.storageCode;
	MaterialDictShower.showMaterialDictNew(null, '', '', true, function(faryItems:Array):void
		{
			fillIntoGrid(faryItems);
		}, x, y);
}

/**
 * 生产厂家字典响应方法
 * */
protected function factoryCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict(function(rev:Object):void
		{

		factoryName.txtContent.text=rev.providerName;
			if (dgDeliverBillList.selectedItem)
			{
				dgDeliverBillList.selectedItem.factoryName=rev.providerName;
				dgDeliverBillList.selectedItem.factoryCode=rev.providerId;
			}
			dgDeliverBillList.invalidateList();
		}, x, y);
}

/**
 * 自动完成表格回调
 * */
private function fillIntoGrid(fItem:Array):void
{
	var laryDetails:ArrayCollection=dgDeliverBillList.dataProvider as ArrayCollection;
	for each(var obj:Object in fItem){
		//放大镜取出的值、赋值
		var deliverOtherDetail:MaterialRdsDetailDept=new MaterialRdsDetailDept();
		deliverOtherDetail.materialClass=obj.materialClass;
		deliverOtherDetail.materialId=obj.materialId;
		deliverOtherDetail.materialCode=obj.materialCode;
		deliverOtherDetail.materialName=obj.materialName;
		deliverOtherDetail.materialSpec=obj.materialSpec;
		deliverOtherDetail.materialUnits=obj.materialUnits;
		deliverOtherDetail.amount=0;
		deliverOtherDetail.tradePrice=obj.tradePrice == null ? 0 : obj.tradePrice;
		deliverOtherDetail.tradeMoney=obj.tradePrice == null ? 0 : obj.tradePrice;
		deliverOtherDetail.retailPrice=obj.retailPrice == null ? 0 : obj.retailPrice;
		deliverOtherDetail.retailMoney=obj.retailPrice == null ? 0 : obj.retailPrice;
		deliverOtherDetail.outAmount=0;
		deliverOtherDetail.outSign="0";
		deliverOtherDetail.factoryCode=obj.factoryCode;
		deliverOtherDetail.availDate=new Date();
		deliverOtherDetail.detailRemark=obj.detailRemark;
		deliverOtherDetail.currentStockAmount=obj.amount;
		deliverOtherDetail.sourceAutoId="";
		deliverOtherDetail.sourceInputAutoId="";
		laryDetails.addItem(deliverOtherDetail);
		phoInputCode.text=obj.materialCode;
	}
	FormUtils.fillFormByItem(hiddenVGroup, deliverOtherDetail);
	var timer:Timer=new Timer(100, 1)
	timer.addEventListener(TimerEvent.TIMER, function(e:Event):void
	{
		amount.setFocus();
	})
	timer.start();
	dgDeliverBillList.dataProvider=laryDetails;
	dgDeliverBillList.selectedIndex=laryDetails.length - 1;
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
{
	var _dataList:ArrayCollection=dgDeliverBillList.dataProvider as ArrayCollection;
	var dict:Dictionary=new Dictionary();
	for (var i:int=0; i < _dataList.length; i++)
	{
		var item:Object=_dataList.getItemAt(i);
		item.factoryName=item.factoryName==null?"":(item.factoryName);
		item.availDate=item.availDate==null?new Date():item.availDate;
		item.nameSpec=item.materialName + "  " + (item.materialSpec == null ? "" : item.materialSpec);
	}
	dict["单位"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="其他出库处理";
	dict["制表人"]=AppInfo.currentUserInfo.userName;
	dict["仓库"]=storageCode.text;
	dict["出库类别"]=rdType.selectedItem.receviceTypeName;
	dict["出库单号"]=billNo.text;
	dict["出库日期"]=DateField.dateToString(DateField.stringToDate(billDate.text, "YYYY-MM-DD"), "YYYY-MM-DD");
	dict["业务类型"]=operationType.text;
	dict["业务号"]=operationNo.text;
	dict["部门"]=deptCode.txtContent.text;
	dict["业务员"]=personId.txtContent.text;
	dict["备注"]=remark.text;
	dict["制单人"]=maker.text;
	dict["审核人"]=verifier.text;
	dict["审核日期"]=verifyDate.text;
	if (printSign == '1')
	{
		ReportPrinter.LoadAndPrint("report/materialDept/deliver/deliverOther/deliverOther.xml", _dataList, dict);
	}
	if (printSign == '0')
	{
		ReportViewer.Instance.Show("report/materialDept/deliver/deliverOther/deliverOther.xml", _dataList, dict);
	}
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
	initPanel();
	operationNo.setFocus();

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
	dgDeliverBillList.selectedIndex=0;
	FormUtils.fillFormByItem(hiddenVGroup, dgDeliverBillList.dataProvider[0]);
	amount.text="";
	amount.setFocus();
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
				ro.deleteRds(_materialRdsMasterDept.autoId);
			}
		});
}


/**
 * 保存
 */
protected function saveClickHandler(event:Event):void
{
	var arry:ArrayCollection=dgDeliverBillList.dataProvider as ArrayCollection;
	//保存权限
	if (!checkUserRole('04'))
	{
		return;
	}
	if (arry.length <= 0)
	{
		Alert.show("明细记录不能为空!", "提示");
		return;
	}
	masterEvalate();
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
		{
			setReadOnly(false);
			findRdsById(rev.data[0].autoId);
			toolBar.saveToPreState();
			Alert.show("保存成功", "提示");
		});
	ro.saveRdsOther(_materialRdsMasterDept, arry);
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
 * 审核按钮
 */
protected function toolBar_verifyClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
		{
			Alert.show("审核成功", "提示");
			findRdsById(_materialRdsMasterDept.autoId);
		})
	ro.verifyRds(_materialRdsMasterDept.autoId);
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
	var laryDetails:ArrayCollection=dgDeliverBillList.dataProvider as ArrayCollection;
	var i:int=laryDetails.getItemIndex(dgDeliverBillList.selectedItem);
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
			dgDeliverBillList.dataProvider=laryDetails;
			dgDeliverBillList.selectedIndex=i == 0 ? 0 : (i - 1);
			FormUtils.fillFormByItem(hiddenVGroup, dgDeliverBillList.selectedItem);
		})
}

/**
 * 查询其他出库界面
 */
private function callbackApply(e:Event):void
{
	var win:WinDeliverOtherFilter=PopUpManager.createPopUp(this, WinDeliverOtherFilter, true) as WinDeliverOtherFilter;
	win.data={parentWin: this};
	PopUpManager.centerPopUp(win);
}

/**
 * 查询
 */
protected function queryClickHandler(event:Event):void
{
	var win:WinDeliverOtherQuery=WinDeliverOtherQuery(PopUpManager.createPopUp(this, WinDeliverOtherQuery, true));
	win.iparentWin=this;
	PopUpManager.centerPopUp(win);
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
			_materialRdsMasterDept=rev.data[0];
			masterEvaluate(rev);
			dgDeliverBillList.dataProvider=rev.data[1];
			stateButton(rev.data[0].currentStatus);
			setReadOnly(false);
		});
	ro.findOtherDetailById(fstrAutoId);
}


/**
 * 查询批号
 */
protected function batch_queryIconClickHandler():void
{
	if (dgDeliverBillList.selectedItem)
	{
		var x:int=0;
		var y:int=this.parentApplication.screen.height - 345;
		MaterialDictShower.showBatchNoChooser(dgDeliverBillList.selectedItem.materialId, _materialRdsMasterDept.storageCode, null, function(rev:Object):void
			{
				if (dgDeliverBillList.selectedItem)
				{
					batch.text=rev.batch;
					dgDeliverBillList.selectedItem.batch=rev.batch;
					dgDeliverBillList.selectedItem.availDate=rev.availDate;
					dgDeliverBillList.selectedItem.factoryCode=rev.factoryCode;
					dgDeliverBillList.selectedItem.factoryName=rev.factoryName;
				}

			}, x, y);
	}

}

/**
 * 给主记录文本赋值
 */
protected function masterEvaluate(rev:Object):void
{
	FormUtils.fillFormByItem(masterGroup, rev.data[0]);
	var consultingDoctor1:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', rev.data[0].personId);
	var deptcode:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', rev.data[0].deptCode);
	operationNo.text=consultingDoctor1 == null ? null : consultingDoctor1.personIdName;
	deptCode.text=deptcode == null ? null : deptcode.deptName;
	var lobjItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', rev.data[0].storageCode);
	storageCode.text=lobjItem.deptName;
	FormUtils.selectComboItem(rdType, "deliverTypeCode", rev.data[0].rdType);
	FormUtils.fillFormByItem(_bottom, rev.data[0]);
	maker.text=codeToName(rev.data[0].maker);
	verifier.text=codeToName(rev.data[0].verifier);
	if (rev.data[0].invoiceType == "1")
	{
		invoiceType1.selected=true;
	}
	else
	{
		invoiceType2.selected=true;
	}
}

/**
 * 取页面主记录
 */
public function masterEvalate():void
{
	_materialRdsMasterDept.operationNo=operationNo.text;
	_materialRdsMasterDept.rdType=rdType.selectedItem.deliverType;
	_materialRdsMasterDept.billDate=billDate.selectedDate;
	_materialRdsMasterDept.remark=remark.text;
	_materialRdsMasterDept.invoiceType=invoiceType1.selected == true ? "1" : "2"
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
 * 红字蓝字类型改变事件响应方法
 * */
protected function invoiceType_changeHandler(event:Event):void
{
	if (dgDeliverBillList.dataProvider.length == 0)
	{
		return;
	}
	Alert.show('切换单据类型将清空页面数据', '提示信息', Alert.YES | Alert.NO, null, function(e:CloseEvent):void
		{
			if (e.detail == Alert.YES)
			{
				FormUtils.clearForm(hiddenVGroup);
				dgDeliverBillList.dataProvider=[];
				invoiceType.selection=event.target.selection == invoiceType1 ? invoiceType1 : invoiceType2;
				return;
			}
			invoiceType.selection=event.target.selection == invoiceType1 ? invoiceType2 : invoiceType1;
		});
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