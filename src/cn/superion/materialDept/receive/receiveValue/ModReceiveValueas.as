/**
 *	 高值耗材入库模块
 *	 author:芮玉红 2012.9.24
 *	 modify：
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
import cn.superion.materialDept.receive.receiveValue.view.WinReceiveQuery;
import cn.superion.materialDept.util.DefaultPage;
import cn.superion.materialDept.util.MainToolBar;
import cn.superion.materialDept.util.MaterialDictShower;
import cn.superion.materialDept.util.ReportParameter;
import cn.superion.report.hlib.UrlLoader;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialRdsDetailDept;
import cn.superion.vo.material.MaterialRdsMasterDept;
import cn.superion.vo.system.SysUnitInfor;

import flash.events.KeyboardEvent;
import flash.external.ExternalInterface;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.events.CloseEvent;
import mx.events.DataGridEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;
import mx.utils.StringUtil;

import spark.events.TextOperationEvent;

registerClassAlias("cn.superion.materialDept.entity.MaterialRdsMasterDept", cn.superion.vo.material.MaterialRdsMasterDept);
registerClassAlias("cn.superion.materialDept.entity.MaterialRdsDetailDept", cn.superion.vo.material.MaterialRdsDetailDept);

public static const MENU_NO:String="0105";
//服务类
public static const DESTANATION:String="deptReceiveValueImpl";

private var _winY:int=0;

private var _materialRdsMaster:MaterialRdsMasterDept=new MaterialRdsMasterDept();
private var _materialRdsDetail:MaterialRdsDetailDept=new MaterialRdsDetailDept();

//是否批号管理
[Bindable]
private var _bathSign:Boolean=false;

//查询主记录ID列表
public var arrayAutoId:Array=new Array();
//当前页，翻页用
public var currentPage:int=0;

private var salerClass:String='';


/**
 * 初始化当前窗口
 * */
public function doInit():void
{
	if(parentDocument is WinModual){
		parentDocument.title="高值耗材入库";
	}
	
	_winY=this.parentApplication.screen.height - 345;
	toolBar.btExp.label='条码'
	personId.width=supplyDeptCode.width;
	materialBarCode.width=materialCode.width;
	initPanel();
	setPrintPageToDefault();
	gdRdsDetail.colorWhereField='isGive';
	gdRdsDetail.colorWhereValue='1';
	gdRdsDetail.colorWhereColor=0x01b919;
	
	if(MaterialDictShower.isAllUnitsDict)
	{
		MaterialDictShower.getAdvanceDictList();
	}
	
	salerClass=ExternalInterface.call("getSalerClass");

}


/**
 * 面板初始化
 */
private function initPanel():void
{
	var ro:RemoteObject = RemoteUtil.getRemoteObject("unitInforImpl",function(rev:Object):void{
		if(rev.data.length > 0 ){
			for each (var it:SysUnitInfor in rev.data){
				it.label = it.unitsSimpleName;
				it.data = it.unitsCode;
			}
			MaterialDictShower.SYS_UNITS = rev.data;
		}
	});
	ro.findByEndSign("1");
	
	initToolBar();
	//增加项隐藏
	bord.height=70;
	hiddenVGroup.includeInLayout=false;
	hiddenVGroup.visible=false;
	
	//设置只读
	setReadOnly(true);
	//阻止表单输入
	preventDefaultForm();
	toolBar.btAbandon.label="弃审";
}
 
/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.imageList1,toolBar.btAbandon, toolBar.btAdd, toolBar.btModify, toolBar.btDelete, toolBar.btCancel, toolBar.btSave, toolBar.btVerify, toolBar.imageList2, toolBar.btAddRow, toolBar.btDelRow, toolBar.imageList3, toolBar.btQuery, toolBar.imageList5, toolBar.btFirstPage, toolBar.btPrePage, toolBar.btNextPage, toolBar.btLastPage, toolBar.imageList6, toolBar.btExit];
	var laryEnables:Array=[toolBar.btExit, toolBar.btQuery, toolBar.btAdd]
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 表头设置只读或读写状态
 */
