import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.DateUtil;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.ObjectUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.base.util.StringUtils;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialDept.receive.receiveApply.view.WinReceiveApplyQuery;
import cn.superion.materialDept.util.DefaultPage;
import cn.superion.materialDept.util.MaterialCurrentStockShower;
import cn.superion.materialDept.util.MaterialDictShower;
import cn.superion.materialDept.util.ToolBar;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.center.material.CdMaterialDict;
import cn.superion.vo.cssd.DeptPackageMaterial;
import cn.superion.vo.material.CdDeptLimit;
import cn.superion.vo.material.MaterialProvideDetail;
import cn.superion.vo.material.MaterialProvideMaster;

import flash.events.KeyboardEvent;
import flash.external.ExternalInterface;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.core.IFlexDisplayObject;
import mx.core.UIComponent;
import mx.events.CloseEvent;
import mx.events.CollectionEvent;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;
import mx.utils.StringUtil;
import mx.validators.NumberValidator;
import mx.validators.StringValidator;
import mx.validators.Validator;

import spark.events.IndexChangeEvent;
import spark.events.TextOperationEvent;

registerClassAlias("cn.superion.material.entity.MaterialProvideMaster", MaterialProvideMaster);
registerClassAlias("cn.superion.material.entity.MaterialProvideDetail", MaterialProvideDetail);
[Bindable]
private var _tempSalerCode:String;
private var _tempDeptId:String;
private var _tempStorageCode:String;
private var _tempPersonId:String;
private var _tempCorporation:String;
private var _tempBatch:String;
private var _tempMaterialId:String;
private var _btModifyBeClicked:Boolean = false;
public var queryStockSign:Boolean = false; //是否执行查找库存方法
private var _materialProvideMaster:MaterialProvideMaster = new MaterialProvideMaster();
private var _vAll:Array = [];

public static const MENU_NO:String="0101";
//服务类
public static const DESTANATION:String="deptApplyImpl";
private var _winY:int=0;


//查询主记录ID列表
public var arrayAutoId:Array=new Array();
//当前页，翻页用
public var currentPage:int=0;
private var storageDeptCode:String = "";
private var isUseMaterialCard:Boolean = false;
private var isCheckAmount:Boolean = false; //是否需要验证申请最大数
private var maxAmount:Number = 0; //参数表中定义的最大数量
private var isDeptList:Boolean=false;

//是否允许零出库 ryh 13.2.22
[Bindable]
private var isZeroDeliver:Boolean;
private var _isShow:Boolean=false;//显示小数位数，东方3，泰州2
private var seasonArray:ArrayCollection = new ArrayCollection([{"month":"1","season":"1"},{"month":"2","season":"1"},{"month":"3","season":"1"},
	{"month":"4","season":"2"},{"month":"5","season":"2"},{"month":"6","season":"2"},
	{"month":"7","season":"3"},{"month":"8","season":"3"},{"month":"9","season":"3"},
	{"month":"10","season":"4"},{"month":"11","season":"4"},{"month":"12","season":"4"}]);

/**
 * 初始化当前窗口
 * */
public function doInit():void
{
	parentDocument.title="物资领用申请";
	_winY=this.parentApplication.screen.height - 345;
	cardCode.width=storageCode.width;
	accountRemain.width=supplyDeptCode.width;
	
	initPanel();
	useMaterialCard();
	
	isDeptList=ExternalInterface.call("getIsDeptList");
	
	if(isDeptList && AppInfo.currentUserInfo.deptList && AppInfo.currentUserInfo.deptList.length>0)
	{
		deptCode.dataProvider = AppInfo.currentUserInfo.deptList;
	}
	else
	{
//		deptCode.dataProvider = new ArrayCollection([{deptCode:AppInfo.currentUserInfo.deptCode,deptName:AppInfo.currentUserInfo.deptName}]);
	}
	
	//初始化参数
	initParam();
	var currentYear:String = DateUtil.dateToString(new Date(),"YYYY");
	var currentMonth:String = DateUtil.dateToString(new Date(),"MM");
	var index:int = Number(currentMonth) - 1;
	var season:String = seasonArray[index].season;
	if(deptCode.dataProvider.length>0){
		var code:String ='';
		if(!deptCode.selectedItem){
			code = deptCode.dataProvider[0].deptCode;
		}else{
			code = deptCode.selectedItem?deptCode.selectedItem.deptCode:""
		}
		initDeptLimit(currentYear,season,code);
	}
	
	
	
}


protected function deptCode_changeHandler(event:IndexChangeEvent):void
{
	// TODO Auto-generated method stub
	var currentYear:String = DateUtil.dateToString(new Date(),"YYYY");
	var currentMonth:String = DateUtil.dateToString(new Date(),"MM");
	var index:int = Number(currentMonth) - 1;
	var season:String = seasonArray[index].season;
	if(deptCode.dataProvider.length>0){
		var code:String ='';
		if(!deptCode.selectedItem){
			code = deptCode.dataProvider[0].deptCode;
		}else{
			code = deptCode.selectedItem?deptCode.selectedItem.deptCode:""
		}
		initDeptLimit(currentYear,season,code);
	}
}


