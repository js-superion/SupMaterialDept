import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.materialDept.deliver.deliverValue.view.WinDeliverValueQuery;
import cn.superion.materialDept.util.DefaultPage;
import cn.superion.materialDept.util.MaterialDictShower;
import cn.superion.materialDept.util.ToolBar;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialPatsDetail;
import cn.superion.vo.material.MaterialPatsMaster;

import flash.events.KeyboardEvent;
import flash.ui.Keyboard;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DataGrid;
import mx.controls.DateField;
import mx.controls.dataGridClasses.DataGridColumn;
import mx.core.IFlexDisplayObject;
import mx.events.CloseEvent;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import spark.events.TextOperationEvent;


private static const MENU_NO:String="0207";
public var DESTANATION:String="deptDeliverValueImpl";

//主记录
public var _materialPatsMaster:MaterialPatsMaster=new MaterialPatsMaster();

//查询主记录ID列表
public var arrayAutoId:Array=new Array();
//当前页，翻页用
public var currentPage:int=0;

public var fstrRefundSign:String='';

private var refundDays:Number=0;



/**
 * 初始化当前窗口
 * */
public function doInit():void
{
	toolBar.btAbandon.label="退费";
	toolBar.btVerify.label="收费";
	parentDocument.title="高值耗材收费";
	
	//重新注册客户端对应的服务端类
	registerClassAlias("cn.superion.materialDept.entity.MaterialPatsMaster", MaterialPatsMaster);
	registerClassAlias("cn.superion.materialDept.entity.MaterialPatsDetail", MaterialPatsDetail);
	//放大镜不可手动输入
	preventDefaultForm();
	initPanel();
	initToolBar();
	MaterialDictShower.getAdvanceDictList();
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
	var laryDisplays:Array=[toolBar.btPrint, toolBar.imageList4, toolBar.btExp, toolBar.btAddRow, toolBar.btDelRow, toolBar.imageList1,toolBar.btAbandon, toolBar.btAdd, toolBar.btModify, toolBar.btDelete, toolBar.btCancel, toolBar.btSave, toolBar.btVerify, toolBar.imageList2, toolBar.btQuery, toolBar.imageList5, toolBar.btFirstPage, toolBar.btPrePage, toolBar.btNextPage, toolBar.btLastPage, toolBar.imageList6, toolBar.btExit];
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
	FormUtils.clearForm(patsDetail);
}

/**
 * 清空主记录
 */
public function clearMaster():void
{
	FormUtils.clearForm(patsMaster);
	_materialPatsMaster=new MaterialPatsMaster();
	dataGridDetail.dataProvider=null;
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
 * 数量key事件
 */
protected function amountKey(e:KeyboardEvent, fcontrolNext:*):void
{
	if (e.keyCode == Keyboard.ENTER)
	{
		if (!dataGridDetail.selectedItem)
		{
			return;
		}
		if ((dataGridDetail.selectedItem.amount) <= 0)
		{
			return;
		}
		fcontrolNext.setFocus();
	}
}


/**
 * 数量change事件
 */
protected function applyAmount_changeHandler(event:TextOperationEvent):void
{
	// TODO Auto-generated method stub
	if (!dataGridDetail.selectedItem)
	{
		return;
	}
	var amout:int;
	var ro:RemoteObject=RemoteUtil.getRemoteObject("deptCommMaterialServiceImpl", function(rev:Object):void
	{
		amout=rev.data[0].totalCurrentStockAmount;
		if (((Number)(amount.text)) > amout)
		{
			Alert.show("输入数量已超出、现存量！", "提示");
			return;
		}
		dataGridDetail.selectedItem.amount=((Number)(amount.text));
		dataGridDetail.selectedItem.retailMoney=(((Number)(amount.text)) * ((Number)(dataGridDetail.selectedItem.retailPrice)));
		dataGridDetail.invalidateList();
	});
	ro.findCurrentStockById(dataGridDetail.selectedItem.materialId);
	
}


protected function barCode_enterHandler(event:KeyboardEvent):void
{ 
	if(event.keyCode!=13) return;
	
	if(!_materialPatsMaster || !_materialPatsMaster.patientId){
		Alert.show('请先录入病人信息','提示');
		return;
	}
	var _barCode:String=barCode.text;
	if(!_barCode || _barCode.length<10) return;
	
	var timer:Timer=new Timer(1000, 1)
	timer.addEventListener(TimerEvent.TIMER, function(e:Event):void
	{
		var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION,function(rev:Object):void
		{
			if(rev.data && rev.data[0])
			{
				fillIntoGrid(rev.data[0]);
			}
		});
		ro.findMaterialDetailByBarCode(barCode.text);
		timer.stop();
	})
	timer.start();
	
}

/**
 * 自动完成表格回调
 * */