private function setReadOnly(boolean:Boolean):void
{
	var i:String="";
	if(boolean){i="0"}else{i="1"}
	boolean=!boolean;
	blueType.enabled=boolean;
	redType.enabled=boolean;
	
	supplyDeptCode.enabled=boolean;
	
	billDate.enabled=boolean;
	
	operationNo.enabled=boolean;
	billNo.enabled=boolean;
	
	personId.enabled=boolean;
	remark.enabled=boolean;
}

/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{
	supplyDeptCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
	
	
	personId.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
	
	materialCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
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
		blueType.selected=true;
		
		supplyDeptCode.txtContent.text="";
		
		billDate.selectedDate=new Date();
		
		operationNo.text="";
		billNo.text="";
		
		personId.txtContent.text="";
		remark.text="";
		
		currentStockAmount.text="";
		maker.text='';
		makeDate.text='';
		verifier.text='';
		verifyDate.text='';
		
		_materialRdsMaster=new MaterialRdsMasterDept();
	}
	if (detailFlag)
	{
		materialCode.txtContent.text="";
		materialName.text="";
		packageSpec.text="";
		packageUnits.text="";
		
		amount.text="";
		
		batch.text="0";
		availDate.text="";
		
		detailRemark.text= '';
		gdRdsDetail.dataProvider=new ArrayCollection();
	}
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

	if (event.currentTarget == amount)
	{
		if(!_bathSign)
		{
			materialBarCode.setFocus();
			return;
		}
		else
		{
			batch.setFocus();
			return;
		}
	}
	if(event.currentTarget == materialCode){
		materialCode.txtContent.text = '';
		materialCode.txtContent.setFocus();
	}
	//
	FormUtils.toNextControl(event, fctrlNext);
}

/**
 * 供应商档案
 */
protected function supplyDeptCode_queryIconClickHandler(event:Event):void
{
	
	MaterialDictShower.showProviderDict(function(rev:Object):void
	{
		supplyDeptCode.txtContent.text=rev.providerName;
		
		_materialRdsMaster.supplyDeptCode=rev.providerId;
		operationNo.setFocus();
		
	}, x, _winY,null,salerClass,false);
}


/**
 * 人员档案
 */
protected function personId_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict(function(rev:Object):void
	{
		personId.txtContent.text=rev.name;
		
		_materialRdsMaster.personId=rev.personId;
	}, x, y);
}


/**
 * 高值物资字典
 */
protected function materialCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	
	MaterialDictShower.showMaterialValueDict(function(fItem:Object):void
	{
		fillIntoGrid(fItem);
	}, x, y);
}

protected function gdRdsDetail_itemEditBeginHandler(event:DataGridEvent):void
{
	var lastIndex:int = gdRdsDetail.dataProvider.length - 1;
	if(lastIndex == event.rowIndex - 1){
		var ss:Boolean = event.cancelable;
		event.preventDefault();
		gdRdsDetail.selectedIndex = lastIndex
	}
}

/**
 * 自动完成表格回调
 * */