private function initDeptLimit(year:String,season:String,deptCode:String):void{
	
	
	var param:ParameterObject=new ParameterObject();
	var _fparameter:Object = {};
	_fparameter.deptCode =deptCode;// deptCode.selectedItem?deptCode.selectedItem.deptCode:""
	_fparameter.years = year;
	_fparameter.season =season;
	param.conditions = _fparameter
	//是否显示三位小数。
	var rod:RemoteObject=RemoteUtil.getRemoteObject('sendImpl', function(rev:Object):void
	{
		seasonLimit.text = usedLimit.text = remainLimit.text = '';
		if(rev.data && rev.data.length>0){
			var limit:CdDeptLimit = rev.data[0]
			seasonLimit.text = limit.limits;
			usedLimit.text = limit.addUp;
			remainLimit.text = (limit.limits - limit.addUp).toString();
		}
		
	});
	rod.findDeptLimitInfo(year,season,deptCode);
	
}
private function initParam():void
{
	var ro:RemoteObject=RemoteUtil.getRemoteObject("centerSysParamImpl",function(rev:Object):void
	{
		if (rev.data && rev.data[0] == '1')
		{
			isZeroDeliver=true; //允许零出库
		}
		else{
			isZeroDeliver=false; //不允许零出库
		}
	});
	ro.findSysParamByParaCode("0601");
	
	//是否显示三位小数。
	var rod:RemoteObject=RemoteUtil.getRemoteObject('centerSysParamImpl', function(revd:Object):void
	{
		if (revd.data && revd.data[0] == '1')
		{
			_isShow=true; 
			dgDetail.format = [,,,,,'0.000','0.000','0.000','0.000'];
		}
		else{
			_isShow=false; 
		}
		
	});
	rod.findSysParamByParaCode("0602");
}

/**
 * 判断是否显示领用卡号
 **/
private function useMaterialCard():void
{
	//查找系统参数，
	var ro:RemoteObject=RemoteUtil.getRemoteObject('centerSysParamImpl',function(rev:Object):void{
		if(rev.data[0] != null){
			isUseMaterialCard = rev.data[0] == "1" ? true:false;
			labCardCode.visible=isUseMaterialCard;
			labCardCode.includeInLayout = isUseMaterialCard;
			cardCode.visible=isUseMaterialCard;
			cardCode.includeInLayout = isUseMaterialCard;
			labAccountRemain.visible=isUseMaterialCard;
			labAccountRemain.includeInLayout = isUseMaterialCard;
			accountRemain.visible=isUseMaterialCard;
			accountRemain.includeInLayout = isUseMaterialCard
			//
		}
		var ro:RemoteObject=RemoteUtil.getRemoteObject('centerSysParamImpl',function(rev:Object):void{
			if(rev.data[0] != null){
				isCheckAmount = true
				maxAmount = rev.data[0];
				//
			}
		});
		ro.findSysParamByParaCode("0102");
	});
	ro.findSysParamByParaCode("0205");
}

/**
 * 面板初始化
 * */
private function initPanel():void
{
	initToolBar();
	//仓库下拉框
//	storageCode.dataProvider = AppInfo.currentUserInfo.storageList;
//	storageCode.selectedIndex = 0;
	var result:ArrayCollection =ObjectUtil.copy(AppInfo.currentUserInfo.storageList) as ArrayCollection;
	var newArray:ArrayCollection = new ArrayCollection();
	for each(var it:Object in result){
		if(it.type == '1'||it.type == '3'){
			newArray.addItem(it);
		}
	}
	storageCode.dataProvider=newArray;//AppInfo.currentUserInfo.storageList;
	storageCode.selectedIndex=0;
	//根据仓库查所属科室
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION,function(rev:Object):void{
		if(rev.data.length>0){
			storageDeptCode = rev.data[0][0];
			supplyDeptCode.text = rev.data[0][1];
		}
	});
	ro.findDeptByStorageCode(storageCode.selectedItem.storageCode);
	
	deptCode.textInput.editable=false;
	//
	setReadOnly(true);
	//隐藏明细查询组件
	bord.height=64;
	amount.editable = false;
	initValidate();
	//阻止表单输入
	preventDefaultForm();
	toolBar.btAbandon.label="弃审";
}
/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	//初始按钮组
	var laryDisplays:Array =[toolBar.btPrint, toolBar.btExp, toolBar.imageList1,toolBar.btAbandon, 
		toolBar.btAdd, toolBar.btModify, toolBar.btDelete, toolBar.btCancel, 
		toolBar.btSave, toolBar.btVerify, toolBar.imageList2,toolBar.btAddRow,
		toolBar.btDelRow, toolBar.imageList3, toolBar.btQuery, toolBar.imageList5, 
		toolBar.btFirstPage, toolBar.btPrePage, toolBar.btNextPage, toolBar.btLastPage,
		toolBar.imageList6, toolBar.btExit];
	var laryEnables:Array =[toolBar.btAdd, toolBar.btQuery, toolBar.btExit];
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 表头设置只读或读写状态
 */
private function setReadOnly(boolean:Boolean):void
{
	boolean=!boolean;
	blueType.enabled=boolean;
	redType.enabled=boolean;
	supplyDeptCode.enabled = boolean;
	
	billDate.enabled=boolean;
	billNo.enabled=boolean;
	
	cardCode.enabled=boolean;
	accountRemain.enabled=boolean;
	remark.enabled=boolean;
}

/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{
//	supplyDeptCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
//	{
//		e.preventDefault();
//	})
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
		
		cardCode.text="";
		
		billDate.selectedDate=new Date();
		
		billNo.text="";
		
		accountRemain.text="";
		remark.text="";
		_materialProvideMaster=new MaterialProvideMaster();
	}
	if (detailFlag)
	{
		materialCode.txtContent.text="";
		materialName.text="";
		materialSpec.text="";
		materialUnits.text="";
		
		amount.text="";
		
		dgDetail.dataProvider=new ArrayCollection();
	}
}
/**
 * 显示明细组件
 * */
private function detailComponents(top:UIComponent,height:Number,bottom:UIComponent,b:Boolean):void{
	top.height=height;
	bottom.includeInLayout = b;
	bottom.visible = b;
}

