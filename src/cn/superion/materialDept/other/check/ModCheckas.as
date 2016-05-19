/**
 *		 库存盘点模块
 *		 author:邢树斌   2011.01.29
 * 		 modify:吴小娟   2011.07.06
 *		 checked by
 **/
import cn.superion.base.components.controls.TextInputIcon;
import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.DateUtil;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.ObjectUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.base.util.StringUtils;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialDept.other.check.view.WinCheckQuery;
import cn.superion.materialDept.other.check.view.WinCheckStorage;
import cn.superion.materialDept.util.DefaultPage;
import cn.superion.materialDept.util.MaterialDictShower;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialCheckDetailDept;
import cn.superion.vo.material.MaterialCheckMasterDept;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.controls.Text;
import mx.core.IFlexDisplayObject;
import mx.events.CloseEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;

import org.alivepdf.layout.Format;

import spark.events.TextOperationEvent;

registerClassAlias("cn.superion.materialDept.entity.MaterialCheckDetailDept", cn.superion.vo.material.MaterialCheckDetailDept);
registerClassAlias("cn.superion.materialDept.entity.MaterialCheckMasterDept", cn.superion.vo.material.MaterialCheckMasterDept);

public static const MENU_NO:String="0302";
//服务类
public static const DESTANATION:String="deptCheckImpl";

private var _winY:int=0;

//当前主记录
private var _materialCheckMasterDept:MaterialCheckMasterDept=new MaterialCheckMasterDept();

//是否批号管理
private var _bathSign:Boolean;

//查询主记录ID列表
public var arrayAutoId:Array=new Array();
//当前页，翻页用
public var currentPage:int=0;

/**
 * 初始化当前窗口
 * */
public function doInit():void
{
	parentDocument.title="库存盘点处理";
	_winY=this.parentApplication.screen.height - 345;
	inRdType.width=storageCode.width;
	deptCode.width=billNo.width;
	personId.width=billDate.width;
	initPanel();
}

/**
 * 面板初始化
 */
private function initPanel():void
{
	initToolBar();
	//增加项隐藏
	bord.height=70;
	hiddenVGroup.includeInLayout=false;
	hiddenVGroup.visible=false;
	//授权仓库赋值
	var deptItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', AppInfo.currentUserInfo.deptCode);
	storageCode.text=deptItem == null ? "" : deptItem.deptName;
	//设置只读
	setReadOnly(false);
	//阻止表单输入
	preventDefaultForm();
}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.imageList1, toolBar.btAdd, toolBar.btModify, toolBar.btDelete, toolBar.btCancel, toolBar.btSave, toolBar.btVerify, toolBar.btStorage, toolBar.imageList2, toolBar.btAddRow, toolBar.btDelRow, toolBar.imageList3, toolBar.imageList5, toolBar.btFirstPage, toolBar.btPrePage, toolBar.btNextPage, toolBar.btLastPage, toolBar.btQuery, toolBar.imageList6, toolBar.btExit];
	var laryEnables:Array=[toolBar.btAdd, toolBar.btQuery, toolBar.btExit];
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 表头设置只读或读写状态
 */
private function setReadOnly(boolean:Boolean):void
{
	boolean=!boolean;
	storageCode.enabled=boolean;
	billNo.enabled=boolean;
	billDate.enabled=boolean;
	accountDate.enabled=boolean;
	outRdType.enabled=boolean;
	inRdType.enabled=boolean;
	deptCode.enabled=boolean;
	personId.enabled=boolean;
	remark.enabled=boolean;
}

/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{
	outRdType.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
		{
			e.preventDefault();
		})

	inRdType.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
		{
			e.preventDefault();
		})

	deptCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
		{
			e.preventDefault();
		})

	personId.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
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
	materialCode.txtContent.text="";
	materialName.text="";
	materialSpec.text="";
	materialUnits.text="";
	checkAmount.text="";
	batch.text="0";
	availDate.text="";

	gdCheckDetail.dataProvider=new ArrayCollection();
}

/**
 * 清空主记录
 */
