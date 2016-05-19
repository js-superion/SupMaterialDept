import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.config.SysUser;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.DateUtil;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialDept.util.DefaultPage;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.center.material.CdMaterialDict;
import cn.superion.vo.cssd.CssdDeliverMaster;
import cn.superion.vo.cssd.CssdPackageDict;
import cn.superion.vo.cssd.CssdProvideDetail;
import cn.superion.vo.cssd.CssdRetrieveDetail;
import cn.superion.vo.cssd.CssdRetrieveMaster;
import cn.superion.vo.cssd.CssdStockMaster;
import cn.superion.vo.cssd.DeptPackageMaterial;

import com.adobe.utils.StringUtil;

import mx.collections.ArrayCollection;
import mx.collections.ListCollectionView;
import mx.controls.Alert;
import mx.controls.Button;
import mx.controls.DataGrid;
import mx.core.FlexGlobals;
import mx.core.IFlexDisplayObject;
import mx.core.UIComponent;
import mx.events.CloseEvent;
import mx.events.CollectionEvent;
import mx.events.DataGridEvent;
import mx.events.FlexEvent;
import mx.events.ListEvent;
import mx.events.ScrollEvent;
import mx.managers.PopUpManager;
import mx.managers.ToolTipManager;
import mx.messaging.Producer;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;
import mx.validators.NumberValidator;
import mx.validators.StringValidator;
import mx.validators.Validator;

import spark.components.SkinnableContainer;
import spark.events.TextOperationEvent;
import cn.superion.materialDept.receive.receiveBag.view.ReceiveBagQueryCon;
import cn.superion.vo.cssd.CssdProvideMaster;

import mx.events.CalendarLayoutChangeEvent;
private var autoIds:String="";
public var cssdProvideMaster:CssdProvideMaster=new CssdProvideMaster();
public var btPrint:Boolean=false; //打印
public var btExp:Boolean=false; //输出
public var btAdd:Boolean=false; //增加
public var btModify:Boolean=false; //修改
public var btDelete:Boolean=false; //删除
public var btSave:Boolean=false; //保存
public var btCancel:Boolean=false; //放弃
public var btVerify:Boolean=false; //审核
public var btAddRow:Boolean=false; //增行
public var btDelRow:Boolean=false; //删行
public var btQuery:Boolean=false; //查询
public var btFirstPage:Boolean=false; //首张
public var btPrePage:Boolean=false; //上一张
public var btNextPage:Boolean=false; //下一张
public var btLastPage:Boolean=false; //末张
public var btExit:Boolean=false; //退出
[Bindable]
private var _tempSalerCode:String;
public var _tempDeptCode:String;
private var _tempPersonId:String=AppInfo.currentUserInfo.personId;
private var _tempMaterialId:String;
private var _tempPackageId:String;
private var _btModifyBeClicked:Boolean=false;//判断增加还是修改
[Bindable]
public var gridDetailEnabled:Boolean=true;
public var queryStockSign:Boolean=false; //是否执行查找库存方法
private const MENU_NO:String="0101";
private const PARA_CODE:String="0201";
public static const DESTANATION:String='cssdApplyImpl';
private var _retrieveMaster:CssdRetrieveMaster=new CssdRetrieveMaster();
[Bindable]
public var _dataProvider:ArrayCollection=null;

private var autoId:String=null;
/* 	//记录当前输入的对象，当用户下录下一条时，部分值默认从该对象中取
private var _tempProviderMaster:MaterialProvideMaster = null; */
private var _vAll:Array=[];
public var disAry:Array=[]

	
/**
 * 初始化
 * */