/**
 * 点击红蓝单
 * */
protected function redOrBlue_changeHandler(event:Event):void
{
	var laryDetails:ArrayCollection=dgDetail.dataProvider as ArrayCollection;
	if(laryDetails.length ==0){
		return	
	}
	Alert.show('切换单据类型将清空页面数据','提示',Alert.YES | Alert.NO,null,function(e:*):void{
		if (e.detail == Alert.YES ){
			//清空页面数据
			FormUtils.clearForm(hg1);
			FormUtils.clearForm(hg2);
			FormUtils.clearForm(detailGroup);
			dgDetail.dataProvider = [];
		}else{
			redOrBlue.selection = event.target.selection == redType?blueType:redType;
		}
	}) 
}

/**
 * 处理键的keyUp事件
 * */
protected function keyUpCtrl(event:KeyboardEvent, ctrl:Object):void
{
	if(event.keyCode != 13){
		return;
	}
	if(event.currentTarget.className == "TextInput"){
		//					if(StringUtil.trim(event.currentTarget.text).length == 0||
		//						event.currentTarget.text == '0'){
		//						return;
		//					}
	}
	if(ctrl.className == "DropDownList"){
		ctrl.openDropDown();
	}
	if(ctrl.className == "DateField"){
		ctrl.open();
	}
	if(ctrl.className == "TextInputIcon"){
		ctrl.txtContent.setFocus();
		return;
	}
	ctrl.setFocus();
}

/**
 * 领用卡号回车事件
 * */
protected function cardCode_enterHandler():void
{
	if(StringUtil.trim(cardCode.text).length == 0){
		accountRemain.setFocus();
		return;
	}
	//调用后台查询方法
	var ro:RemoteObject = RemoteUtil.getRemoteObject(ModReceiveApply.DESTANATION,function(rev:Object):void{
		accountRemain.text = rev.data[0] == null||""?"0":rev.data[0];
		accountRemain.setFocus();
	});
	ro.findAccountRemain(cardCode.text);
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
	lstorageCode=(storageCode.selectedItem || {}).storageCode;
	
	MaterialDictShower.showMaterialDictNew(lstorageCode, '', '', true, function(fItem:Array):void
	{
		fillIntoGrid(fItem);
	}, x, y,isZeroDeliver);
}

/**
 * 自动完成表格回调
 * */
private function fillIntoGrid(fItem:Array):void
{
	var laryDetails:ArrayCollection=dgDetail.dataProvider as ArrayCollection;
	
	for (var i:int = 0 ;i < fItem.length; i ++){

	var lnewlDetail:MaterialProvideDetail=new MaterialProvideDetail();
	
	lnewlDetail.materialId=fItem[i].materialId;
	lnewlDetail.materialClass=fItem[i].materialClass;
	lnewlDetail.barCode=fItem[i].barCode;
	lnewlDetail.materialCode=fItem[i].materialCode;
	lnewlDetail.materialName=fItem[i].materialName;
	lnewlDetail.materialSpec=fItem[i].materialSpec;
	lnewlDetail.materialUnits=fItem[i].materialUnits;
	
	lnewlDetail.packageSpec=fItem[i].packageSpec;
	lnewlDetail.packageUnits=fItem[i].packageUnits;
	if(fItem[i].amountPerPackage == '' || fItem[i].amountPerPackage == null){
		lnewlDetail.amountPerPackage = 1;
	}else{
		lnewlDetail.amountPerPackage = fItem[i].amountPerPackage;
	}
	lnewlDetail.amount = 1;
	
	lnewlDetail.amount = 1;
	
	lnewlDetail.tradePrice=fItem[i].tradePrice;
	lnewlDetail.tradeMoney=fItem[i].tradePrice;
	
	lnewlDetail.factTradePrice=fItem[i].tradePrice * fItem[i].rebateRate;
	lnewlDetail.factTradeMoney=fItem[i].tradePrice * fItem[i].rebateRate;
	
	lnewlDetail.rebateRate=fItem[i].rebateRate;
	lnewlDetail.rebateRate=isNaN(lnewlDetail.rebateRate) ? 1 : lnewlDetail.rebateRate;
	lnewlDetail.planAmount=isNaN(lnewlDetail.planAmount) ? 1 : lnewlDetail.planAmount;
	
	lnewlDetail.wholeSalePrice=fItem[i].wholeSalePrice;
	lnewlDetail.wholeSaleMoney=fItem[i].wholeSalePrice;
	
	lnewlDetail.invitePrice=fItem[i].invitePrice;
	lnewlDetail.inviteMoney=fItem[i].invitePrice;
	
	lnewlDetail.retailPrice=fItem[i].retailPrice;
	lnewlDetail.retailMoney=fItem[i].retailPrice;
	lnewlDetail.batch='0'
	lnewlDetail.factoryCode=fItem[i].factoryCode;
	lnewlDetail.mainProvider=fItem[i].mainProvider;
	lnewlDetail.currentStockAmount=fItem[i].amount;
	
	lnewlDetail.outAmount=0;
	lnewlDetail.outSign='0';
	
	lnewlDetail.registerNo=fItem[i].registerNo;
	lnewlDetail.inviteNo=fItem[i].inviteNo;
	lnewlDetail.countClass=fItem[i].countClass;
	
	lnewlDetail.invoiceAmount=0;
	lnewlDetail.invoiceSign='0';
	
	lnewlDetail.highValueSign=fItem[i].highValueSign;
	lnewlDetail.agentSign=fItem[i].agentSign;
	lnewlDetail.storageMaterialSign = fItem[i].storageMaterialSign;
	lnewlDetail.chargeSign = fItem[i].chargeSign;//收费标示；
	lnewlDetail.classOnAccount = fItem[i].accountClass;//会计分类；
	lnewlDetail.checkAmount=0;
	
	lnewlDetail.virtualAmount = fItem[i].virtualAmount;//虚拟库存 ryh 13.2.25 主要针对东方医院不允许零出库
	
	for(var j:int=0;j<laryDetails.length;j++){
		if(lnewlDetail.materialId == laryDetails.getItemAt(j).materialId){
			Alert.show('明细中已存在相同的'+lnewlDetail.materialName+'物资');
			return;
		}
	}
	laryDetails.addItem(lnewlDetail);
	
	}

	dgDetail.dataProvider=laryDetails;
	dgDetail.selectedIndex=laryDetails.length - 2;
	fillDetailForm(lnewlDetail);
	
	if(redOrBlue.selectedValue == '2'){
		batch_queryIconClickHandler(null);      //byzcl
	}
	
	
	var timer:Timer=new Timer(100, 1)
	timer.addEventListener(TimerEvent.TIMER, function(e:Event):void
	{
		dgDetail.scrollToIndex(dgDetail.selectedIndex);
		amount.editable = true;
		amount.setFocus();
	})
	timer.start();
	storageCode.enabled = false;
}