public function clearMaster():void
{

	billNo.text="";
	accountDate.selectedDate=new Date();
	billDate.selectedDate=new Date();
	inRdType.txtContent.text="";
	deptCode.txtContent.text="";
	personId.txtContent.text="";
	remark.text="";

	maker.text='';
	makeDate.text='';
	verifier.text='';
	verifyDate.text='';

	_materialCheckMasterDept=new MaterialCheckMasterDept();
}


/**
 * 回车事件
 **/
private function toNextCtrl(event:KeyboardEvent, fctrlNext:Object):void
{
	if (event.keyCode != Keyboard.ENTER)
	{
		return;
	}
	if (event.currentTarget == availDate)
	{
		materialCode.txtContent.text='';
	}

	if (event.currentTarget == checkAmount && !_bathSign)
	{
		materialCode.txtContent.text='';
		materialCode.txtContent.setFocus();
		return;
	}
	FormUtils.toNextControl(event, fctrlNext);
}

/**
 * 有效日期
 */
protected function availDate_changeHandler(event:Event):void
{
	var lCheckDetail:MaterialCheckDetailDept=gdCheckDetail.selectedItem as MaterialCheckDetailDept;
	if (!lCheckDetail)
	{
		return;
	}

	lCheckDetail.availDate=availDate.selectedDate;
}

/**
 * 出库类别字典
 */
protected function outRdType_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	DictWinShower.showDeliverTypeDict(function(rev:Object):void
		{
			outRdType.txtContent.text=rev.rdName;

			_materialCheckMasterDept.outRdType=rev.rdCode;
		}, x, _winY);
}

/**
 * 入库类别字典
 */
protected function inRdType_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	DictWinShower.showReceiveTypeDict(function(rev:Object):void
		{
			inRdType.txtContent.text=rev.rdName;

			_materialCheckMasterDept.inRdType=rev.rdCode;
		}, x, _winY);
}

/**
 * 部门档案
 */
protected function deptCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	DictWinShower.showDeptDict(function(rev:Object):void
		{
			deptCode.txtContent.text=rev.deptName;
			_materialCheckMasterDept.deptCode=rev.deptCode;
		}, x, _winY);
}

/**
 * 人员档案
 */
protected function personId_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	DictWinShower.showPersonDict(function(rev:Object):void
		{
			personId.txtContent.text=rev.name;
			_materialCheckMasterDept.personId=rev.personId;
		}, x, _winY);
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
	lstorageCode=AppInfo.currentUserInfo.deptCode;

	MaterialDictShower.showMaterialDictNew(null, '', '', true, function(fItems:Array):void
		{
			fillIntoGrid(fItems);
		}, x, y);
}


/**
 * 自动完成表格回调
 * */
private function fillIntoGrid(fItems:Array):void
{
	var laryDetails:ArrayCollection=gdCheckDetail.dataProvider as ArrayCollection;

	for each(var fItem:Object in fItems){
		var lnewlDetail:MaterialCheckDetailDept=new MaterialCheckDetailDept();
		//	lnewlDetail.serialNo=0;
		//物资分类
		lnewlDetail.materialClass=fItem.materialClass;
		//条形码
		lnewlDetail.barCode=fItem.barCode;
		//物资ID
		lnewlDetail.materialId=fItem.materialId;
		//物资编码
		lnewlDetail.materialCode=fItem.materialCode;
		//物资名称
		lnewlDetail.materialName=fItem.materialName;
		//规格型号
		lnewlDetail.materialSpec=fItem.materialSpec;
		//单位
		lnewlDetail.materialUnits=fItem.materialUnits;
		//账面数量
		lnewlDetail.amount=fItem.amount;
		//盘点数量
		lnewlDetail.checkAmount=0;
		//进价
		lnewlDetail.tradePrice=fItem.tradePrice;
		//进价金额
		lnewlDetail.tradeMoney=fItem.tradePrice;
		//售价
		lnewlDetail.retailPrice=fItem.retailPrice;
		//售价金额
		lnewlDetail.retailMoney=fItem.retailPrice;
		//生产厂家
		lnewlDetail.factoryCode=fItem.factoryCode;
		//批号
		lnewlDetail.batch='0';
		//是否批号管理
		_bathSign=fItem.bathSign;
		//待发数量
		lnewlDetail.outAmount=0;
		//待入数量
		lnewlDetail.inAmount=0;
		//生产日期
		lnewlDetail.madeDate=fItem.madeDate;
		laryDetails.addItem(lnewlDetail);
	}
	
	gdCheckDetail.dataProvider=laryDetails;
	gdCheckDetail.selectedItem=lnewlDetail;
	fillDetailForm(lnewlDetail);
	var timer:Timer=new Timer(100, 1)
	timer.addEventListener(TimerEvent.TIMER, function(e:Event):void
		{
			gdCheckDetail.selectedIndex=gdCheckDetail.dataProvider.length - 1;
			checkAmount.setFocus();
		})
	timer.start();
}