private function fillIntoGrid(fItem:Object):void
{
	var laryDetails:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	
	var lnewlDetail:MaterialRdsDetailDept=new MaterialRdsDetailDept();
	materialBarCode.text='';
	lnewlDetail.materialId=fItem.materialId;
	lnewlDetail.materialClass=fItem.materialClass;
	lnewlDetail.materialCode=fItem.materialCode;
	lnewlDetail.materialName=fItem.materialName;
	lnewlDetail.materialSpec=fItem.materialSpec;
	lnewlDetail.materialUnits=fItem.materialUnits;
	
	if(fItem.amountPerPackage == '' || fItem.amountPerPackage == null){
		lnewlDetail.amountPerPackage = 1;
	}else{	
		lnewlDetail.amountPerPackage = fItem.amountPerPackage;
	}
	
	lnewlDetail.amount = 1;
	lnewlDetail.tradePrice=fItem.tradePrice;
	lnewlDetail.tradeMoney=fItem.tradePrice;
	lnewlDetail.wholeSalePrice=fItem.wholeSalePrice;
	lnewlDetail.wholeSaleMoney=fItem.wholeSaleMoney;
	lnewlDetail.retailPrice=fItem.retailPrice;
	lnewlDetail.retailMoney=fItem.retailPrice;
	lnewlDetail.batch='0'
	lnewlDetail.factoryCode=fItem.factoryCode;
	lnewlDetail.currentStockAmount=fItem.amount;
	
	lnewlDetail.outAmount=0;
	lnewlDetail.outSign='0';
	
	lnewlDetail.highValueSign=fItem.highValueSign;
	lnewlDetail.agentSign=fItem.agentSign;
	//是否单独计价
	lnewlDetail.chargeSign=fItem.chargeSign;
	//会计科目分类
	lnewlDetail.classOnAccount=fItem.accountClass;
	
	//是否批号管理
	_bathSign=fItem.batchSign=='1' ? true : false;
	
	lnewlDetail.isGive='0';
	lnewlDetail.isSelected=false;
	laryDetails.addItem(lnewlDetail); 
	
	
	gdRdsDetail.dataProvider=laryDetails;
	gdRdsDetail.selectedIndex=laryDetails.length - 2;
	fillDetailForm(lnewlDetail);
	
	var timer:Timer=new Timer(100, 1)
	timer.addEventListener(TimerEvent.TIMER, function(e:Event):void
	{
		gdRdsDetail.scrollToIndex(gdRdsDetail.selectedIndex);
		amount.setFocus();
	})
	timer.start();
}

/**
 * 明细表单赋值 
 */
private function fillDetailForm(fselDetailItem:MaterialRdsDetailDept):void
{
	if (!fselDetailItem)
	{
		return;
	}
	//
	materialCode.txtContent.text=fselDetailItem.materialCode;
	materialName.text=fselDetailItem.materialName;
	packageSpec.text=fselDetailItem.materialSpec;
	packageUnits.text=fselDetailItem.packageUnits;
	
	amount.text=fselDetailItem.amount + '';
	batch.text=fselDetailItem.batch;
	availDate.text=DateField.dateToString(fselDetailItem.availDate, 'YYYY-MM-DD');
	
	currentStockAmount.text=fselDetailItem.currentStockAmount + '';
	detailRemark.text = fselDetailItem.detailRemark;
	materialBarCode.text=fselDetailItem.materialBarCode;
}

/**
 * 数量进行改变事件
 */
public function amount_ChangeHandler(event:Event):void
{
	var lRdsDetail:MaterialRdsDetailDept=gdRdsDetail.selectedItem as MaterialRdsDetailDept;
	if (!lRdsDetail)
	{
		return;
	}
	var isCharDuplication:Boolean = false;
	var trimedText:String = mx.utils.StringUtil.trim(amount.text); 
	for(var i:int = 1; i < trimedText.length;i ++){
		if(trimedText.charAt(i) == '-'){
			isCharDuplication = true;
			break;
		}
	}
	if(isCharDuplication){
		amount.text = '-';
		amount.selectRange(1,amount.text.length);;
		return;	
	}
	if(isNaN(Number(trimedText)) || trimedText == '' ){
		lRdsDetail.amount = 0;
	}else{
		lRdsDetail.amount=isNaN(lRdsDetail.amount) ? 1 : lRdsDetail.amount;
	}
	lRdsDetail.amount = parseFloat(amount.text);
	lRdsDetail.tradeMoney=lRdsDetail.amount * lRdsDetail.tradePrice;
	lRdsDetail.wholeSaleMoney=lRdsDetail.amount * lRdsDetail.wholeSalePrice;
	lRdsDetail.retailMoney= Number((lRdsDetail.amount * lRdsDetail.retailPrice).toFixed(2));
}
/**
 * 数量失去焦点，若是蓝字，则为正，否则为负
 * */
