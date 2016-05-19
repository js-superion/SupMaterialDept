import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.DateUtil;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.materialDept.receive.receive.view.WinReceiveQuery;
import cn.superion.materialDept.util.DefaultPage;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialProvideMaster;
import cn.superion.vo.material.MaterialRdsMaster;
registerClassAlias("cn.superion.material.entity.MaterialRdsMaster", MaterialRdsMaster);
import mx.controls.Alert;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.core.UIComponent;
import mx.events.CollectionEvent;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
//
import cn.superion.materialDept.util.ToolBar;
import cn.superion.materialDept.util.MaterialDictShower;

private const MENU_NO:String="0101";
//服务类
public static const DESTANATION:String='deptApplyImpl';

private var _winY:int=0;

private var _materialProviderMaster:Object = new MaterialProvideMaster;
private var _materialRdsMaster:MaterialRdsMaster = new MaterialRdsMaster();

//查询主记录ID列表
public var arrayAutoId:Array=new Array();
//当前页，翻页用
public var currentPage:int=0;

/**
 * 初始化当前窗口
 * */ 
public function doInit():void
{
	parentDocument.title="物资入库确认";
	_winY=this.parentApplication.screen.height - 345;
	initPanel();
	
	if(MaterialDictShower.isAllUnitsDict)
	{
		MaterialDictShower.getAdvanceDictList();
	}
}

/**
 * 面板初始化
 */
private function initPanel():void
{
	initToolBar();
	setReadOnly(true);
}
/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	//初始按钮组
	var laryDisplays:Array =[toolBar.btPrint, toolBar.btExp, toolBar.imageList1,
		toolBar.btVerify, toolBar.imageList2,toolBar.btQuery,toolBar.imageList5, 
		toolBar.btFirstPage, toolBar.btPrePage, toolBar.btNextPage, toolBar.btLastPage,
		toolBar.imageList6, toolBar.btExit];
	var laryEnables:Array =[toolBar.btQuery, toolBar.btExit];
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 表头设置只读或读写状态
 */
private function setReadOnly(boolean:Boolean):void
{
	boolean=!boolean;
	storageCode.enabled=boolean;
	supplyDeptCode.enabled=boolean;
	
	billNo.enabled=boolean;
	
	billDate.enabled=boolean;
	
	cardCode.enabled=boolean;
	personId.enabled=boolean;
	deliverDate.enabled = boolean;
	remark.enabled=boolean;
}

/**
 * 审核
 * */
protected function verifyClickHandler(event:Event):void
{
	if(_materialProviderMaster.currentStatus == "3"){
		Alert.show('该单据已入库','提示');
		return;
	}
	Alert.show('确定审核单据号为['+_materialProviderMaster.billNo+']的单据？','提示',Alert.YES | Alert.NO,null,function(e:*):void{
		if (e.detail == Alert.YES ) {
			var ro:RemoteObject = RemoteUtil.getRemoteObject(DESTANATION,function(rev:Object):void{
				_materialProviderMaster = rev.data[3];
				toolBar.btVerify.enabled = _materialProviderMaster.currentStatus == "3" ? false:true;
				Alert.show("审核成功！","提示");
			});
			ro.verifyDeptReceive(_materialRdsMaster.autoId);
		}else{
			return;
		}
	})
}

/**
 * 查询
 * */
protected function queryClickHandler(event:Event):void
{
	var win:WinReceiveQuery=WinReceiveQuery(PopUpManager.createPopUp(this, WinReceiveQuery, true));
	win.iparentWin = this;
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
 * 翻页回调函数
 * */
public function findRdsById(o:Object):void{
	//
	var ros:RemoteObject = RemoteUtil.getRemoteObject(ModReceive.DESTANATION,function(ss:Object):void{
		registerClassAlias("cn.superion.material.entity.MaterialRdsMaster", MaterialRdsMaster);
		//发放主记录
		_materialRdsMaster = ss.data[0];
		//发放明细
		var rdsDetails:ArrayCollection = ss.data[1] as ArrayCollection;
		//申请主记录
		var providerMaster:Object = ss.data[2];
		//申请明细
		var providerDetails:ArrayCollection = ss.data[3] as ArrayCollection;
		_materialProviderMaster = providerMaster;
		//主记录赋值
		fillMaster(_materialRdsMaster,providerMaster);
		//明细赋值
		for each(var item:Object in providerDetails)
		{
			var factoryObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict,'provider',item.factoryCode);
			item.factoryName=factoryObj==null ? "" : factoryObj.providerName;
		}
		ary = providerDetails;
		for each(var obj:Object in rdsDetails)
		{
			factoryObj=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict,'provider',obj.factoryCode);
			obj.factoryName=factoryObj==null ? "" : factoryObj.providerName;
		}
		aryDeliverDetail = rdsDetails;
		// 表尾部分----------------------------------------------------------------------------
		fillReportFoot(providerMaster);
		toolBar.btVerify.enabled = _materialProviderMaster.currentStatus == "3" ? false:true;
		
	});
	ros.findDeliverDetail(o);
}