/**
 * 明细表单赋值
 */
private function fillDetailForm(fselDetailItem:Object):void
{
	if (!fselDetailItem)
	{
		return;
	}
	materialCode.txtContent.text=fselDetailItem.materialCode;
	materialName.text=fselDetailItem.materialName;
	materialSpec.text=fselDetailItem.materialSpec;
	materialUnits.text=fselDetailItem.materialUnits;
	checkAmount.text=fselDetailItem.checkAmount + '';
	batch.text=fselDetailItem.batch;
	availDate.text=DateField.dateToString(fselDetailItem.availDate, 'YYYY-MM-DD');

}

/**
 * 数量进行改变事件
 */
private function amount_ChangeHandler(event:Event):void
{
	var lCheckDetail:MaterialCheckDetailDept=gdCheckDetail.selectedItem as MaterialCheckDetailDept;
	if (!lCheckDetail)
	{
		return;
	}
	lCheckDetail.checkAmount=parseFloat(checkAmount.text);
	lCheckDetail.checkAmount=isNaN(lCheckDetail.checkAmount) ? 1 : lCheckDetail.checkAmount;
	lCheckDetail.tradeMoney=lCheckDetail.checkAmount * lCheckDetail.tradePrice;
	lCheckDetail.retailMoney=lCheckDetail.checkAmount * lCheckDetail.retailPrice;
}

/**
 * 批号
 */
protected function batch_changeHandler(event:Event):void
{
	var lCheckDetail:MaterialCheckDetailDept=gdCheckDetail.selectedItem as MaterialCheckDetailDept;
	if (!lCheckDetail)
	{
		return;
	}
	lCheckDetail.batch=batch.text;
}

/**
 * 填充当前表单
 */
protected function gdCheckDetail_itemClickHandler(event:Event):void
{
	var lCheckDetail:MaterialCheckDetailDept=gdCheckDetail.selectedItem as MaterialCheckDetailDept;
	if (!lCheckDetail)
	{
		return;
	}
	fillDetailForm(lCheckDetail);
}

/**
 * 打印
 */
protected function printClickHandler(event:Event):void
{
	//打印权限
	if (!checkUserRole('05'))
	{
		return;
	}
	printReport("1");

}

/**
 * 输出
 */
protected function expClickHandler(event:Event):void
{
	//输出权限
	if (!checkUserRole('08'))
	{
		return;
	}
	printReport("0");

}