protected function amount_focusOutHandler(event:FocusEvent):void
{
	if(redOrBlue.selection == blueType){
		if(Number(amount.text)  > 0 ){
			return;	
		}
		amount.text = Number(0-Number(amount.text)).toString();
		
	}else{
		if(Number(amount.text)  < 0 ){
			return;	
		}
		if(amount.text == '-'){
			amount.text = '0';
		}
		amount.text = Number(0-Number(amount.text)).toString();
	}
	amount_ChangeHandler(null);
}
/**
 * 批号
 */
protected function batch_changeHandler(event:Event):void
{
	var lRdsDetail:MaterialRdsDetailDept=gdRdsDetail.selectedItem as MaterialRdsDetailDept;
	if (!lRdsDetail)
	{
		return;
	}
	lRdsDetail.batch=batch.text;
}

/**
 * 有效日期
 */
protected function availDate_changeHandler(event:Event):void
{
	var lRdsDetail:MaterialRdsDetailDept=gdRdsDetail.selectedItem as MaterialRdsDetailDept;
	if (!lRdsDetail)
	{
		return;
	}
	
	lRdsDetail.availDate=availDate.selectedDate;
}
/**
 * 发票日期
 */
protected function invoiceDate_changeHandler(event:Event):void
{
	var laryDetails:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	if (laryDetails.length == 0)
	{
		return;
	}
}
/**
 * 发票号
 * */
protected function invoiceNo_changeHandler(event:TextOperationEvent):void
{
	var laryDetail:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	if (laryDetail.length == 0)
	{
		return;
	}
}

/** 
 * 产品码
 * */
protected function materialBarCode_changeHandler(event:TextOperationEvent):void
{
	var lRdsDetail:MaterialRdsDetailDept=gdRdsDetail.selectedItem as MaterialRdsDetailDept;
	if (!lRdsDetail)
	{
		return;
	}
	
	lRdsDetail.materialBarCode=materialBarCode.text;
}

/** 
 * 明细备注
 * */
protected function detailRemark_changeHandler(event:TextOperationEvent):void
{
	var lRdsDetail:MaterialRdsDetailDept=gdRdsDetail.selectedItem as MaterialRdsDetailDept;
	if (!lRdsDetail)
	{
		return;
	}
	
	lRdsDetail.detailRemark=detailRemark.text;
}
/**
 * 填充当前表单
 */
protected function gdRdsDetail_itemClickHandler(event:Event):void
{
	var lRdsDetail:MaterialRdsDetailDept=gdRdsDetail.selectedItem as MaterialRdsDetailDept;
	if (!lRdsDetail)
	{
		return;
	}
	fillDetailForm(lRdsDetail);
}

//打印
protected function printClickHandler(event:Event):void
{
	printReport("1");
	
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
		if(item.rdBillNo!=rdBillNo){
			rdBillNo=item.rdBillNo
			pageNo++;
		}
		item.wholeSalePrice = item.amount * item.wholeSalePrice; //
		item.invitePrice = item.amount * item.invitePrice; //
		item.retailPrice = item.amount * item.retailPrice; //
		item.tradePrice = item.amount * item.tradePrice; //
		
		item.factoryName=!item.factoryName ? '' : item.factoryName
		item.pageNo=pageNo;
		item.factoryName = item.factoryName.substr(0,6);
		
		item.packageUnits = item.packageUnits == null ? item.materialUnits:item.packageUnits
		item.materialSpec = item.materialSpec == null ? "" : item.materialSpec;
		item.nameSpec = item.materialName + " "+item.materialSpec
	}
}

/**
 * 生成表格尾第二行
 * */
private function createPrintSecondBottomLine(fLastItem:Object):String
{
	var lstrLine:String = "";
//	if(isShowPurchase){
//		var purchaser:Object = ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict,'personId',_materialRdsMaster.personId);
//		lstrLine = "采购:{0}          审核:{1}         制单:{2}  ";
//		lstrLine=StringUtils.format(lstrLine, 
//			purchaser?purchaser.personIdName:"",
//			"",
//			maker.text)
//	}
//	else{
//		lstrLine = "审核:{0}         制单:{1}        ";
//		lstrLine=StringUtils.format(lstrLine, 
//			"",
//			maker.text)
//	}
	
	return lstrLine;
}

/**
 * 打印
 */