private function fillIntoGrid(fItem:Object):void
{
	var materialPatsDetail:MaterialPatsDetail=new MaterialPatsDetail();
	var laryDetails:ArrayCollection=dataGridDetail.dataProvider as ArrayCollection;
	for each(var obj:Object in laryDetails)
	{
		if(obj.barCode==fItem.barCode)
		{
			Alert.show('该条形码在明细中已存在','提示');
			dataGridDetail.selectedIndex=laryDetails.getItemIndex(obj);
			return;
		}
	}
	materialPatsDetail=fillDetailForm(fItem);
	laryDetails.addItem(materialPatsDetail);
	for each(var item:Object in laryDetails)
	{
		item.isSelected=true;
	}
	dataGridDetail.dataProvider=laryDetails;
	dataGridDetail.selectedIndex=laryDetails.length - 1;
	barCode.text='';
}

/**
 * 明细表单赋值
 */
private function fillDetailForm(faryItems:Object):MaterialPatsDetail
{
	var materialPatsDetail:MaterialPatsDetail=new MaterialPatsDetail();
	materialPatsDetail.barCode=faryItems.barCode;
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
	//进价
	materialPatsDetail.tradePrice=faryItems.tradePrice;
	//进价金额
	materialPatsDetail.tradeMoney=faryItems.amount * faryItems.tradePrice;
	//批发价
	materialPatsDetail.wholeSalePrice=faryItems.wholeSalePrice;
	//批发价金额
	materialPatsDetail.wholeSaleMoney=faryItems.amount * faryItems.wholeSalePrice;
	
	//售价金额
	materialPatsDetail.retailMoney=faryItems.amount * faryItems.retailPrice;
	//售价
	materialPatsDetail.retailPrice=faryItems.retailPrice;
	//生产厂家
	materialPatsDetail.factoryCode=faryItems.factoryCode;

	//生产日期
	materialPatsDetail.madeDate=faryItems.madeDate;
	//批号
	materialPatsDetail.batch=faryItems.batch;
	//有效日期
	materialPatsDetail.availDate=faryItems.availDate;
	//初始化申请数量
	materialPatsDetail.applyAmount=1;
	//退费标准
	materialPatsDetail.refundSign="";
	//领用数量
	materialPatsDetail.amount=1;
	//是否单独计价
	materialPatsDetail.chargeSign=faryItems.chargeSign;
	//会计科目分类
	materialPatsDetail.classOnAccount=faryItems.classOnAccount;
	//产品码
	materialPatsDetail.materialBarCode=faryItems.materialBarCode;
	//是否赠送
	materialPatsDetail.isGive=faryItems.isGive;
	//供应商
	materialPatsDetail.supplyDeptCode=faryItems.supplyDeptCode;
	
	//该病人使用的耗材是否来自本院的入库
	if(faryItems.unitsCode!=_materialPatsMaster.unitsCode)
	{
		materialPatsDetail.currentReceiveSign='0';
	}
	else
	{
		materialPatsDetail.currentReceiveSign='1';
	}
	
	FormUtils.fillFormByItem(patsDetail, materialPatsDetail);
	
	return materialPatsDetail;
}

/**
 * 给主记录赋值
 */
private function fillRdsMaster(rev:Object):void
{
	_materialPatsMaster.billType="2";
	_materialPatsMaster.patientType="2";
	_materialPatsMaster.patientId=rev.patientId;
	_materialPatsMaster.inpNo=rev.inpNo;
	_materialPatsMaster.clinicDiag=rev.diagenoseCode;
	_materialPatsMaster.clinicDiagName=rev.diagenoseName;
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
	_materialPatsMaster.applyDoctor=rev.doctor;
	_materialPatsMaster.applyDate=new Date();
	_materialPatsMaster.currentStatus="0";
	_materialPatsMaster.unitsCode=rev.unitsCode;
}

/**
 * 所有Change事件
 */
protected function evaluate_changeHandler(event:Event):void
{
	if (!dataGridDetail.selectedItem)
	{
		return;
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
	dict["主标题"]="高值耗材收费";
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
		ReportPrinter.LoadAndPrint("report/materialDept/deliver/deliverValue/deliverValue.xml", _dataList, dict);
	if (printSign == '0')
		ReportViewer.Instance.Show("report/materialDept/deliver/deliverValue/deliverValue.xml", _dataList, dict);
	
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
			ro.deletePatsFee(_materialPatsMaster.autoId);
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
	if (!validateMaster())
	{
		return;
	}
	var arrayList:ArrayCollection=dataGridDetail.dataProvider as ArrayCollection;
	var dataList:ArrayCollection=new ArrayCollection();
	for each(var item:Object in arrayList)
	{
		if(item.isSelected)
		{
			if(item.amount>0)
			{
				dataList.addItem(item);
			}
		}
	}
	if (dataList.length <= 0)
	{
		Alert.show("请选择需要保存的明细", "提示");
		return;
	}
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		initToolBar();
		setReadOnly(false);
		fstrRefundSign="";
		findRdsById(rev.data[0].autoId);
		
		Alert.show("保存成功", "提示");
	});
	ro.savePatsFee(_materialPatsMaster, dataList);
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
	toolBar.btAbandon.enabled=!state;
	toolBar.btPrint.enabled=true;
	toolBar.btExp.enabled=true;
}

/**
 * 保存前验证主记录
 */
