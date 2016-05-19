/**
 *		 采购计划编制
 *		 作者: 朱玉峰 2011.06.18
 *		 修改：
 **/
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.materialDept.util.DefaultPage;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialPatsDetail;
import cn.superion.vo.material.MaterialPatsMaster;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;


private static const MENU_NO:String="0204";
public var DESTANATION:String="deptPatsFeeImpl";
public var autoId:String="";
public var _materialPatsMaster:MaterialPatsMaster=new MaterialPatsMaster();

/**
 * 初始化当前窗口
 * */
public function doInit():void
{
	initToolBar();
	toolBar.btAbandon.label="退费";
	parentDocument.title="病人记账作废";
	//重新注册客户端对应的服务端类
	registerClassAlias("cn.superion.materialDept.entity.MaterialPatsMaster", MaterialPatsMaster);
	registerClassAlias("cn.superion.materialDept.entity.MaterialPatsDetail", MaterialPatsDetail);
}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.imageList1, toolBar.imageList2, toolBar.btQuery, toolBar.imageList5, toolBar.btExit, toolBar.btAbandon, toolBar.imageList2];
	var laryEnables:Array=[toolBar.btAdd, toolBar.btQuery, toolBar.btExit];
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
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
}

/**
 * 清空主记录
 */
public function clearMaster():void
{
	FormUtils.clearForm(patsMaster)
	dataGridDetail.dataProvider=null;
}

/**
 * 全选框
 */
protected function ckAll_changeHandler(event:Event):void
{
	for each (var obj1:Object in dataGridDetail.dataProvider)
	{
		if (obj1.refundSign != "1")
		{
			obj1.isSelected=ckAll.selected;
		}
	}
	dataGridDetail.invalidateList();
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
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	var _dataList:ArrayCollection=dataGridDetail.dataProvider as ArrayCollection;
	var dict:Dictionary=new Dictionary();
	for (var i:int=0; i < _dataList.length; i++)
	{
		var item:Object=_dataList.getItemAt(i);
		item.factoryName=item.factoryName==null?"":item.factoryName;
		item.availDate=item.availDate==null?new Date():item.availDate;
		item.nameSpec=item.materialName + "  " + (item.materialSpec == null ? "" : item.materialSpec);
	}
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="病人记帐作废";
	dict["床号"]=bedNo.text==null?"":bedNo.text;
	dict["诊断"]=admDiagnose.text==null?"":admDiagnose.text;
	dict["制表人"]=AppInfo.currentUserInfo.userName;
	dict["单据编号"]=_materialPatsMaster.billNo;
	dict["申请日期"]=DateField.dateToString(_materialPatsMaster.applyDate, "YYYY-MM-DD")
	dict["住院号"]=_materialPatsMaster.inpNo==null?"":_materialPatsMaster.inpNo;
	dict["姓名"]=patientName.text==null?"":patientName.text;
	dict["性别"]=sex.text==null?"":sex.text;
	dict["年龄"]=age.text==null?"":age.text;
	dict["费别"]=chargeType.text==null?"":chargeType.text;
	dict["科室"]=deptCode.text==null?"":deptCode.text;
	dict["病区"]=wardCode.text==null?"":wardCode.text;
	dict["医生"]=consultingDoctor.text==null?"":consultingDoctor.text;
	dict["余额"]=prepaymentsLeft.text==null?"":prepaymentsLeft.text;
	if (printSign == '1')
		ReportPrinter.LoadAndPrint("report/materialDept/deliver/tallyOut/deliverExesTallyOut.xml", _dataList, dict);
	if (printSign == '0')
		ReportViewer.Instance.Show("report/materialDept/deliver/tallyOut/deliverExesTallyOut.xml", _dataList, dict);

}

/**
 * 作废按钮
 */