/**
 * 明细表单赋值 checked by zzj 2011.06.04
 */
private function fillDetailForm(fselDetailItem:MaterialProvideDetail):void
{
	if (!fselDetailItem)
	{
		return;
	}
	materialCode.txtContent.text=fselDetailItem.materialCode;
	materialName.text=fselDetailItem.materialName;
	amount.text = fselDetailItem.amount.toFixed(2);
	tradePrice.text = fselDetailItem.tradePrice.toFixed(2);
	tradeMoney.text = fselDetailItem.tradeMoney.toFixed(2);

	var _storageCode:String=storageCode.selectedItem.storageCode;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION,function(rev:Object):void
	{
		if(rev.data && rev.data[0])
		{
			virtualAmount.text = rev.data[0];
		}
		else
		{
			virtualAmount.text = fselDetailItem.amount.toFixed(2);
		}
	});
	ro.findVirtualAmountByMaterialId(_storageCode,fselDetailItem.materialId);
	
}

/**
 * 数量进行改变事件
 */
private function amount_ChangeHandler(event:Event):void
{
	var lRdsDetail:MaterialProvideDetail=dgDetail.selectedItem as MaterialProvideDetail;
	if (!lRdsDetail)
	{
		return;
	}
	var isCharDuplication:Boolean = false;
	var trimedText:String = StringUtil.trim(amount.text); 
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
		lRdsDetail.amount=parseFloat(amount.text) * lRdsDetail.amountPerPackage;
	}
	
	//不允许零出库 ryh 13.2.22
//	if(blueType.selected && !isZeroDeliver)
//	{
//		if(Number(amount.text) > 0 && Number(amount.text) > Number(virtualAmount.text))
//		{
//			Alert.show('申领数量大于现存量','提示');
//			amount.text='0.00'
//			return;
//		}
//	}
	
	lRdsDetail.amount = parseFloat(amount.text);
	//
	lRdsDetail.tradeMoney=lRdsDetail.amount * lRdsDetail.tradePrice;
	lRdsDetail.factTradeMoney=Number((lRdsDetail.amount * lRdsDetail.factTradePrice).toFixed(2));
	
	lRdsDetail.wholeSaleMoney=Number((lRdsDetail.amount * lRdsDetail.wholeSalePrice).toFixed(2));
	lRdsDetail.inviteMoney= Number((lRdsDetail.amount * lRdsDetail.invitePrice).toFixed(2));
	
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
 * 填充当前表单 checked by zzj 2011.04.22
 */
protected function dgDetail_itemClickHandler(event:Event):void
{
	var lRdsDetail:MaterialProvideDetail=dgDetail.selectedItem as MaterialProvideDetail;
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

//输出
protected function expClickHandler(event:Event):void
{
	printReport("0");
	
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
		item.factoryName=!item.factoryName ? '' : item.factoryName
		item.pageNo=pageNo;
		item.factoryName = item.factoryName.substr(0,6);
		item.packageSpec = item.packageSpec == null ? "" : item.packageSpec;
		item.packageUnits = item.packageUnits == null ? "" : item.packageUnits;
		item.materialSpec = item.materialSpec == null ? "" : item.materialSpec;
		item.nameSpec = item.materialName + " "+(item.packageSpec == null ? "" : item.packageSpec);
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
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	var dataList:ArrayCollection=dgDetail.dataProvider as ArrayCollection;
	var rawList:ArrayCollection = dgDetail.getRawDataProvider() as ArrayCollection;
	var lastItem:Object=rawList.getItemAt(rawList.length - 1);
	preparePrintData(dataList);
	var dict:Dictionary=new Dictionary();
	
	dict["主标题"]="采购入库单";
	dict["单位"] = AppInfo.currentUserInfo.unitsName;
	dict["仓库"] = ArrayCollUtils.findItemInArrayByValue(BaseDict.storageDict, 'storage', _materialProvideMaster.storageCode) == null?
		"":ArrayCollUtils.findItemInArrayByValue(BaseDict.storageDict, 'storage', _materialProvideMaster.storageCode).storageName;
	
	dict["供应单位"]=_materialProvideMaster.salerName == null ? "" : _materialProvideMaster.salerName.substr(0,10);
	dict["入库单号"]=_materialProvideMaster.billNo;
	dict["入库日期"]=DateUtil.dateToString(_materialProvideMaster.billDate,'YYYY-MM-DD');
	var dept:Object = ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', _materialProvideMaster.deptCode);
	dict["合计进价"]=lastItem.tradeMoney.toFixed(2);//批发价
	dict["表尾第二行"]=createPrintSecondBottomLine(lastItem)
	if (printSign == "1")
	{
		ReportPrinter.LoadAndPrint("report/material/receive/receive.xml", dataList, dict);
	}
	else
	{
		ReportViewer.Instance.Show("report/material/receive/receive.xml", dataList, dict);
	}
}

/**
 * 增加
 * */
protected function addClickHandler(event:Event):void
{
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, "01"))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	} 
	//增加按钮
	toolBar.addToPreState()
	_btModifyBeClicked = false;
	//显示明细组件
	detailComponents(bord,111,hiddenVGroup,true);
	//设置可写
	setReadOnly(false);
	//清空当前表单
	clearForm(true, true)
	queryStockSign = true;
	supplyDeptCode.setFocus();
	storageCode.enabled = true;
	billDate.enabled = billNo.enabled = false;
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
		materialCode.txtContent.text='';
		materialCode.txtContent.setFocus();
		return;
	}
	if(event.currentTarget == materialCode){
		materialCode.txtContent.text = '';
		materialCode.txtContent.setFocus();
	}
	//
	FormUtils.toNextControl(event, fctrlNext);
}
/**
 * 当前角色权限认证
 */
