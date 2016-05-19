/**
 *		 期初结存录入模块
 *		 作者：吴小娟   2010.02.26
 *		 修改：吴小娟   2011.07.05
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
import cn.superion.materialDept.other.initRecord.view.WinInitRecordQuery;
import cn.superion.materialDept.util.DefaultPage;
import cn.superion.materialDept.util.MaterialDictShower;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialRdsDetailDept;
import cn.superion.vo.material.MaterialRdsMasterDept;

import flash.utils.Dictionary;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.controls.Text;
import mx.core.IFlexDisplayObject;
import mx.events.CloseEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import org.alivepdf.layout.Format;

import spark.events.TextOperationEvent;

registerClassAlias("cn.superion.materialDept.entity.MaterialRdsMasterDept", cn.superion.vo.material.MaterialRdsMasterDept);
registerClassAlias("cn.superion.materialDept.entity.MaterialRdsDetailDept", cn.superion.vo.material.MaterialRdsDetailDept);

public static const MENU_NO:String="0303";
//服务类
public static const DESTINATION:String="deptOtherReceiveImpl";

private var _winY:int=0;

private var _materialRdsMasterDept:MaterialRdsMasterDept=new MaterialRdsMasterDept();
private var _materialRdsDetailDept:MaterialRdsDetailDept=new MaterialRdsDetailDept();

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
	parentDocument.title="期初结存录入";
	_winY=this.parentApplication.screen.height - 345;
	personId.width=storageCode.width;
	initPanel();
	materialCode.setFocus();
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
	setReadOnly(true);
	//阻止表单输入
	preventDefaultForm();
}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.imageList1, toolBar.btAdd, toolBar.btModify, toolBar.btDelete, toolBar.btCancel, toolBar.btSave, toolBar.btVerify, toolBar.imageList2, toolBar.btAddRow, toolBar.btDelRow, toolBar.imageList3, toolBar.btQuery, toolBar.imageList5, toolBar.btFirstPage, toolBar.btPrePage, toolBar.btNextPage, toolBar.btLastPage, toolBar.imageList6, toolBar.btExit];
	var laryEnables:Array=[toolBar.btExit, toolBar.btQuery, toolBar.btAdd]
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 表头设置只读或读写状态
 */
private function setReadOnly(boolean:Boolean):void
{

	boolean=!boolean;
	storageCode.enabled=boolean;
	rdType.enabled=boolean;
	billNo.enabled=boolean;
	billDate.enabled=boolean;
	deptCode.enabled=boolean;

	personId.enabled=boolean;
	remark.enabled=boolean;
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

	materialCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
		{
			e.preventDefault();
		})
}

/**
 * 放大镜输入框键盘处理方法
 * */
protected function textInputIcon_keyUpHandler(event:KeyboardEvent, fctrNext:Object):void
{
	FormUtils.textInputIconKeyUpHandler(event, _materialRdsMasterDept, fctrNext);
}

/**
 * 清空表单
 */
public function clearForm(masterFlag:Boolean, detailFlag:Boolean):void
{
	if (masterFlag)
	{
		rdType.txtContent.text="";
		deptCode.txtContent.text="";
		billDate.selectedDate=new Date();
		billNo.text="";

		deptCode.txtContent.text="";
		personId.txtContent.text="";
		remark.text="";

		currentStockAmount.text="";
		maker.text='';
		verifier.text='';
		verifyDate.text='';
		gdRdsDetail.dataProvider=new ArrayCollection();
		_materialRdsMasterDept=new MaterialRdsMasterDept();
	}
	if (detailFlag)
	{
		materialCode.txtContent.text="";
		materialName.text="";
		materialSpec.text="";
		materialUnits.text="";
		amount.text="";
		batch.text="0";
		availDate.selectedDate=new Date();

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
	if (event.currentTarget == availDate)
	{
		materialCode.txtContent.text='';
	}
	if (event.currentTarget == amount && !_bathSign)
	{
		materialCode.txtContent.text='';
		materialCode.txtContent.setFocus();
		return;
	}
	FormUtils.toNextControl(event, fctrlNext);
}


/**
 * 部门档案
 */
protected function deptCode_queryIconClickHandler(event:Event):void
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
 * 人员档案
 */
protected function personId_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict(function(rev:Object):void
		{
			personId.txtContent.text=rev.name;

			_materialRdsMasterDept.personId=rev.personId;
		}, x, y);
}