protected function toolBar_abandonClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	Alert.show('是否退费?', '提示', Alert.YES | Alert.NO, null, function(e:*):void
		{
			if (e.detail == Alert.YES)
			{
				var _ary:ArrayCollection=dataGridDetail.dataProvider as ArrayCollection;
				var ary:Array=new Array();

				for (var i:int=0; i < _ary.length; i++)
				{
					var patientI:String;
					if (_ary[i].isSelected)
					{
						patientI=_ary[i].patientId;
						ary.push(_ary[i].detailAutoId);
					}
				}
				if (ary.length <= 0)
				{
					Alert.show("请选择要退费的物品", "提示");
					return;
				}
				var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
					{
						Alert.show("退费成功", "提示");
						inpNoQuery();
						return;
					});
				ro.refundFee(autoId, ary);
			}
		})
}

/**
 * 给主记录文本赋值
 */
protected function masterEvaluate(rev:Object):void
{
	FormUtils.fillFormByItem(patsMaster, rev.data[0]);
	autoId=rev.data[0].autoId;
	var aplyDoctor:String=rev.data[0].doctorInCharge == null ? rev.data[0].applyDoctor : rev.data[0].doctorInCharge;
	var consultingDoctor1:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', aplyDoctor);
	var deptcode:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', rev.data[0].deptCode);
	var wardcode:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', rev.data[0].wardCode);
	patientName.text=consultingDoctor1 == null ? null : consultingDoctor1.personIdName;
	deptCode.text=deptcode == null ? null : deptcode.deptName;
	wardCode.text=wardcode == null ? null : wardcode.deptName;
	consultingDoctor.text=consultingDoctor1 == null ? "" : consultingDoctor1.personIdName;
}

/**
 * 按照住院号 查找病人详细信息
 */
protected function inpNo_keyUpHandler(event:KeyboardEvent):void
{
	// TODO Auto-generated method stub
	if (event.keyCode == Keyboard.ENTER)
	{
		inpNoQuery();
	}
}

/**
 * 查询按钮
 */
protected function toolBar_queryClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	inpNoQuery();

}

/**
 * 按照住院号查询
 */
public function inpNoQuery():void
{
	var ro:RemoteObject=RemoteUtil.getRemoteObject("deptPatsFeeImpl", function(rev:Object):void
		{
			if (rev.data[0] == null)
			{
				toolBar.btAbandon.enabled=false;
				toolBar.btPrint.enabled=false;
				toolBar.btExp.enabled=false;
				autoId="";
				//清空当前表单
				clearForm(true, true);
				return;
			}
			fillRdsMaster(rev.data[0]);
			masterEvaluate(rev);
			dataGridDetail.dataProvider=rev.data[1];
			toolBar.btAbandon.enabled=true;
			toolBar.btPrint.enabled=true;
			toolBar.btExp.enabled=true;
		});
	ro.findPatsFeeByPatientId(inpNo.text);
}
/**
 * 给主记录赋值
 */
private function fillRdsMaster(rev:Object):void
{
	_materialPatsMaster.billNo=rev.billNo;
	_materialPatsMaster.applyDate=rev.applyDate;
	_materialPatsMaster.inpNo=rev.inpNo;
	_materialPatsMaster.age=rev.age;
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
 * 转换人名
 */
protected function codeToName(name:String):String
{
	var makerItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', name);
	var maker:String=makerItem == null ? "" : makerItem.personIdName;
	return maker;
}

private function labelFun(item:Object, salerCode:DataGridColumn):*
{
	if (salerCode.headerText == "记账人")
	{
		var consultingDoctor:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', item.accounter);
		item.personIdName=consultingDoctor.personIdName;
		if (!consultingDoctor)
		{
			return '';
		}
		else
		{
			return item.personIdName;
		}
	}

	if (salerCode.headerText == "记账科室")
	{
		var deptcode:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', item.deptCode);
		item.deptName=deptcode.deptName;
		if (!deptcode)
		{
			return '';
		}
		else
		{
			return item.deptName;
		}
	}

	if (salerCode.headerText == "记账病区")
	{
		var wardcode:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', item.wardCode);
		item.wardName=wardcode.deptName;
		if (!wardcode)
		{
			return '';
		}
		else
		{
			return item.wardName;
		}
	}

	if (salerCode.headerText == "退费标志")
	{
		
		if (item.refundSign == "0")
		{
			return item.refund="未退费";
		}
		else if (item.refundSign == "1")
		{
			return item.refund="已退费";
		}
		else
		{
			return item.refund="未知";
		}
	}
}