public  function checkUserRole(role:String):Boolean
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
 * 修改
 * */
protected function modifyClickHandler(event:Event):void
{
	if (!checkUserRole('02'))
	{
		return;
	}

	//判断当前表格是否具有明细数据
	var laryDetails:ArrayCollection=dgDetail.dataProvider as ArrayCollection;
	if (!laryDetails)
	{
		return;
	}
	
	//当前状态显示的值
	if (_materialProvideMaster.currentStatus == "2")
	{
		Alert.show("该入库单已经审核，不能再修改");
		return;
	}
	if (_materialProvideMaster.currentStatus == "0")
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
	detailComponents(bord,111,hiddenVGroup,true);
	//设置可写
	setReadOnly(false);
	//显示所选择的明细记录
	dgDetail_itemClickHandler(null)
	
}

/**
 * 删除
 * */
protected function deleteClickHandler(event:Event):void
{
	if (!checkUserRole('03'))
	{
		return;
	}
	if(_materialProvideMaster.currentStatus == "1"){
		Alert.show('该单据已审核','提示');
		return;
	}
	Alert.show('确定删除单据号为['+_materialProvideMaster.billNo+']的单据？','提示',Alert.YES | Alert.NO,null,function(e:*):void{
		if (e.detail == Alert.YES ) {
			var ro:RemoteObject = RemoteUtil.getRemoteObject(DESTANATION,function(rev:Object):void{
				Alert.show("删除成功！", "提示信息");
				doInit();
				//清空当前表单
				clearForm(true, true);
			});
			ro.deleteApply(_materialProvideMaster.autoId);
		}else{
			return;
		}
	})
}

/**
 * 初始化验证
 * */
private function initValidate():void{
	//String类验证
	var lcontrols:Array = [];
	for each (var control:* in lcontrols){
		var vRequired:StringValidator=new StringValidator();
		vRequired.source = control.className == "TextInputIcon" ? control.txtContent : control;
		vRequired.property="text"
		vRequired.required=true
		vRequired.requiredFieldError="必填"
		_vAll.push(vRequired);
	}
}

/**
 * @return 布尔值，若通过则为true，否则为false
 * */
private function validateData():Boolean{
	var vResults:Array=Validator.validateAll( _vAll)
	if(vResults.length > 0 || dgDetail.dataProvider.length == 0) return false;
	return true;
}

/**
 * 填充报表尾部，当保存，修改，删除，审核成功、或翻页查询时，调用
 * @param item,MaterialProvideMaster对象
 * */
private function fillReportFoot(item:Object):void{
	makeDate.text = DateUtil.dateToString(item.makeDate,"YYYY-MM-DD");
	maker.text = ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict,'personId',item.maker)==null?
		item.maker:ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict,'personId',item.maker).personIdName;
	verifier.text = ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict,'personId',item.verifier)==null?
		item.verifier:ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict,'personId',item.verifier).personIdName;;
	verifyDate.text = DateUtil.dateToString(item.verifyDate,"YYYY-MM-DD");
}

/**
 * 校验表格中的数量是否大于参数定义的最大数；
 * @param itemsAmount,表格中的数量；
 * @param paramAmount,系统参数表中定义的最大数；
 * */
private function compareAmount(itemsAmount:Number,paramAmount:Number):Number{
	return itemsAmount - paramAmount;
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
	//
	if (!validateMaster())
	{
		return;
	}
	// 表体部分----------------------------------------------------------------------------
	var detail:ArrayCollection = dgDetail.dataProvider as ArrayCollection;
	if(detail.length == 0 ){
		Alert.show("请录入数据","提示");
		return ;
	}
	//根据系统参数判断是否限制单据数量
	if(isCheckAmount){
		//验证每张单据的最大数
		var itemsAmount:Number = detail.length;
		if(compareAmount(itemsAmount,maxAmount)>0){
			Alert.show("每张单据最大数量不能超过【"+maxAmount+"】条","提示");
			return;
		}
	}
		
	for each(var obj:Object in detail){
		if(obj.amount == 0){
			Alert.show("申请数量不可以为0","提示");
			return;
		}
	}
	//填充主记录
	fillProvideMaster();
	var ro:RemoteObject = RemoteUtil.getRemoteObject(DESTANATION,function(rev:Object):void{
		
		toolBar.saveToPreState();
		//
		copyFieldsToCurrentMaster(rev.data[0], _materialProvideMaster);
		billNo.text = rev.data[0].billNo;
		billNo.editable = false;
		// 表尾部分----------------------------------------------------------------------------
		fillReportFoot(rev.data[0])
		_materialProvideMaster = rev.data[0];
//		doInit();
		findRdsById(rev.data[0].autoId);
		Alert.show("保存成功！", "提示信息");
		toolBar.btSave.enabled = false;
		return;
	});
	
	ro.saveApply(_materialProvideMaster, detail);
}