protected function doInit():void
{
	addPanel.height=0;
	cssdProvideMaster.invoiceType="1";
	personId.txtContent.editable=false;
	deptCode.txtContent.editable=false;
	
	initToolBar();
	initPanel();
}
/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	parentDocument.title="科室用包申请";
	//初始按钮组
	disAry =[btToolBar.btPrint, btToolBar.btExp, btToolBar.imageList1,btToolBar.btAbandon,
		btToolBar.btAdd, btToolBar.btModify, btToolBar.btDelete, btToolBar.btCancel, 
		btToolBar.btSave, btToolBar.btVerify, btToolBar.imageList2,btToolBar.btAddRow,
		btToolBar.btDelRow, btToolBar.imageList3, btToolBar.btQuery, btToolBar.imageList5, 
		btToolBar.btFirstPage, btToolBar.btPrePage, btToolBar.btNextPage, btToolBar.btLastPage,
		btToolBar.imageList6, btToolBar.btExit];
	var enAry:Array=[btToolBar.btAuto,btToolBar.btAdd, btToolBar.btQuery, btToolBar.btExit];
	MainToolBar.showSpecialBtn(btToolBar, disAry, enAry, true);
	//配置翻页回调
	btToolBar.callback=setAutoId;
}

/**
 * 初始化面板
 * */
private function initPanel():void
{
	//
	MainToolBar.setToolKitEnable(vgTop, false);
//	MainToolBar.setToolKitEnable(hgTwo, false);
	cssdProvideMaster.deptCode=AppInfo.currentUserInfo.deptCode;
	deptCode.txtContent.text=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', cssdProvideMaster.deptCode) == null ? "" : ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', cssdProvideMaster.deptCode).deptName;
	cssdProvideMaster.personId=AppInfo.currentUserInfo.personId;
	personId.txtContent.text=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', AppInfo.currentUserInfo.personId) == null ? "" : ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', AppInfo.currentUserInfo.personId).personIdName;
//	FormUtils.setFormItemEditable(hgBottom, false); 
	//隐藏明细查询组件
	rdo.selection = AppInfo.currentUserInfo.inputCode == "PHO_INPUT"?
	rdoPhoCode:rdoFiveCode;
}

/**
 * 申请数量
 */
protected function amount_changeHandler(event:TextOperationEvent):void
{
	// TODO Auto-generated method stub amount
	if(gridDetail.selectedItem)
	{
		if(redType.selected!=true)
		{
			gridDetail.selectedItem.amount=Number(amount.text);
			
		}
		else
		{
			if(isNaN(Number(amount.text))){
				amount.text = "1";
			}
			if(Number((amount.text)) < 0){
				amount.text = (Number(amount.text)*1).toString();
			}else{
				amount.text = (Number(amount.text)*-1).toString();
			}
			amount.selectRange(amount.text.length,amount.text.length+1);
		}
		
		gridDetail.invalidateList();
	}
}
/**
 *备注change事件
 */
protected function remark_changeHandler(event:TextOperationEvent):void
{
	// TODO Auto-generated method stub
	cssdProvideMaster.remark=remark.text;
	gridDetail.invalidateList();
}
/**
 * 明细备注change事件
 */
protected function detailRemark_changeHandler(event:TextOperationEvent):void
{
	// TODO Auto-generated method stub
	if(gridDetail.selectedItem)
	{
		gridDetail.selectedItem.detailRemark=detailRemark.text;
		gridDetail.invalidateList();
	}
}
/**
 * 单据change事件
 */
protected function billNo_changeHandler(event:TextOperationEvent):void
{
	// TODO Auto-generated method stub.
	cssdProvideMaster.billNo=billNo.text;
}
/**
 * 单据日期change事件
 */ 
protected function billDate_changeHandler(event:CalendarLayoutChangeEvent):void
{
	// TODO Auto-generated method stub
	cssdProvideMaster.billDate=billDate.selectedDate;
}
/**
 *	放弃按钮 
 */
protected function btToolBar_cancelClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	if(autoIds!=null)
	{
		MainToolBar.setToolKitEnable(vgTop, false);
		showButtonState();
		addPanel.height=0;
		setAutoId(autoIds);
	}
	
	clearMe();
}
/**
 * 记录按钮状态
 */
