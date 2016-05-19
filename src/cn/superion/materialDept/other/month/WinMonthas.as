/** 
 *		 月末结账模块  
 *		 author:邢树斌   2011.02.29
 *		 modified by 
 *		 checked by 
 **/
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.vo.material.MaterialMonth;
import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;


private const DESTINATION:String="deptMonthImpl";

/**
 * 初始化
 * */
protected function doInit(event:Event):void
{
	fillYearCombo();
}
/**
 * 填充年度下拉框
 * */
private function fillYearCombo():void{
	var laryYears:ArrayCollection=new ArrayCollection()
	var curYear:int=new Date().getFullYear()
	for(var lintYear:int=curYear-10;lintYear<curYear+2;lintYear++){
		laryYears.addItem(lintYear);
	}
	year.dataProvider=laryYears;
	year.textInput.editable=false;
	storage.editable=false;
	year.selectedItem=curYear;
	storage.text=AppInfo.currentUserInfo.deptName
}


/**
 * 返回事件响应方法
 * */
protected function btReturn_clickHandler():void
{
	PopUpManager.removePopUp(this);
}

/**
 * 查询事件响应方法
 * */
protected function btQuery_clickHandler(event:MouseEvent):void
{
	var params:Object=FormUtils.getFields(queryArea, []);
	var paramQuery:ParameterObject=new ParameterObject();
	var strYear:String=year.selectedItem.toString()
	if(strYear=="")
	{
		Alert.show("请输入年份","提示");
		return;
	}
	
	paramQuery.conditions = params;
	//查询主记录ID列表
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
	{
		var list:ArrayCollection=rev.data as ArrayCollection;
		for (var i:int=0;i<list.length;i++)
		{
			var item:Object=list.getItemAt(i,i);
			if (item.accountSign=="0")
			{
				item.accountSign="否";
			}
			else
			{
				item.accountSign="是";
			}
		}
		gdMonthList.dataProvider=list;
	});
	ro.findMonth (strYear);
}


/**
 * 结账事件响应方法
 * */
protected function btCheck_clickHandler(event:MouseEvent):void
{
	var lmaterialMonth:MaterialMonth=gdMonthList.selectedItem as MaterialMonth;
	if(!lmaterialMonth){
		Alert.show("请选择结账数据","提示");
		return;
	}
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
	{		
		Alert.show("结账成功","提示");
		btQuery_clickHandler(null);
	});
	ro.saveMonth(lmaterialMonth);
	
}

/**
 * 取消事件响应方法
 * */
protected function btCancel_clickHandler(event:MouseEvent):void
{
	var lmaterialMonth:MaterialMonth=gdMonthList.selectedItem as MaterialMonth;
	if(!lmaterialMonth){
		Alert.show("请选择取消结账数据","提示")
		return;
	}	
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
	{
		if (rev.error == null)
		{
			Alert.show("取消结账成功","提示");
			btQuery_clickHandler(null);
			
		}
		
	});
	ro.cancelMonth(lmaterialMonth.yearMonth);
}