/**
 * 保存前验证主记录
 */
private function validateMaster():Boolean
{
	if (!storageCode.selectedItem)
	{
		storageCode.setFocus();
		Alert.show("供应仓库必填", "提示");
		return false;
	}
	if (!deptCode.selectedItem)
	{
		deptCode.setFocus();
		Alert.show("申领科室必填", "提示");
		return false;
	}
	return true;
}

/**
 * 填充主记录,作为参数
 * */
private function fillProvideMaster():void
{
	_materialProvideMaster.storageCode = storageCode.selectedItem.storageCode;
	_materialProvideMaster.billNo = StringUtil.trim(billNo.text).length>0?billNo.text:"";
	_materialProvideMaster.billDate=billDate.selectedDate;
	_materialProvideMaster.accountRemain = Number(accountRemain.text.length == 0?0:accountRemain.text);
	_materialProvideMaster.cardCode = cardCode.text;
//	_materialProvideMaster.deptCode = AppInfo.currentUserInfo.deptCode;//5-18新增加
	
	_materialProvideMaster.deptCode = deptCode.selectedItem.deptCode;//2013.01.24
	_materialProvideMaster.manualSign = '0';
	_materialProvideMaster.supplyDeptCode = storageDeptCode; //供应部门，写仓库所在部门编码
	_materialProvideMaster.invoiceType = redOrBlue.selectedValue.toString();
	_materialProvideMaster.remark = remark.text;
}
/**
 * 复制当前数据记录
 */
private function copyFieldsToCurrentMaster(fsource:Object, ftarget:Object):void
{
	ObjectUtils.mergeObject(fsource, ftarget)
}

/**
 * 仓库改变时
 * */
protected function storageCode_changeHandler(event:IndexChangeEvent):void
{
	// TODO Auto-generated method stub
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION,function(rev:Object):void{
		if(rev.data.length>0){
			storageDeptCode = rev.data[0][0];
			supplyDeptCode.text = rev.data[0][1];
		}
		else
		{
			storageDeptCode = "";
			supplyDeptCode.text = "";
		}
	});
	ro.findDeptByStorageCode(storageCode.selectedItem.storageCode);
}
/**
 * 放弃，增加的时候若放弃，按钮全部灰化
 * */
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

/**
 * 审核
 * */
protected function verifyClickHandler(event:Event):void
{
	
	if (!checkUserRole('06'))
	{
		return;
	}
	if(_materialProvideMaster.currentStatus == "1"){
		Alert.show('该单据已审核','提示');
		return;
	}
	Alert.show('确定审核单据号为['+_materialProvideMaster.billNo+']的单据？','提示',Alert.YES | Alert.NO,null,function(e:*):void{
		if (e.detail == Alert.YES ) {
			_materialProvideMaster.currentStatus = '1';
		
			var ro:RemoteObject = RemoteUtil.getRemoteObject(DESTANATION,function(rev:Object):void{
				
				//显示输入明细区域
				bord.height=70;
				hiddenVGroup.includeInLayout=false;
				hiddenVGroup.visible=false;
				//设置只读
				setReadOnly(true);
				//赋当前审核状态
				_materialProvideMaster.currentStatus='1';
				//表尾赋值
				verifier.text=AppInfo.currentUserInfo.userName;
				verifyDate.text=DateUtil.dateToString(new Date(), "YYYY-MM-DD");
				findRdsById(rev.data[0].autoId);
				Alert.show("审核成功！", "提示信息");
				
			});
			ro.verifyApply(_materialProvideMaster.autoId,"1");
		}else{
			return;
		}
	})
}
/**
 * 增行
 * */
protected function addRowClickHandler(event:Event):void
{
	materialName.text="";
	materialSpec.text="";
	materialUnits.text="";
	
	amount.text="";
	
	materialCode_queryIconClickHandler(null);
}
/**
 * 删行
 * */
protected function delRowClickHandler(event:Event):void
{
	var laryDetails:ArrayCollection=dgDetail.getRawDataProvider() as ArrayCollection;
	
	var lintMaxIndex:int=laryDetails.length;
	var lintSelIndex:int=dgDetail.selectedIndex;
	if (lintSelIndex < 0 || lintSelIndex > lintMaxIndex - 1)
	{
		return;
	}
	
	var lRdsDetail:MaterialProvideDetail=dgDetail.selectedItem as MaterialProvideDetail;
	if (!lRdsDetail)
	{
		Alert.show("请您选择要删除的记录！", "提示");
		return;
	}
	
	//已保存
	var lselIndex:int=dgDetail.selectedIndex;
	Alert.show("您是否删除" + lRdsDetail.materialName + "吗？", "提示", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
	{
		if (e.detail == Alert.NO)
		{
			return;
		}
		if (lselIndex < 0)
		{
			storageCode.enabled = true;
			return;
		}
		
		laryDetails.removeItemAt(lintSelIndex);
		if (lintSelIndex == 0)
		{
			storageCode.enabled = true;
			lintSelIndex=1;
		}
		dgDetail.selectedIndex=lintSelIndex - 1;
		
		return;
		
	})
}