private function printReport(printSign:String):void
{
	setPrintPageSize()
	var dataList1:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	var dataList:ArrayCollection = ObjectUtil.copy(dataList1) as ArrayCollection;
	var rawList:ArrayCollection = gdRdsDetail.getRawDataProvider() as ArrayCollection;
	var lastItem:Object=rawList.getItemAt(rawList.length - 1);
	preparePrintData(dataList);
	var dict:Dictionary=new Dictionary();
	
	dict["主标题"]="高值耗材入库单";
	dict["单位"] = AppInfo.currentUserInfo.unitsName;
	dict["日期"] = new Date();

	
	dict["供应单位"]=supplyDeptCode.text;
	dict["入库单号"]=_materialRdsMaster.billNo;
	dict["入库日期"]=DateUtil.dateToString(_materialRdsMaster.billDate,'YYYY-MM-DD');
	dict["业务号"]=operationNo.text;
	dict["业务员"]=personId.text;
	dict["备注"]=remark.text;

	dict["合计进价"]=lastItem.tradeMoney.toFixed(2);//批发价
	dict["表尾第二行"]=createPrintSecondBottomLine(lastItem)
	var reportUrl:String="report/materialDept/receive/receiveValue.xml";
	loadReportXml(reportUrl, dataList, dict,printSign,1)
}


private function loadReportXml(reportUrl:String,faryDetails:ArrayCollection, fdict:Dictionary,fprintSign:String,pageNum:int):void{
	var loader:UrlLoader=new UrlLoader();
	loader.addEventListener(Event.COMPLETE, function(event:Event):void{
		var xml:XML=XML(event.currentTarget.Data)
		if(ReportParameter.reportPrintHeight_in&&ReportParameter.reportPrintHeight_in!='0'){
			var lreportHeight:String=parseFloat(ReportParameter.reportPrintHeight_in)/10+''
			xml.PageHeight=lreportHeight	
		}		
		
		
		if (fprintSign == "1")
		{ 
			ReportPrinter.Print(xml, faryDetails, fdict,null,false,pageNum);
		}
		else
		{
			ReportViewer.Instance.Show(xml, faryDetails, fdict);
		}
	});
	loader.Load(reportUrl);
}

//条形码
protected function expClickHandler(event:Event):void
{
	var printDataList:ArrayCollection=new ArrayCollection();
	var dataList:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	
	for each(var item:Object in dataList)
	{
		item.materialSpec=item.materialSpec==null ? "" : item.materialSpec;
		item.materialUnits=item.materialUnits==null ? "" : item.materialUnits;
		item.factoryName=item.factoryName==null ? "" : item.factoryName.length > 10 ? (item.factoryName).substr(0,10) : item.factoryName;
		item.materialDetail=item.materialName + " " + item.materialSpec + " " + item.materialUnits + " " + item.factoryName;
		
		
	}
	var dict:Dictionary=new Dictionary();
	
	dict["单位"] = AppInfo.currentUserInfo.unitsName;
	
	dict["供应商"]=supplyDeptCode.text;
	dict["登记日期"]=DateUtil.dateToString(_materialRdsMaster.billDate,'YYYY-MM-DD');
	var reportUrl:String="report/materialDept/receive/receiveValueBar.xml";
	
	loadReportXml(reportUrl, dataList, dict,'1',2);
	
}

//增加
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
	bord.height=140;
	hiddenVGroup.includeInLayout=true;
	hiddenVGroup.visible=true;
	
	//设置可写
	setReadOnly(false);
	//清空当前表单
	clearForm(true, true);
	
	_materialRdsMaster.rdFlag='1';
	_materialRdsMaster.currentStatus='0';
	
	//表尾赋值
	maker.text=AppInfo.currentUserInfo.userName;
	makeDate.text=DateUtil.dateToString(new Date(), "YYYY-MM-DD");
	//得到区域
	supplyDeptCode.txtContent.setFocus();
}
/**
 * 弃审按钮
 */ 