protected function noteButtonState():void
{
	btPrint=btToolBar.btPrint.enabled; //打印
	btExp=btToolBar.btExp.enabled; //输出
	btAdd=btToolBar.btAdd.enabled; //增加
	btModify=btToolBar.btModify.enabled; //修改
	btDelete=btToolBar.btDelete.enabled; //删除
	btSave=btToolBar.btSave.enabled; //保存
	btCancel=btToolBar.btCancel.enabled; //放弃
	btVerify=btToolBar.btVerify.enabled; //审核
	btAddRow=btToolBar.btAddRow.enabled; //增行
	btDelRow=btToolBar.btDelRow.enabled; //删行
	btQuery=btToolBar.btQuery.enabled; //查询
	btFirstPage=btToolBar.btFirstPage.enabled; //首张
	btPrePage=btToolBar.btPrePage.enabled; //上一张
	btNextPage=btToolBar.btNextPage.enabled; //下一张
	btLastPage=btToolBar.btLastPage.enabled; //末张
	btExit=btToolBar.btExit.enabled; //退出
}
/**
 * 显示按钮状态
 */ 
protected function showButtonState():void
{
	btToolBar.btPrint.enabled=btPrint; //打印
	btToolBar.btExp.enabled=btExp; //输出
	btToolBar.btAdd.enabled=btAdd; //增加
	btToolBar.btModify.enabled=btModify; //修改
	btToolBar.btDelete.enabled=btDelete; //删除
	btToolBar.btSave.enabled=btSave; //保存
	btToolBar.btCancel.enabled=btCancel; //放弃
	btToolBar.btVerify.enabled=btVerify; //审核
	btToolBar.btAddRow.enabled=btAddRow; //增行
	btToolBar.btDelRow.enabled=btDelRow; //删行
	btToolBar.btQuery.enabled=btQuery; //查询
	btToolBar.btFirstPage.enabled=btFirstPage; //首张
	btToolBar.btPrePage.enabled=btPrePage; //上一张
	btToolBar.btNextPage.enabled=btNextPage; //下一张
	btToolBar.btLastPage.enabled=btLastPage; //末张
	btToolBar.btExit.enabled=btExit; //退出
}
/**
 * 查询按钮
 */ 
protected function btToolBar_queryClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	var win:ReceiveBagQueryCon=ReceiveBagQueryCon(PopUpManager.createPopUp(this, ReceiveBagQueryCon, true));
	win.data={parentWin: this};
	PopUpManager.centerPopUp(win);
}
//查找结果赋值
public function setAll(dry:ArrayCollection):void
{
	
	btToolBar.arc=dry;
}
/**
 * 蓝字click事件
 */ 
protected function blueType_clickHandler(event:MouseEvent):void
{
	// TODO Auto-generated method stub
	cssdProvideMaster.invoiceType="1";
	blueType.selected=true;
	redType.selected=false;
	gridDetail.dataProvider=null;
	
}
/**
 * 红字click事件
 */ 
protected function redType_clickHandler(event:MouseEvent):void
{
	// TODO Auto-generated method stub
	cssdProvideMaster.invoiceType="2";
	blueType.selected=false;
	redType.selected=true;
	gridDetail.dataProvider=null;
}
/**
 * 删除按钮
 */ 
protected function btToolBar_deleteClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		btToolBar.deleteSuccess=true;
		Alert.show("删除成功！","提示");
	});
	ro.deleteApply(cssdProvideMaster.autoId);
}
/**
 * 增行
 */ 
protected function btToolBar_addRowClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	gridDetail.selectedIndex=-1;
	phoInputCode.setFocus();
}
/**
 * 删行
 */ 