/**
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	var dataList:ArrayCollection=gdCheckDetail.dataProvider as ArrayCollection;
	var rawList:ArrayCollection=gdCheckDetail.getRawDataProvider() as ArrayCollection;
	var lastItem:Object=rawList.getItemAt(rawList.length - 1);
	preparePrintData(dataList);
	var dict:Dictionary=new Dictionary();
	
	dict["主标题"]="库存盘点单";
	dict["单位"]=AppInfo.currentUserInfo.unitsName;
	dict["仓库"]=storageCode.text;
	dict["入库单号"]=_materialCheckMasterDept.billNo;
	dict["入库日期"]=DateUtil.dateToString(_materialCheckMasterDept.billDate, 'YYYY-MM-DD');
	dict["表尾第二行"]=createPrintSecondBottomLine(lastItem);
	
	if (printSign == "1")
	{
		ReportPrinter.LoadAndPrint("report/materialDept/other/check.xml", dataList, dict);
	}
	else
	{
		ReportViewer.Instance.Show("report/materialDept/other/check.xml", dataList, dict);
	}
}

/**
 * 拼装打印数据，并计算页码
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
		
		item.factoryName=!item.factoryName ? '' : item.factoryName;
		item.pageNo=pageNo;
		item.factoryName=item.factoryName.substr(0, 6);
		item.materialSpec=item.materialSpec == null ? "" : item.materialSpec;
		item.materialUnits=item.materialUnits == null ? "" : item.materialUnits;
		item.nameSpec=item.materialName + " " + item.materialSpec;
	}
}

/**
 * 生成表格尾第二行
 * */
private function createPrintSecondBottomLine(fLastItem:Object):String
{
	var lstrLine:String="审核:{0}         制单:{1}     ";
	lstrLine=StringUtils.format(lstrLine, 
		verifier.text,
		maker.text)
	return lstrLine;
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

	//显示输入明细区域
	bord.height=111;
	hiddenVGroup.includeInLayout=true;
	hiddenVGroup.visible=true;

	toolBar.btStorage.enabled=true;
	//设置可写
	setReadOnly(false);
	//清空当前表单
	clearForm(true, true);
	//表头赋值
	//授权仓库赋值
	var deptItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', AppInfo.currentUserInfo.deptCode);
	storageCode.text=deptItem == null ? "" : deptItem.deptName;
	outRdType.txtContent.text="盘亏出库";
	inRdType.txtContent.text="盘盈入库";
	_materialCheckMasterDept.outRdType='202';
	_materialCheckMasterDept.inRdType='102';
	_materialCheckMasterDept.currentStatus='0';

	//表尾赋值
	maker.text=AppInfo.currentUserInfo.userName;
	makeDate.text=DateUtil.dateToString(new Date(), "YYYY-MM-DD");
	//得到区域
	materialCode.txtContent.setFocus();
}


/**
 * 修改
 */
protected function modifyClickHandler(event:Event):void
{
	//判断当前表格是否具有明细数据
	var laryDetails:ArrayCollection=gdCheckDetail.dataProvider as ArrayCollection;
	if (!laryDetails)
	{
		return;
	}

	//当前状态显示的值
	if (_materialCheckMasterDept.currentStatus == "2")
	{
		Alert.show("该库存盘点单已经审核，不能再修改");
		return;
	}
	if (_materialCheckMasterDept.currentStatus == "0")
	{
		toolBar.setEnabled(toolBar.btVerify, true);
	}
	else
	{
		toolBar.setEnabled(toolBar.btSave, false);
		toolBar.setEnabled(toolBar.btVerify, false);
	}
	//修改按钮初始化
	toolBar.modifyToPreState();
	//显示输入明细区域
	bord.height=111;
	hiddenVGroup.includeInLayout=true;
	hiddenVGroup.visible=true;

	//设置可写
	setReadOnly(false);
	//显示所选择的明细记录
	gdCheckDetail_itemClickHandler(null);
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

	if (_materialCheckMasterDept.autoId == "" || (_materialCheckMasterDept.autoId == null))
	{
		Alert.show("请先查询要删除的库存盘点单！", "提示信息");
		return;
	}

	if (_materialCheckMasterDept.currentStatus == '1')
	{
		Alert.show("库存盘点单已审核！", "提示信息");
		return;
	}
	else if (_materialCheckMasterDept.currentStatus == '2')
	{
		Alert.show("库存盘点单已记账！", "提示信息");
		return;
	}

	Alert.show("您确定要删除当前记录？", "提示信息", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
		{
			if (e.detail == Alert.YES)
			{
				var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
					{
						Alert.show("删除库存盘点单成功！", "提示信息");
						doInit();
						//清空当前表单
						clearForm(true, true);
					});
				ro.delCheck(_materialCheckMasterDept.autoId);
			}
		});
}