/**
 * 调用入库类型字典
 */
protected function rdType_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showReceiveTypeDict(function(rev:Object):void
		{
			rdType.txtContent.text=rev.rdName;

			_materialRdsMasterDept.rdType=rev.rdCode;
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
	var laryDetails:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;

	for each(var fItem:Object in fItems){
		var lnewlDetail:MaterialRdsDetailDept=new MaterialRdsDetailDept();
		
		lnewlDetail.materialId=fItem.materialId;
		lnewlDetail.materialClass=fItem.materialClass;
		lnewlDetail.barCode=fItem.barCode;
		lnewlDetail.materialCode=fItem.materialCode;
		lnewlDetail.materialName=fItem.materialName;
		lnewlDetail.materialSpec=fItem.materialSpec;
		lnewlDetail.materialUnits=fItem.materialUnits;
		lnewlDetail.serialNo=0;
		lnewlDetail.availDate=new Date();
		
		lnewlDetail.amount=0;
		
		lnewlDetail.tradePrice=fItem.tradePrice;
		lnewlDetail.tradeMoney=fItem.tradePrice;
		
		lnewlDetail.retailPrice=fItem.retailPrice;
		lnewlDetail.retailMoney=fItem.retailPrice;
		lnewlDetail.batch='0'
		
		lnewlDetail.factoryCode=fItem.factoryCode;
		lnewlDetail.currentStockAmount=fItem.amount;
		
		lnewlDetail.outAmount=0;
		lnewlDetail.outSign='0';
		
		lnewlDetail.highValueSign=fItem.highValueSign;
		lnewlDetail.agentSign=fItem.agentSign;
		
		
		//是否批号管理
		_bathSign=fItem.bathSign;
		
		laryDetails.addItem(lnewlDetail);
	}
	gdRdsDetail.dataProvider=laryDetails;
	gdRdsDetail.selectedItem=lnewlDetail;

	fillDetailForm(lnewlDetail);

	var timer:Timer=new Timer(100, 1);
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
	materialCode.txtContent.text=fselDetailItem.materialCode;
	materialName.text=fselDetailItem.materialName;
	materialSpec.text=fselDetailItem.materialSpec;
	materialUnits.text=fselDetailItem.materialUnits;

	amount.text=fselDetailItem.amount + '';
	batch.text=fselDetailItem.batch;
	availDate.text=DateField.dateToString(fselDetailItem.availDate, 'YYYY-MM-DD');

	currentStockAmount.text=fselDetailItem.currentStockAmount + '';
}

/**
 * 数量进行改变事件
 */
private function amount_ChangeHandler(event:Event):void
{
	var lRdsDetail:MaterialRdsDetailDept=gdRdsDetail.selectedItem as MaterialRdsDetailDept;
	if (!lRdsDetail)
	{
		return;
	}

	lRdsDetail.amount=parseFloat(amount.text);
	lRdsDetail.amount=isNaN(lRdsDetail.amount) ? 1 : lRdsDetail.amount;

	lRdsDetail.tradeMoney=lRdsDetail.amount * lRdsDetail.tradePrice;

	lRdsDetail.retailMoney=lRdsDetail.amount * lRdsDetail.retailPrice;
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

/**
 * 打印
 * */
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
 * */
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
	var dataList:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	var rawList:ArrayCollection=gdRdsDetail.getRawDataProvider() as ArrayCollection;
	var lastItem:Object=rawList.getItemAt(rawList.length - 1);
	preparePrintData(dataList);
	var dict:Dictionary=new Dictionary();

	dict["主标题"]="期初结存录入";
	dict["单位"]=AppInfo.currentUserInfo.unitsName;
	dict["仓库"]=storageCode.text;
	dict["入库单号"]=_materialRdsMasterDept.billNo;
	dict["入库日期"]=DateUtil.dateToString(_materialRdsMasterDept.billDate, 'YYYY-MM-DD');
	dict["合计进价"]=lastItem.tradeMoney.toFixed(2);
	dict["表尾第二行"]=createPrintSecondBottomLine(lastItem);

	if (printSign == "1")
	{
		ReportPrinter.LoadAndPrint("report/materialDept/other/initRecord.xml", dataList, dict);
	}
	else
	{
		ReportViewer.Instance.Show("report/materialDept/other/initRecord.xml", dataList, dict);
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
 * */
protected function addClickHandler(event:Event):void
{
	//新增权限
	if (!checkUserRole('01'))
	{
		return;
	}

	//增加按钮
	toolBar.addToPreState();

	//显示输入明细区域
	bord.height=111;
	hiddenVGroup.includeInLayout=true;
	hiddenVGroup.visible=true;

	//设置可写
	setReadOnly(false);
	//清空当前表单
	clearForm(true, true);
	//表头赋值
	//授权仓库赋值
	var deptItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', AppInfo.currentUserInfo.deptCode);
	storageCode.text=deptItem == null ? "" : deptItem.deptName;
	rdType.txtContent.text="期初数据";
	_materialRdsMasterDept.rdType='103';
	_materialRdsMasterDept.currentStatus='0';

	//表尾赋值
	maker.text=AppInfo.currentUserInfo.userName;
	makeDate.text=DateUtil.dateToString(new Date(), "YYYY-MM-DD");
	//得到区域
	materialCode.txtContent.setFocus();
}

/**
 * 修改
 * */
protected function modifyClickHandler(event:Event):void
{
	//修改权限
	if (!checkUserRole('02'))
	{
		return;
	}
	//判断当前表格是否具有明细数据
	var laryDetails:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	if (!laryDetails)
	{
		return;
	}

	//当前状态显示的值
	if (_materialRdsMasterDept.currentStatus == "2")
	{
		Alert.show("该入库单已经审核，不能再修改");
		return;
	}
	if (_materialRdsMasterDept.currentStatus == "0")
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
	gdRdsDetail_itemClickHandler(null);
}

/**
 * 删除
 * */
protected function deleteClickHandler(event:Event):void
{
	//删除权限
	if (!checkUserRole('03'))
	{
		return;
	}

	if (_materialRdsMasterDept.autoId == "" || (_materialRdsMasterDept.autoId == null))
	{
		Alert.show("请先查询要删除的期初入库单！", "提示信息");
		return;
	}

	if (_materialRdsMasterDept.currentStatus == '1')
	{
		Alert.show("该期初入库单已审核！", "提示信息");
		return;
	}
	else if (_materialRdsMasterDept.currentStatus == '2')
	{
		Alert.show("该期初入库单已记账！", "提示信息");
		return;
	}

	Alert.show("您确定要删除当前记录？", "提示信息", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
		{
			if (e.detail == Alert.YES)
			{
				var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
					{
						Alert.show("删除期初入库单成功！", "提示信息");
						doInit();
						clearForm(true, true);
					});
				ro.deleteRds(_materialRdsMasterDept.autoId);
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
	if (!laryDetails)
	{
		Alert.show("期初结存单明细记录不能为空", "提示");
		return;
	}
	//填充主记录
	fillRdsMaster();
	//保存当前数据
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
		{
			if (rev && rev.data[0])
			{
				toolBar.saveToPreState();
				//
				copyFieldsToCurrentMaster(rev.data[0], _materialRdsMasterDept);
				//
				billNo.text=_materialRdsMasterDept.billNo;
				findRdsById(rev.data[0].autoId);
				doInit();
				Alert.show("期初结存单保存成功！", "提示信息");
				return;
			}
		});
	ro.saveInitialRds(_materialRdsMasterDept, laryDetails);
}

/**
 * 保存前验证主记录
 */
private function validateMaster():Boolean
{
	if (rdType.txtContent.text == "")
	{
		rdType.txtContent.setFocus();
		Alert.show("入库类型必填", "提示");
		return false;
	}
	return true;
}

/**
 * 填充主记录,作为参数
 * */
private function fillRdsMaster():void
{
	_materialRdsMasterDept.invoiceType="1";
	// 仓库
	var a:*=AppInfo.currentUserInfo.deptCode;
	_materialRdsMasterDept.storageCode=AppInfo.currentUserInfo.deptCode;

	// 入库单号
	_materialRdsMasterDept.billNo=billNo.text;
	// 入库日期
	_materialRdsMasterDept.billDate=billDate.selectedDate;
	// 备注
	_materialRdsMasterDept.remark=remark.text;
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
	//审核权限
	if (!checkUserRole('06'))
	{
		return;
	}

	//应为后台提供
	_materialRdsMasterDept.verifier=AppInfo.currentUserInfo.personId;
	_materialRdsMasterDept.verifyDate=new Date();

	if (_materialRdsMasterDept.currentStatus == "1")
	{
		Alert.show('该期初入库单已经审核', '提示信息');
		return;
	}

	Alert.show('您是否审核当前期初入库单？', '提示信息', Alert.YES | Alert.NO, null, function(e:*):void
		{
			if (e.detail == Alert.YES)
			{
				var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
					{
						//显示输入明细区域
						bord.height=70;
						hiddenVGroup.includeInLayout=false;
						hiddenVGroup.visible=false;
						//设置只读
						setReadOnly(true);
						//赋当前审核状态
						_materialRdsMasterDept.currentStatus='1';
						//表尾赋值
						verifier.text=AppInfo.currentUserInfo.userName;
						verifyDate.text=DateUtil.dateToString(new Date(), "YYYY-MM-DD");
						findRdsById(rev.data[0].autoId);
						Alert.show("期初入库单审核成功！", "提示信息");
					});
				ro.verifyRds(_materialRdsMasterDept.autoId);
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

	batch.text="0";
	availDate.text="";

	materialCode_queryIconClickHandler(null);
}

/**
 * 删行
 * */
protected function delRowClickHandler(event:Event):void
{
	var laryDetails:ArrayCollection=gdRdsDetail.getRawDataProvider() as ArrayCollection;

	var lintMaxIndex:int=laryDetails.length;
	var lintSelIndex:int=gdRdsDetail.selectedIndex;
	if (lintSelIndex < 0 || lintSelIndex > lintMaxIndex - 1)
	{
		return;
	}

	var lRdsDetail:MaterialRdsDetailDept=gdRdsDetail.selectedItem as MaterialRdsDetailDept;
	if (!lRdsDetail)
	{
		Alert.show("请您选择要删除的记录！", "提示");
		return;
	}

	var lselIndex:int=gdRdsDetail.selectedIndex;
	Alert.show("您是否删除" + lRdsDetail.materialName + "吗？", "提示", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
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
			clearForm(false, true);
			if (lintSelIndex == 0)
			{
				lintSelIndex=1;
			}
			gdRdsDetail.selectedIndex=lintSelIndex - 1;

			Alert.show("删除明细记录成功!", "提示");
			return;

		})
}

/**
 * 查询
 * */
protected function queryClickHandler(event:Event):void
{
	var win:WinInitRecordQuery=PopUpManager.createPopUp(this, WinInitRecordQuery, true) as WinInitRecordQuery;
	win.parentWin=this;
	FormUtils.centerWin(win);
}

/**
 * 首页
 * */
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
 * */
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
 * */
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
 * */
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
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
		{

			if (rev.data && rev.data.length > 0 && rev.data[0] != null && rev.data[1] != null)
			{
				_materialRdsMasterDept=new MaterialRdsMasterDept();
				_materialRdsMasterDept=rev.data[0] as MaterialRdsMasterDept;
				var details:ArrayCollection=rev.data[1] as ArrayCollection;

				//主记录赋值
				fillMaster(_materialRdsMasterDept);
				stateButton(rev.data[0].currentStatus);
				//明细赋值
				gdRdsDetail.dataProvider=details;
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

	var deptItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', materialRdsMaster.storageCode);
	storageCode.text=deptItem == null ? "" : deptItem.deptName;
	FormUtils.fillTextByDict(rdType, materialRdsMaster.rdType, 'receviceType');
	FormUtils.fillTextByDict(deptCode, materialRdsMaster.deptCode, 'dept');
	FormUtils.fillTextByDict(personId, materialRdsMaster.personId, 'personId');
	FormUtils.fillTextByDict(maker, materialRdsMaster.maker, 'personId');
	FormUtils.fillTextByDict(verifier, materialRdsMaster.verifier, 'personId');
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
 * 品名规格，用以扩展打印需要的字段
 */
private function nameSpecLBF(item:Object, column:DataGridColumn):String
{
	var nameSpec:String=item.materialName + (item.materialSpec == null ? "" : item.materialSpec);
	item.nameSpec=nameSpec;
	return "";
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
 * */
protected function exitClickHandler(event:Event):void
{

	PopUpManager.removePopUp(this.parentDocument as IFlexDisplayObject);

	DefaultPage.gotoDefaultPage();
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