protected function btToolBar_delRowClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	var arrayList:ArrayCollection=gridDetail.dataProvider as ArrayCollection;
	
	
	if (!gridDetail.selectedItem)
	{
		Alert.show('请选中要删除的一行数据', '提示信息');
		return;
	}
	var _gd:ArrayCollection=gridDetail.dataProvider as ArrayCollection;
	var _index:int=_gd.getItemIndex(gridDetail.selectedItem);
	_gd.removeItemAt(_index);
	
	gridDetail.dataProvider=_gd;
	gridDetail.invalidateList();
	//清空表头隐藏输入项
	clearDet();
	if (gridDetail.dataProvider.length > 0)
	{
		gridDetail.selectedIndex=gridDetail.dataProvider.length - 1;
		phoInputCode.setFocus();
		return;
	}
	//清空表头隐藏输入项
	clearDet();
	phoInputCode.setFocus();
	btToolBar.btDelRow.enabled=false;
}
/**
 * 修改按钮
 */ 
protected function btToolBar_modifyClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	addPanel.height=32;
	phoInputCode.setFocus();
	//记录当前所有按钮状态
	noteButtonState();
	MainToolBar.setToolKitEnable(vgTop, true);
	//让按钮灰化、亮化
	var enAry:Array=[btToolBar.btSave, btToolBar.btCancel, btToolBar.btAddRow, btToolBar.btDelRow, btToolBar.btExit];
	MainToolBar.showSpecialBtn(btToolBar, disAry, enAry, true);
	gridDetail.selectedIndex=0;
}
/**
 * 保存
 * */
protected function saveClickHandler(event:Event):void
{
	var o:Object=cssdProvideMaster;
	if(cssdProvideMaster.personId==null||cssdProvideMaster.personId==""||cssdProvideMaster.deptCode==null||cssdProvideMaster.deptCode=="")
	{
		Alert.show("申请科室、人员不能为空！","提示");
		return;
	}
	if(gridDetail.dataProvider<=0)
	{
		Alert.show("明细不能为空！","提示", Alert.YES , null, function(e:CloseEvent):void
		{
			if (e.detail == Alert.YES)
			{
				phoInputCode.setFocus();
				return;
			}
		});
		return;
	}
	for(var i:int;i<gridDetail.dataProvider.length;i++)
	{
		if(gridDetail.dataProvider[i].amount==0)
		{
			Alert.show("光标所在物品数量不能<=0！", "提示信息", Alert.YES , null, function(e:CloseEvent):void
			{
				if (e.detail == Alert.YES)
				{
					amount.setFocus();
					gridDetail.selectedIndex=i;
					return;
				}
			});
			return;
		}
	}
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		if(rev.data[0]!=null&&rev.data[1].length>0)
		{
			Alert.show("保存成功！","提示");
			//保存成功灰化的按钮
			btToolBar.btSave.enabled=false;
			btToolBar.btCancel.enabled=false;
			btToolBar.btAddRow.enabled=false;
			btToolBar.btDelRow.enabled=false;
			//保存成功亮化的按钮
			btToolBar.btQuery.enabled=true;
			btToolBar.btAdd.enabled=true;
			btToolBar.btPrint.enabled=true;
			btToolBar.btExp.enabled=true;
			var aryd:Array=new Array(rev.data[0].autoId);
			btToolBar.arc=new ArrayCollection(aryd);
			addPanel.height=0;
			MainToolBar.setToolKitEnable(vgTop, false);
			setAutoId(rev.data[0].autoId);
		}
		else
		{
			//显示按钮
			showButtonState();
			clearMe();
		}
		
	});
	ro.saveApply(cssdProvideMaster,gridDetail.dataProvider);
	btToolBar.btSave.enabled=false;
}

/**
 * 按照ID查找对应的信息
 */ 