/**
 * 保存
 */
protected function saveClickHandler(event:Event):void
{
	//保存权限
	if (!checkUserRole('04'))
	{
		return;
	}
	var laryDetails:ArrayCollection=gdCheckDetail.dataProvider as ArrayCollection;
	if (!laryDetails)
	{
		Alert.show("库存盘点明细记录不能为空", "提示");
		return;
	}
	//填充主记录
	fillRdsMaster();
	//保存当前数据
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
		{
			if (rev && rev.data[0])
			{
				toolBar.saveToPreState();

				copyFieldsToCurrentMaster(rev.data[0], _materialCheckMasterDept);

				billNo.text=_materialCheckMasterDept.billNo;
				doInit();
				findCheckById(rev.data[0].autoId);
				Alert.show("库存盘点保存成功！", "提示信息");
				return;
			}
		});
	ro.saveCheck(_materialCheckMasterDept, laryDetails);
}

/**
 * 填充主记录,作为参数
 * */
private function fillRdsMaster():void
{
	// 仓库
	_materialCheckMasterDept.storageCode=AppInfo.currentUserInfo.deptCode;
	// 盘点单号
	_materialCheckMasterDept.billNo=billNo.text;
	// 盘点日期
	_materialCheckMasterDept.billDate=billDate.selectedDate;
	// 账面日期
	_materialCheckMasterDept.accountDate=accountDate.selectedDate;
	// 备注
	_materialCheckMasterDept.remark=remark.text;
}

/**
 * 复制当前数据记录
 */
private function copyFieldsToCurrentMaster(fsource:Object, ftarget:Object):void
{
	ObjectUtils.mergeObject(fsource, ftarget)
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
			//增加项隐藏
			bord.height=70;
			hiddenVGroup.includeInLayout=false;
			hiddenVGroup.visible=false;

			toolBar.cancelToPreState();
			//清空当前表单
			clearForm(true, true);
			//设置只读
			setReadOnly(true);
			toolBar.btStorage.enabled=false;
		})
}

/**
 * 审核
 */
protected function verifyClickHandler(event:Event):void
{
	//审核权限
	if (!checkUserRole('06'))
	{
		return;
	}

	//应为后台提供
	_materialCheckMasterDept.verifier=AppInfo.currentUserInfo.personId;
	_materialCheckMasterDept.verifyDate=new Date();

	if (_materialCheckMasterDept.currentStatus == "1")
	{
		Alert.show('库存盘点单已经审核', '提示信息');
		return;
	}

	Alert.show('您是否审核当前库存盘点单？', '提示信息', Alert.YES | Alert.NO, null, function(e:*):void
		{
			if (e.detail == Alert.YES)
			{
				var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
					{
						//显示输入明细区域
						bord.height=70;
						hiddenVGroup.includeInLayout=false;
						hiddenVGroup.visible=false;
						//设置只读
						setReadOnly(true);
						//赋当前审核状态
						_materialCheckMasterDept.currentStatus='1';
						//表尾赋值
						verifier.text=AppInfo.currentUserInfo.userName;
						verifyDate.text=DateUtil.dateToString(new Date(), "YYYY-MM-DD");
						findCheckById(rev.data[0].autoId);
						Alert.show("库存盘点单审核成功！", "提示信息");
					});
				ro.verifyCheck(_materialCheckMasterDept.autoId);
			}
		})
}

/**
 * 增行
 */
protected function addRowClickHandler(event:Event):void
{
	materialName.text="";
	materialSpec.text="";
	materialUnits.text="";
	
	checkAmount.text="";
	
	batch.text="0";
	availDate.text="";
	
	materialCode_queryIconClickHandler(null);
}

/**
 * 删行
 */