/**
 * 填充报表尾部，当保存，修改，删除，审核成功、或翻页查询时，调用
 * @param item,MaterialProvideMaster对象
 * */
private function fillReportFoot(item:Object):void{
	makeDate.text=null;
	maker.text=null;
	verifier.text =null;
	verifyDate.text=null;
	makeDate.text = DateUtil.dateToString(item.makeDate,"YYYY-MM-DD");
	maker.text = ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict,'personId',item.maker)==null?
		item.maker:ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict,'personId',item.maker).personIdName;
	verifier.text = ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict,'personId',item.verifier)==null?
		item.verifier:ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict,'personId',item.verifier).personIdName;
	verifyDate.text = DateUtil.dateToString(item.verifyDate,"YYYY-MM-DD");
}

/**
 * 填充主记录
 * @param rds:根据条件过滤出的 收发存主记录；
 * @param provider:根据条件过滤出的 科室领用主记录；
 * */
private function fillMaster(rds:Object,provider:Object):void{
	//----------------------------------
	//  来自收科室领用主记录
	//----------------------------------
	billNo.text = provider.billNo;
	//申请日期
	billDate.text = cn.superion.base.util.DateUtil.dateToString(provider.billDate,"YYYY-MM-DD");
	//----------------------------------
	//  来自收发存主记录
	//----------------------------------
	if(rds!=null)
	{
		var o:Object= ArrayCollUtils.findItemInArrayByValue(BaseDict.storageDict,'storage',rds.storageCode);
		storageCode.text =o==null?null:o.storageName;
		//供应部门
		o
		supplyDeptCode.text = ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict,'dept',rds.deptCode)==null?
			rds.deptCode:ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict,'dept',rds.deptCode).deptName;
		//领用卡号
		cardCode.text = rds.cardCode;
		//发放人
		personId.text = ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict,'personId',rds.personId)==null?
			rds.personId:ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict,'personId',rds.personId).personIdName;
		//发放日期
		deliverDate.text = cn.superion.base.util.DateUtil.dateToString(rds.billDate,"YYYY-MM-DD");
		//备注
		remark.text = rds.remark;
		//填充制单人等信息
	}
	else
	{
		Alert.show("操作有误，请重新打开系统！","提示");
	}
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
 * 响应表格数据变化事件
 * */
public function dgDetail_dataChangeHandler(event:CollectionEvent):void
{
	toolBar.btPrint.enabled
		=toolBar.btExp.enabled = ary.length == 0 ? false:true;	
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
	var dict:Dictionary = new Dictionary();
	dict["单位名称"] = AppInfo.currentUserInfo.unitsName;
	dict["日期"] =DateField.dateToString(new Date(),'YYYY-MM-DD');
	dict["主标题"] = "入库物资列表";
	dict["制单人"] ="制单人:"+AppInfo.currentUserInfo.userName;
	dict["制单日期"] = makeDate.text;
	dict["审核人"] = verifier.text;
	dict["审核日期"] = verifyDate.text;
	dict["供应仓库"]=storageCode.text;
	dict["供应部门"]=supplyDeptCode.text;
	dict["单据编号"]=billNo.text;
	dict["单据日期"]=billDate.text;
	dict["领用卡号"]=cardCode.text;
	dict["发放人"]=personId.text;
	dict["发放日期"]=deliverDate.text;
	dict["备注"]=remark.text;
	if(isPrintSign=='1') 
	{
		ReportPrinter.LoadAndPrint("report/materialDept/receive/receive.xml",_dataList,dict);
	}
	if(isPrintSign=='0')
	{
		ReportViewer.Instance.Show("report/materialDept/receive/receive.xml",_dataList,dict);
	}
}


protected function toolBar_verifyClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
}