public function setAutoId(fstrAutoId:String):void
{
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		if(rev.data[0]==null&&rev.data[1].length<=0)
		{
			clearMe();
			return;
		}
		FormUtils.fillFormByItem(hgBottom, rev.data[0]);
		getcssProvideMaster(rev.data[0]);
		btToolBar.verifyEnabled = rev.data[0].currentStatus == "0"?true:false;
		btToolBar.abandonEnabled = rev.data[0].currentStatus == "1"?true:false;
		gridDetail.dataProvider=rev.data[1]
		maker.text=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId',  maker.text) == null ? "" : ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', maker.text).personIdName;
		verifier.text=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId',  verifier.text) == null ? "" : ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', verifier.text).personIdName;	
	});
	ro.findApplyDetailById(fstrAutoId);	
}
/**
 * 保存所有autoId
 */ 
public function patsMasterId(dry:ArrayCollection):void
{
	if (dry == null || dry.length == 0)
	{
		Alert.show("没有对应的数据!", "提示");
		clearMe();
		//初始按钮组
		var enAry:Array=[btToolBar.btAuto,btToolBar.btAdd, btToolBar.btQuery, btToolBar.btExit];
		MainToolBar.showSpecialBtn(btToolBar, disAry, enAry, true);
		return;
	}
	btToolBar.arc=dry;
	setAutoId(dry[0]);
}
/**
 * 主记录赋值
 */
public function getcssProvideMaster(cpm:CssdProvideMaster):void
{
	cssdProvideMaster=cpm;
	if(cssdProvideMaster.invoiceType=="1")
	{
		blueType.selected=true;
		redType.selected=false;
	}
	else
	{
		blueType.selected=false;
		redType.selected=true;
	}
	autoIds=cpm.autoId;
	billNo.text=cpm.billNo;
	billDate.selectedDate=cpm.billDate;
	remark.text=cpm.remark;
	personId.txtContent.text=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', cssdProvideMaster.personId) == null ? "" : ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', cssdProvideMaster.personId).personIdName;
	deptCode.txtContent.text=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', cssdProvideMaster.deptCode) == null ? "" : ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', cssdProvideMaster.deptCode).deptName;
}
/**
 * 审核按钮
 */ 
protected function btToolBar_verifyClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		btToolBar.verifyEnabled = rev.data[0].currentStatus == "0"?true:false;
		setAutoId(rev.data[0].autoId);
		Alert.show("审核成功！","提示");
	});
	ro.verifyApply(cssdProvideMaster.autoId);
}

/**
 * 弃审
 * */
protected function btToolBar_abandonClickHandler(event:Event):void
{
	
	btToolBar.btAbandon.enabled = false;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		btToolBar.verifyEnabled = rev.data[0].currentStatus == "0"?true:false;
		btToolBar.btAbandon.enabled = rev.data[0].currentStatus == "1"?true:false;
		setAutoId(rev.data[0].autoId);
		Alert.show("弃审成功！","提示");
	});
	ro.cancelVerifyApply(cssdProvideMaster.autoId);
	
}
/**
 * 退出按钮
 */ 
protected function btToolBar_exitClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	if (this.parentDocument is WinModual)
	{
		PopUpManager.removePopUp(this.parentDocument as IFlexDisplayObject);
		return;
	}
	DefaultPage.gotoDefaultPage();
}
/**
 * 回车事件
 */
protected function storageCode_keyUpHandler(event:KeyboardEvent, fcontrolNext:*):void
{
	if (event.keyCode == Keyboard.ENTER)
	{
		fcontrolNext.setFocus();
	}
}
/**
 * 备注按钮
 */ 