protected function toolBar_abandonClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	Alert.show('您是否弃审该张单据？', '提示信息', Alert.YES | Alert.NO, null, function(e:*):void
	{
		if (e.detail == Alert.YES)
		{
			var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
			{
				findRdsById(_materialRdsMaster.autoId);
				Alert.show("高值耗材入库弃审成功！", "提示信息");
			});
			ro.cancelVerifyRds(_materialRdsMaster.autoId);
		}
	})
}

//修改
protected function modifyClickHandler(event:Event):void
{
	//判断当前表格是否具有明细数据
	var laryDetails:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	if (!laryDetails)
	{
		return;
	}
	
	//当前状态显示的值
	if (_materialRdsMaster.currentStatus == "2")
	{
		Alert.show("该入库单已经审核，不能再修改");
		return;
	}
	if (_materialRdsMaster.currentStatus == "0")
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
	bord.height=140;
	hiddenVGroup.includeInLayout=true;
	hiddenVGroup.visible=true;
	
	//设置可写
	setReadOnly(false);
	//显示所选择的明细记录
	gdRdsDetail_itemClickHandler(null);
}


//删除
protected function deleteClickHandler(event:Event):void
{
	//删除权限
	if (!checkUserRole('03'))
	{
		return;
	}
	
	if (_materialRdsMaster.autoId == "" || (_materialRdsMaster.autoId == null))
	{
		Alert.show("请先查询要删除的高值耗材入库单！", "提示信息");
		return;
	}
	
	if (_materialRdsMaster.currentStatus == '1')
	{
		Alert.show("该高值耗材入库单已审核！", "提示信息");
		return;
	}
	else if (_materialRdsMaster.currentStatus == '2')
	{
		Alert.show("该高值耗材入库单已记账！", "提示信息");
		return;
	}
	
	Alert.show("您确定要删除当前记录？", "提示信息", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
	{
		if (e.detail == Alert.YES)
		{
			var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
			{
				Alert.show("删除高值耗材入库单成功！", "提示信息");
				doInit();
				//清空当前表单
				clearForm(true, true);
			});
			ro.deleteRds(_materialRdsMaster.autoId);
		}
	});
}

/**
 * 保存
 * */
protected function saveClickHandler(event:Event):void
{
	//保存权限
	if (!checkUserRole('04'))
	{
		return;
	}
	if (!validateMaster())
	{
		return;
	}
	var laryDetails:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	for each(var item:Object in laryDetails)
	{
//		if(!item.availDate)
//		{
//			gdRdsDetail.selectedIndex=laryDetails.getItemIndex(item);
//			Alert.show('第'+item.serialNo+'行的"有效日期"为空，请填写完整','提示');
//			return;
//		}
		if(item.availDate && DateUtil.getTimeSpans(item.availDate,new Date()) >0)
		{
			gdRdsDetail.selectedIndex=laryDetails.getItemIndex(item);
			Alert.show('第'+item.serialNo+'行的"有效日期"填写不合法','提示');
			return;
		}
		if(item.isSelected)
		{
			item.isGive='1';
		}
	}
	if (laryDetails.length == 0 )
	{
		Alert.show("入库单明细记录不能为空", "提示");
		return;
	}
	if(!MainToolBar.validateItem(gdRdsDetail,['amount'],['0']))
		return;
	//填充主记录
	fillRdsMaster();
	toolBar.btSave.enabled = false;
	//保存当前数据
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		if (rev && rev.data[0])
		{
			toolBar.saveToPreState();
			//
			copyFieldsToCurrentMaster(rev.data[0], _materialRdsMaster);
			//
			billNo.text=_materialRdsMaster.billNo;
			doInit();
			findRdsById(rev.data[0].autoId);
			Alert.show("高值耗材入库保存成功！", "提示信息");
			return;
		}
	});
	ro.saveRds(_materialRdsMaster, laryDetails);
}
/**
 * 点击红蓝单
 * */