/**
 * 查找
 * */
protected function queryClickHandler(event:Event):void
{
	var win:WinReceiveApplyQuery=WinReceiveApplyQuery(PopUpManager.createPopUp(this, WinReceiveApplyQuery, true));
	win.iparentWin = this;
	FormUtils.centerWin(win);
}

/**
 * 弃审按钮
 */ 
protected function abandonClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	Alert.show('您是否弃审该张单据？', '提示信息', Alert.YES | Alert.NO, null, function(e:*):void
	{
		if (e.detail == Alert.YES)
		{
			var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
			{
				findRdsById(_materialProvideMaster.autoId);
				Alert.show("领用申请单弃审成功！", "提示信息");
			});
			ro.cancelApply(_materialProvideMaster.autoId);
		}
	})
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
	var ro:RemoteObject = RemoteUtil.getRemoteObject(ModReceiveApply.DESTANATION,function(rev:Object):void{
		var m:MaterialProvideMaster = rev.data[0] as MaterialProvideMaster;
		var details:ArrayCollection = rev.data[1] as ArrayCollection;
		if(m!=null && details.length > 0){
			_materialProvideMaster=rev.data[0] as MaterialProvideMaster;
			//主记录赋值
			fillMaster(_materialProvideMaster);
			//明细赋值
			dgDetail.dataProvider=details;
			stateButton(rev.data[0].currentStatus);
		}
	});
	ro.findApplyDetailById(fstrAutoId);
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
 * 填充表头部分
 */
private function fillMaster(materialProvideMaster:MaterialProvideMaster):void
{
	if (!materialProvideMaster)
	{
		return;
	}
	FormUtils.fillFormByItem(this, materialProvideMaster)
	
	var selectedIndex:int = ArrayCollUtils.findItemIndexInArray(AppInfo.currentUserInfo.storageList,'storageCode',materialProvideMaster.storageCode);
	
	storageCode.selectedIndex = selectedIndex;
	FormUtils.fillTextByDict(supplyDeptCode, materialProvideMaster.supplyDeptCode, 'dept');
//	FormUtils.fillTextByDict(deptCode, materialProvideMaster.deptCode, 'dept');
	
	//领用部门
	var _index:int=ArrayCollUtils.findItemIndexInArray(deptCode.dataProvider,'deptCode',materialProvideMaster.deptCode);
	deptCode.selectedIndex=_index;
	
	FormUtils.fillTextByDict(maker, materialProvideMaster.maker, 'personId');
	FormUtils.fillTextByDict(verifier, materialProvideMaster.verifier, 'personId');
	
	blueType.selected=materialProvideMaster.invoiceType=='1';
	redType.selected=materialProvideMaster.invoiceType=='2';
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
 * 退出
 * */
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
 * 设置组件是否可用
 * rootId:指定的父组件id；b:true，为可用
 * */
private function setToolKitEnable(rootId:UIComponent, b:Boolean):void{
	var childs:Number = rootId.numChildren;
	for(var i :int = 0 ;i < childs; i ++){
		var disObj:UIComponent =  rootId.getChildAt(i) as UIComponent;
		disObj.enabled = b;
	}
}
/**
 * 响应表格数据变化事件
 * */
public function dgDetail_dataChangeHandler(event:CollectionEvent):void
{
	toolBar.btPrint.enabled = toolBar.btDelRow.enabled
		=toolBar.btExp.enabled = ary.length == 0 ? false:true;
}

/**
 * 根据数量计算：进价金额、售价金额、核算价金额
 * */
protected function amount_changeHandler(event:Event):void
{
	var lRdsDetail:MaterialProvideDetail=dgDetail.selectedItem as MaterialProvideDetail;
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
		lRdsDetail.amount = 1;
	}else{
		lRdsDetail.amount = Number(trimedText);
	}
	//不允许零出库 ryh 13.2.22
//	if(blueType.selected && !isZeroDeliver)
//	{
//		if(Number(amount.text) > 0 && Number(amount.text) > Number(virtualAmount.text))
//		{
//			Alert.show('申领数量大于现存量','提示');
//			amount.text='0.00'
//			return;
//		}
//	}
	
	
	lRdsDetail.tradeMoney=lRdsDetail.amount * lRdsDetail.tradePrice;
	lRdsDetail.factTradeMoney=Number((lRdsDetail.amount * lRdsDetail.factTradePrice).toFixed(2));
	
	lRdsDetail.wholeSaleMoney=Number((lRdsDetail.amount * lRdsDetail.wholeSalePrice).toFixed(2));
	lRdsDetail.inviteMoney= Number((lRdsDetail.amount * lRdsDetail.invitePrice).toFixed(2));
	
	lRdsDetail.retailMoney= Number((lRdsDetail.amount * lRdsDetail.retailPrice).toFixed(2));
}

/**
 * 打印，输出
 * */
protected function printExpClickHandler(lstrPurview:String, isPrintSign:String):void
{
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, lstrPurview))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}

	var _dataList:ArrayCollection=dgDetail.dataProvider as ArrayCollection;
	
	for each (var item:Object in _dataList)
	{
	     item.detailRemark= item.detailRemark==null ? "" : item.detailRemark;
	}
	var dict:Dictionary = new Dictionary();
	
	preparePrintData(_dataList);
	dict["单位名称"] = AppInfo.currentUserInfo.unitsName;
	dict["日期"] =DateField.dateToString(new Date(),'YYYY-MM-DD');
	dict["主标题"] = "物资领用申请";
	dict["制单人"] ="制单人:"+AppInfo.currentUserInfo.userName;
	dict["制单日期"] = makeDate.text;
	dict["审核人"] = verifier.text;
	dict["审核日期"] = verifyDate.text;
	dict["供应仓库"]=storageCode.selectedItem.storageName;
	dict["供应部门"]=supplyDeptCode.text;
	dict["单据编号"]=billNo.text;
	dict["单据日期"]=billDate.text;
	dict["领用卡号"]=cardCode.text;
	dict["帐户余额"]=accountRemain.text;
	dict["备注"]=remark.text;
	if(isPrintSign=='1') 
	{
		ReportPrinter.LoadAndPrint("report/materialDept/receive/apply.xml",_dataList,dict);
	}
	if(isPrintSign=='0')
	{
		ReportViewer.Instance.Show("report/materialDept/receive/apply.xml",_dataList,dict);
	}
}