protected function detailRemark_keyDownHandler(event:KeyboardEvent):void
{
	// TODO Auto-generated method stub
	if (event.keyCode == Keyboard.ENTER)
	{
		gridDetail.selectedIndex=-1;
		amount.text="";
		phoInputCode.setFocus();
	}
}
protected function btToolBar_printClickHandler(lstrPurview:String, isPrintSign:String):void
{
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, lstrPurview))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}
	var _dataList:ArrayCollection=gridDetail.dataProvider as ArrayCollection;
	var dict:Dictionary=new Dictionary();
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="科室用包申请";
	dict["制表人"]=AppInfo.currentUserInfo.userName;
	dict["单据编号"]=cssdProvideMaster.billNo;
	dict["单据日期"]=DateField.dateToString(cssdProvideMaster.billDate, "YYYY-MM-DD")
	dict["申请科室"]=deptCode.txtContent.text;
	dict["申请人"]=personId.txtContent.text;
	dict["备注"]=cssdProvideMaster.remark;
	if (isPrintSign == '1')
		ReportPrinter.LoadAndPrint("report/materialDept/receive/ModReceiveBag.xml", _dataList, dict);
	if (isPrintSign == '0')
		ReportViewer.Instance.Show("report/materialDept/receive/ModReceiveBag.xml", _dataList, dict);
}

/**
 * 人员字典：点击
 * */
protected function personId_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict((function(item:Object):void
	{
		personId.txtContent.text=item.name;
		cssdProvideMaster.personId=item.personId;
		_tempPersonId=item.personId;
		if (_retrieveMaster)
		{
			_retrieveMaster.personId=item.personId;
		}
	}), x, y);
}

/**
 * 人员字典：回车
 * */
protected function personId_keyUpHandler(e:KeyboardEvent):void
{
	if (e.keyCode != 13)
		return;
	if (personId.txtContent.text.length > 0)
	{
		remark.setFocus();
		return
	}
	personId_queryIconClickHandler();
}

/**
 * 部门字典：点击
 * */
protected function deptCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict((function(item:Object):void
	{
		cssdProvideMaster.deptCode=item.deptCode;
		deptCode.txtContent.text=item.deptName;
		_tempDeptCode=item.deptCode;
		if (_retrieveMaster)
		{
			_retrieveMaster.deptCode=item.deptCode;
		}
	}), x, y);
}

/**
 * 部门字典：回车
 * */
protected function deptCode_keyUpHandler(e:KeyboardEvent):void
{
	if (e.keyCode != 13) return;
	if (deptCode.txtContent.text.length > 0)
	{
		personId.setFocus();
		return
	}
	deptCode_queryIconClickHandler();
}

/**
 * 增加
 * */
protected function addClickHandler(event:Event):void
{
//	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, "01"))
//	{
//		Alert.show("您无此按钮操作权限！", "提示");
//		return;
//	}
	clearMe();
	noteButtonState();
	_btModifyBeClicked=false;
	//显示明细组件
	MainToolBar.setToolKitEnable(vgTop, true);
	phoInputCode.setFocus();
	MainToolBar.showSpecialBtn(btToolBar, null, [btToolBar.btAuto, btToolBar.btCancel, btToolBar.btSave,  btToolBar.btAddRow, btToolBar.btDelRow,btToolBar.btExit], true);
	cssdProvideMaster.deptCode=AppInfo.currentUserInfo.deptCode;
	deptCode.txtContent.text=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', cssdProvideMaster.deptCode) == null ? "" : ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', cssdProvideMaster.deptCode).deptName;
	//经手人
	cssdProvideMaster.personId=AppInfo.currentUserInfo.personId;
	personId.txtContent.text=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', AppInfo.currentUserInfo.personId) == null ? "" : ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', AppInfo.currentUserInfo.personId).personIdName;
	personId.enabled = deptCode.enabled = remark.enabled = true;
	queryStockSign=true;
	gridDetailEnabled=true;
	addPanel.height=32;
	blueType.selected=true;
	if(blueType.selected=true)
	{
		cssdProvideMaster.invoiceType=="1"
	}
	else
	{
		cssdProvideMaster.invoiceType=="2"
	}
}

/**
 * 显示明细组件
 * */
private function detailComponents(top:UIComponent, height:Number, bottom:UIComponent, b:Boolean):void
{
	top.height=height;
	bottom.includeInLayout=b;
	bottom.visible=b;
}
/**
 * 五笔码、拼音码 切换
 * */