protected function redOrBlue_changeHandler(event:Event):void
{
	var laryDetails:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	if(laryDetails.length ==0){
		return	
	}
	Alert.show('切换单据类型将清空页面数据','提示',Alert.YES | Alert.NO,null,function(e:*):void{
		if (e.detail == Alert.YES ){
			//清空页面数据
			FormUtils.clearForm(hg1);
			FormUtils.clearForm(hg2);
			FormUtils.clearForm(detailGroup);
			gdRdsDetail.dataProvider = [];
		}else{
			redOrBlue.selection = event.target.selection == redType?blueType:redType;
		}
	}) 
}
/**
 * 保存前验证主记录
 */
private function validateMaster():Boolean
{
	if (supplyDeptCode.txtContent.text == "")
	{
		supplyDeptCode.txtContent.setFocus();
		Alert.show("供应单位必填", "提示");
		return false;
	}
	
	return true;
}

/**
 * 填充主记录,作为参数
 * */
private function fillRdsMaster():void
{
	_materialRdsMaster.invoiceType=blueType.selected ? '1' : '2';
	_materialRdsMaster.billNo=billNo.text;
	_materialRdsMaster.billDate=billDate.selectedDate;
	_materialRdsMaster.operationNo=operationNo.text;
	_materialRdsMaster.storageCode="V"+AppInfo.currentUserInfo.deptCode;
	_materialRdsMaster.deptCode=AppInfo.currentUserInfo.deptCode;
	
	
	_materialRdsMaster.remark=remark.text;
}

/**
 * 复制当前数据记录
 */
private function copyFieldsToCurrentMaster(fsource:Object, ftarget:Object):void
{
	ObjectUtils.mergeObject(fsource, ftarget)
}

//放弃
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
	})
}

//审核
protected function verifyClickHandler(event:Event):void
{
	//审核权限
	if (!checkUserRole('06'))
	{
		return;
	}
	
	//应为后台提供
	_materialRdsMaster.verifier=AppInfo.currentUserInfo.personId;
	_materialRdsMaster.verifyDate=new Date();
	
	if (_materialRdsMaster.currentStatus == "1")
	{
		Alert.show('该高值耗材入库单已经审核', '提示信息');
		return;
	}
	
	Alert.show('您是否审核当前高值耗材入库单？', '提示信息', Alert.YES | Alert.NO, null, function(e:*):void
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
				_materialRdsMaster.currentStatus='1';
				//表尾赋值
				verifier.text=AppInfo.currentUserInfo.userName;
				verifyDate.text=DateUtil.dateToString(new Date(), "YYYY-MM-DD");
				findRdsById(rev.data[0].autoId);
				Alert.show("高值耗材入库单审核成功！", "提示信息");
			});
			ro.verifyRds(_materialRdsMaster.autoId);
		}
	})
}

//增行
protected function addRowClickHandler(event:Event):void
{
	materialName.text="";
	packageSpec.text="";
	packageUnits.text="";
	
	amount.text="";
	
	batch.text="0";
	availDate.text="";
	
	materialCode_queryIconClickHandler(null);
}

//删行
protected function delRowClickHandler(event:Event):void
{
	var laryDetails:ArrayCollection=gdRdsDetail.getRawDataProvider() as ArrayCollection;
	
	var lintMaxIndex:int=laryDetails.length;
	var lintSelIndex:int=gdRdsDetail.selectedIndex;
	if (lintSelIndex < 0 || lintSelIndex > lintMaxIndex - 1)
	{
		clearForm(false,true);
		return;
	}
	
	var lRdsDetail:MaterialRdsDetailDept=gdRdsDetail.selectedItem as MaterialRdsDetailDept;
	if (!lRdsDetail)
	{
		Alert.show("请您选择要删除的记录！", "提示");
		return;
	}
	
	//已保存
	var lselIndex:int=gdRdsDetail.selectedIndex;
	//	Alert.show("您是否删除" + lRdsDetail.materialName + "吗？", "提示", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
	//	{
	//		if (e.detail == Alert.NO)
	//		{
	//			return;
	//		}
	if (lselIndex < 0)
	{
		return;
	}
	
	laryDetails.removeItemAt(lintSelIndex);
	if (lintSelIndex == 0)
	{
		//			clearForm(false,true);
		lintSelIndex=1;
	}
	gdRdsDetail.selectedIndex=lintSelIndex - 1;
	gdRdsDetail_itemClickHandler(null);
	
	
	//	})
}