private function validateMaster():Boolean
{
	var state:Boolean=true;
	;
	if (patientName.text == "" || patientName.text == null)
	{
		Alert.show("病人姓名不能为空！", "提示", Alert.OK, null, function(_rev:CloseEvent):void
		{
			inpNo.setFocus();
		});
		return state=false;
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
 * 审核按钮
 */
protected function toolBar_verifyClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	//新增权限
	if (!checkUserRole('06'))
	{
		return;
	}
	Alert.show('确定要收费吗？', '提示', Alert.YES | Alert.NO, null, function(e:*):void
	{
		if (e.detail == Alert.YES)
		{
			var _ary:ArrayCollection=dataGridDetail.dataProvider as ArrayCollection;
			var details:Array=new Array();
			
			for (var i:int=0; i < _ary.length; i++)
			{
				if(_ary[i].isSelected)
				{
					details.push(_ary[i].autoId);
				}
				
			}
			if(details.length==0)
			{
				Alert.show('请选择需要收费的物资','提示');
				return
			}
			var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
			{
				Alert.show("收费成功", "提示");
				fstrRefundSign="0";
				findRdsById(_materialPatsMaster.autoId);
			});
			ro.verify(_materialPatsMaster.autoId,details);
		}
	})
}
/**
 * 退费按钮
 */ 
protected function toolBar_abandonClickHandler(event:Event):void
{
	Alert.show('是否退费?', '提示', Alert.YES | Alert.NO, null, function(e:*):void
	{
		if (e.detail == Alert.YES)
		{
			var _ary:ArrayCollection=dataGridDetail.dataProvider as ArrayCollection;
			var details:Array=new Array();
			
			for (var i:int=0; i < _ary.length; i++)
			{
				if(_ary[i].isSelected)  
				{
					details.push(_ary[i].autoId);
				}
				
			}
			if (details.length <= 0)
			{
				Alert.show("请选择要退费的物品", "提示");
				return;
			}
			var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
			{
				Alert.show("退费成功", "提示");
				if(rev.data && rev.data[0])
				{
					findRdsById(rev.data[0]);
				}
				else
				{
					clearMaster();
					clearDetail();
				}
			});
			ro.refundFee(_materialPatsMaster.autoId, details);
		}
	})
}


/**
 * 增行
 */
protected function addRowClickHandler(event:Event):void
{
	FormUtils.clearForm(patsDetail);
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
		dataGridDetail.invalidateList();
		dataGridDetail.selectedIndex=dataGridDetail.dataProvider.length - 1;
		dataGridDetail.selectedIndex=i == 0 ? 0 : (i - 1);
		FormUtils.fillFormByItem(patsDetail, dataGridDetail.selectedItem);
	})
}

/**
 * 查询
 */
protected function queryClickHandler(event:Event):void
{
	var queryWin:WinDeliverValueQuery=PopUpManager.createPopUp(this, WinDeliverValueQuery, true) as WinDeliverValueQuery;
	queryWin.data={parentWin: this};
	FormUtils.centerWin(queryWin);
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
		if (rev.data==null || rev.data.length <= 0 || rev.data[1]==null)
		{
			return;
		}
		_materialPatsMaster=rev.data[0];
		masterEvaluate(rev);
		for(var i:int=0;i<rev.data[1].length;i++)
		{
			rev.data[1][i].isSelected=true;
//			for each(var item:Object in rev.data[1][i])
//			{
//				item.isSelected=true;
//			}
		}
		
		dataGridDetail.dataProvider=rev.data[1];
		
		var refundSign:String=rev.data[1][0].refundSign=='0' ? '1' : '0'
		stateButton(refundSign);
		prepaymentsLeft.text=rev.data[2];
	});
	ro.findPatsFeeDetailById(fstrAutoId,fstrRefundSign);
} 

/** 
 * 按照住院号 查病人详细信息
 */
protected function inpNo_keyUpHandler(event:KeyboardEvent):void
{
	// TODO Auto-generated method stub
	if (event.keyCode == Keyboard.ENTER)
	{
		var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
		{
			var _inpNo:String=inpNo.text;
			if (rev.data[0] == null)
			{
				//清空当前表单
				clearForm(true, true);
				Alert.show('病人[标识号：'+_inpNo+']不存在','提示');
				return;
			}
			fillRdsMaster(rev.data[0]);
			masterEvaluate(rev);
			barCode.setFocus();
			return;
			
		});
		ro.findPatsVisitByInpNo(inpNo.text);
	}
}

/**
 * 给主记录赋值
 */
protected function masterEvaluate(rev:Object):void
{
	FormUtils.fillFormByItem(patsMaster, rev.data[0]);
	diagnoseName.text=rev.data[0].diagnoseName == null ? rev.data[0].clinicDiagName : rev.data[0].diagnoseName;
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

private function labFun(item:Object,column:DataGridColumn):String
{
	if(column.headerText=='生产厂家')
	{
		var factoryObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict,'provider',item.factoryCode);
		item.factoryName=factoryObj==null ? "" : factoryObj.providerName;
		return item.factoryName;
	}
	return "";
}