protected function rdo_changeHandler(event:Event):void
{
	if(rdo.selection ==rdoPhoCode){
		AppInfo.currentUserInfo.inputCode = 'PHO_INPUT';
	}
	else {
		AppInfo.currentUserInfo.inputCode = 'FIVE_INPUT';
	}
}
/**
 * 自动完成表格回调
 * */
private function showItemDict(rev:Object):void
{
	var j:int=gridDetail.selectedIndex;
	if(gridDetail.selectedItem)
	{
		gridDetail.selectedItem.packageName=rev.packageName;
		gridDetail.selectedItem.packageMode=rev.packageMode;
		gridDetail.selectedItem.packageUnits=rev.packageUnits;
		gridDetail.selectedItem.tradePrice=rev.tradePrice;
		gridDetail.selectedItem.packageNo=rev.packageNo
		gridDetail.selectedItem.packageClass=rev.packageClass;
		gridDetail.selectedItem.packageId=rev.packageId;
	}
	else
	{
		for(var i:int;i<gridDetail.dataProvider.length;i++)
		{
			if(rev.packageId==gridDetail.dataProvider[i].packageId)
			{
				Alert.show("本条数据已经存在！", "提示信息", Alert.YES , null, function(e:CloseEvent):void
				{
					if (e.detail == Alert.YES)
					{
						phoInputCode.setFocus();
						return;
					}
				});
				return;
			}
		}
		
		j++;
		var arrayList:ArrayCollection=gridDetail.dataProvider as ArrayCollection;
		var cssdProvideDetail:CssdProvideDetail=new CssdProvideDetail();
		cssdProvideDetail.packageName=rev.packageName;
		cssdProvideDetail.packageMode=rev.packageMode;
		cssdProvideDetail.packageUnits=rev.packageUnits;
		cssdProvideDetail.packageNo=rev.packageNo;
		cssdProvideDetail.packageClass=rev.packageClass;
		cssdProvideDetail.packageId=rev.packageId;
		cssdProvideDetail.amount=0;
		cssdProvideDetail.checkAmount=0;
		cssdProvideDetail.tradePrice=rev.tradePrice;
		arrayList.addItem(cssdProvideDetail);
		gridDetail.dataProvider=arrayList;
	}
	gridDetail.selectedIndex=gridDetail.dataProvider.length-1;
	amount.text="";
	amount.setFocus();
	gridDetail.invalidateList();
}




/**
 * 将表格中的DeptPackageMaterial转成CssdRetrieveDetail
 * @param aryVcssdStock:表体中的数据.
 * */
public function DeptPackageMaterial2CssdRetrieveDetail(aryVcssdStock:ArrayCollection):ArrayCollection{
	//将DeptPackageMaterial转为回收明细
	var aryRetrieveDetail:ArrayCollection=MainToolBar.aryColTransfer(aryVcssdStock, CssdRetrieveDetail);
	return aryRetrieveDetail;
}



/**
 * 清空数据
 */ 
private function clearMe():void
{
	billNo.text="";
	billDate.selectedDate=new Date;
	deptCode.text="";
	personId.text="";
	remark.text="";
	phoInputCode.text="";
	packageName.text="";
	packageMode.text="";
	packageUnits.text="";
	amount.text="";
	maker.text="";
	makeDate.text="";
	verifier.text="";
	verifyDate.text="";
	detailRemark.text="";
	gridDetail.dataProvider=null;
	cssdProvideMaster.autoId=null;
	cssdProvideMaster.billDate= new Date
	cssdProvideMaster.billNo=null;
	cssdProvideMaster.deptCode=null;
	cssdProvideMaster.personId=null;
	cssdProvideMaster.remark=null;
	cssdProvideMaster.unitsCode=null;
}

/**
 * 清空拼音表头
 */ 
private function clearDet():void
{
	phoInputCode.text="";
	packageName.text="";
	packageMode.text="";
	packageUnits.text="";
	amount.text="";
}