//查询
protected function queryClickHandler(event:Event):void
{
	var win:WinReceiveQuery=PopUpManager.createPopUp(this, WinReceiveQuery, true) as WinReceiveQuery;
	win.parentWin=this;
	FormUtils.centerWin(win);
}

//首页
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

//下一页
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

//上一页
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

//末页
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
		
		if (rev.data && rev.data.length > 0 && rev.data[0] != null && rev.data[1] != null)
		{
			_materialRdsMaster=rev.data[0] as MaterialRdsMasterDept;
			var details:ArrayCollection=rev.data[1] as ArrayCollection;
			
			//主记录赋值
			fillMaster(_materialRdsMaster);
			//明细赋值
			for each(var item:Object in details)
			{
				if(item.isGive=='1')
				{
					item.isSelected=true;
				}
			}
			gdRdsDetail.dataProvider=details;
			stateButton(rev.data[0].currentStatus);
		}
		
	});
	ro.findRdsDetailById(fstrAutoId);
}

/**
 * 填充表头部分
 */
private function fillMaster(materialRdsMaster:MaterialRdsMasterDept):void
{
	if (!materialRdsMaster)
	{
		return;
	}
	FormUtils.fillFormByItem(this, materialRdsMaster);
	
	
	var _deptObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict,'provider',materialRdsMaster.supplyDeptCode);
	supplyDeptCode.text=_deptObj==null ? materialRdsMaster.supplyDeptCode : _deptObj.providerName;
	
	blueType.selected = materialRdsMaster.invoiceType == "1" ? true:false;
	redType.selected = materialRdsMaster.invoiceType == "2" ? true:false;
	FormUtils.fillTextByDict(personId, materialRdsMaster.personId, 'personId');
	FormUtils.fillTextByDict(maker, materialRdsMaster.maker, 'personId');
	FormUtils.fillTextByDict(verifier, materialRdsMaster.verifier, 'personId');
}

/**
 * LabFunction 处理售价显示
 */
private function retailPriceLBF(item:Object, column:DataGridColumn):String
{
	//若存在包装系数，则返回 包装系数 * 包装数量
	if(item.amountPerPackage && item.amountPerPackage!='0'){
		return (item.amountPerPackage * item.retailPrice).toFixed(2);
	}else{
		return item.retailPrice == null ? "":(item.retailPrice).toFixed(2);
	}
}

/**
 * LabFunction 处理批发价显示
 */
private function wholeSalePriceLBF(item:Object, column:DataGridColumn):String
{
	//若存在包装系数，则返回 包装系数 * 包装数量
	if(item.amountPerPackage && item.amountPerPackage!='0'){
		return (item.amountPerPackage * item.wholeSalePrice).toFixed(2);
	}else{
		return item.wholeSalePrice == null ? "": (item.wholeSalePrice).toFixed(2);;
	}
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
 * 更具数据状态显示不同的按钮
 */
protected function stateButton(currentStatus:String):void
{
	var state:Boolean=(currentStatus == "0" ? true : false);
	toolBar.btModify.enabled=state;
	toolBar.btDelete.enabled=state;
	toolBar.btVerify.enabled=state;
	toolBar.btPrint.enabled=true;
	toolBar.btExp.enabled=true;
	toolBar.btAbandon.enabled=(currentStatus == "1" ? true : false);
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
 
//退出
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
 * 设置默认打印机的打印页面
 * */
private function setPrintPageSize():void{
	var lnumWidth:Number=210*1000
	var lnumHeight:Number=parseFloat(ReportParameter.reportPrintHeight_in)
	lnumHeight=isNaN(lnumHeight)?288*1000:lnumHeight*1000 
	ExternalInterface.call("setPrintPageSize",lnumWidth,lnumHeight)
}
 

/**
 * 恢复默认打印机的打印页面
 * */
private function setPrintPageToDefault():void{
	ExternalInterface.call("setPrintPageToDefault")
}