protected function delRowClickHandler(event:Event):void
{
	var laryDetails:ArrayCollection=gdCheckDetail.getRawDataProvider() as ArrayCollection;
	
	var lintMaxIndex:int=laryDetails.length;
	var lintSelIndex:int=gdCheckDetail.selectedIndex;
	if (lintSelIndex < 0 || lintSelIndex > lintMaxIndex - 1)
	{
		return;
	}
	
	var lCheckDetail:MaterialCheckDetailDept=gdCheckDetail.selectedItem as MaterialCheckDetailDept;
	if (!lCheckDetail)
	{
		Alert.show("请您选择要删除的记录！", "提示");
		return;
	}
	var lselIndex:int=gdCheckDetail.selectedIndex;
	Alert.show("您是否删除" + lCheckDetail.materialName + "吗？", "提示", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
	{
		if (e.detail == Alert.NO)
		{
			return;
		}
		if (lselIndex < 0)
		{
			return;
		}
		
		laryDetails.removeItemAt(lintSelIndex);
		if (lintSelIndex == 0)
		{
			lintSelIndex=1;
		}
		gdCheckDetail.selectedIndex=lintSelIndex - 1;
		Alert.show("删除明细记录成功!", "提示");
		return;
	});
}

/**
 * 查询
 */
protected function queryClickHandler(event:Event):void
{
	var queryWin:WinCheckQuery=PopUpManager.createPopUp(this, WinCheckQuery, true) as WinCheckQuery;
	queryWin.parentWin=this;
	FormUtils.centerWin(queryWin);
}

/**
 * 盘库事件响应方法
 * */
protected function storageClickHandler(event:Event):void
{
	var storageWin:WinCheckStorage=PopUpManager.createPopUp(this, WinCheckStorage, true) as WinCheckStorage;
	storageWin.parentWin=this;
	FormUtils.centerWin(storageWin);
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
	findCheckById(strAutoId);

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
	findCheckById(strAutoId);

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
	findCheckById(strAutoId);

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
	findCheckById(strAutoId);

	toolBar.lastPageToPreState();
}

/**
 * 翻页调用此函数
 * */
public function findCheckById(fstrAutoId:String):void
{
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
		{

			if (rev.data && rev.data.length > 0 && rev.data[0] != null && rev.data[1] != null)
			{
				_materialCheckMasterDept=rev.data[0] as MaterialCheckMasterDept;
				var details:ArrayCollection=rev.data[1] as ArrayCollection;

				//主记录赋值
				fillMaster(_materialCheckMasterDept);
				//明细赋值
				gdCheckDetail.dataProvider=details;
				stateButton(rev.data[0].currentStatus);
			}

		});
	ro.findCheckDetailList(fstrAutoId);
}


/**
 * 填充表头部分
 */
private function fillMaster(fmaterialCheckMasterDept:MaterialCheckMasterDept):void
{
	if (!fmaterialCheckMasterDept)
	{
		return;
	}
	FormUtils.fillFormByItem(this, fmaterialCheckMasterDept);
	
	var deptItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', fmaterialCheckMasterDept.storageCode);
	storageCode.text=deptItem == null ? "" : deptItem.deptName;
	FormUtils.fillTextByDict(outRdType, fmaterialCheckMasterDept.outRdType, 'deliverType');
	FormUtils.fillTextByDict(inRdType, fmaterialCheckMasterDept.inRdType, 'rdType');
	FormUtils.fillTextByDict(deptCode, fmaterialCheckMasterDept.deptCode, 'dept');
	FormUtils.fillTextByDict(personId, fmaterialCheckMasterDept.personId, 'personId');
	FormUtils.fillTextByDict(maker, fmaterialCheckMasterDept.maker, 'personId');
	FormUtils.fillTextByDict(verifier, fmaterialCheckMasterDept.verifier, 'personId');
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
 * 根据数据状态显示不同的按钮
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
 * 生产厂家
 */
private function factoryLBF(item:Object, column:DataGridColumn):String
{
	if (item.factoryCode == '')
	{
		item.factoryName='';
	}
	else
	{
		var provider:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict, 'provider', item.factoryCode);

		item.factoryName=provider == null ? "" : provider.providerName;
	}
	return item.factoryName;
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