protected function cardCode_focusOutHandler(event:FocusEvent):void
{
	// TODO Auto-generated method stub
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
 * 批号字典
 */
protected function batch_queryIconClickHandler(event:Event):void
{
	var lselItem:MaterialProvideDetail=dgDetail.selectedItem as MaterialProvideDetail;
	if (lselItem == null)
	{
		return;
	}
	
	var lstorageCode:String='';
	lstorageCode=(storageCode.selectedItem || {}).storageCode;
	//打开批号字典
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 338;
	
	MaterialCurrentStockShower.showCurrentStock(lstorageCode, lselItem.materialId, '', function(faryItems:Array):void
	{
		fillIntoGridByBatch(faryItems);
	}, x, y);
}

/**
 * 批号字典自动完成表格回调
 * */
private function fillIntoGridByBatch(faryItems:Array):void
{
	var lRdsDetail:MaterialProvideDetail=dgDetail.selectedItem as MaterialProvideDetail;
	if (!lRdsDetail)
	{
		return;
	}
	var i:int=0;
	var laryDetails:ArrayCollection=dgDetail.dataProvider as ArrayCollection;
	
	for each (var item:Object in faryItems)
	{
		var lnewlDetail:MaterialProvideDetail=new MaterialProvideDetail();
		if (i == 0)
		{
			//batch.text=item.batch;
			
			lRdsDetail.tradePrice=item.tradePrice;
			lRdsDetail.factoryCode=item.factoryCode;
			lRdsDetail.madeDate=item.madeDate;
			lRdsDetail.batch=item.batch;
			lRdsDetail.availDate=item.availDate;
			lRdsDetail.wholeSalePrice=item.wholeSalePrice;
			lRdsDetail.retailPrice=item.retailPrice;
			lnewlDetail.currentStockAmount=item.amount;
			//			lRdsDetail.wholeSaleMoney=item.wholeSaleMoney;
			//			lRdsDetail.retailMoney=item.retailMoney;
			
			lnewlDetail=lRdsDetail;
			i++;
			continue;
		}
		
		lnewlDetail.materialId=lRdsDetail.materialId;
		lnewlDetail.materialClass=lRdsDetail.materialClass;
		lnewlDetail.barCode=lRdsDetail.barCode;
		lnewlDetail.materialCode=lRdsDetail.materialCode;
		lnewlDetail.materialName=lRdsDetail.materialName;
		lnewlDetail.materialSpec=lRdsDetail.materialSpec;
		lnewlDetail.materialUnits=lRdsDetail.materialUnits;
		
		lnewlDetail.amount=lRdsDetail.amount;
		
		lnewlDetail.tradePrice=item.tradePrice;
		lnewlDetail.tradeMoney=0;
		
		lnewlDetail.rebateRate=lRdsDetail.rebateRate;
		lnewlDetail.rebateRate=isNaN(lRdsDetail.rebateRate) ? 1 : lRdsDetail.rebateRate;
		
		lnewlDetail.factTradePrice=lRdsDetail.tradePrice * lRdsDetail.rebateRate;
		lnewlDetail.factTradeMoney=0;
		
		lnewlDetail.wholeSalePrice=lRdsDetail.wholeSalePrice;
		lnewlDetail.wholeSaleMoney=Number((lRdsDetail.amount * lRdsDetail.wholeSalePrice).toFixed(2))
		
		lnewlDetail.invitePrice=lRdsDetail.invitePrice;
		lnewlDetail.inviteMoney=0;
		
		lnewlDetail.retailPrice=lRdsDetail.retailPrice;
		lnewlDetail.retailMoney=Number((lRdsDetail.amount * lRdsDetail.retailPrice).toFixed(2));
		
		lnewlDetail.factoryCode=item.factoryCode;
		
		lnewlDetail.currentStockAmount=item.amount;
		
		lnewlDetail.madeDate=item.madeDate;
		lnewlDetail.batch=item.batch;
		lnewlDetail.availDate=item.availDate;
		
		
		lnewlDetail.outAmount=0;
		lnewlDetail.outSign='0';
		
		lnewlDetail.invoiceAmount=0;
		lnewlDetail.invoiceSign='0';
		
		lnewlDetail.highValueSign=lRdsDetail.highValueSign;
		lnewlDetail.agentSign=lRdsDetail.agentSign;
		
		lnewlDetail.checkAmount=0;
		
		
		laryDetails.addItem(lnewlDetail);
	}
	dgDetail.dataProvider=laryDetails;
	dgDetail.selectedItem=lnewlDetail;
	
	fillDetailForm(lnewlDetail);
	
	var timer:Timer=new Timer(100, 1)
	timer.addEventListener(TimerEvent.TIMER, function(e:Event):void
	{
		dgDetail.scrollToIndex(dgDetail.selectedIndex);
		materialCode.txtContent.text="";
		materialCode.txtContent.setFocus();
	})
	timer.start();
}
