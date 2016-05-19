package cn.superion.materialDept.util
{
	import mx.collections.ArrayCollection;
	
	public class RdTypeDict
	{
		/**
		 * 收发类别字典
		 * */
		public static var rdTypeDict:ArrayCollection = new ArrayCollection([
			{rdType:"101", rdTypeName:"领用入库"}, 
			{rdType:"102", rdTypeName:"盘盈入库"},
			{rdType:"103", rdTypeName:"期初入库"},
			{rdType:"109", rdTypeName:"其他入库"},
			{rdType:"201", rdTypeName:"领用出库"},
			{rdType:"202", rdTypeName:"盘亏出库"},
			{rdType:"203", rdTypeName:"报损出库"},
			{rdType:"209", rdTypeName:"其他出库"}]);
		/**
		 * 入库类别字典
		 * */
		public static var receviceTypeDict:ArrayCollection = new ArrayCollection([
			{receviceType:"101", receviceTypeName:"领用入库"}, 
			{receviceType:"102", receviceTypeName:"盘盈入库"},
			{receviceType:"103", receviceTypeName:"期初入库"},
			{receviceType:"109", receviceTypeName:"其他入库"}]);
		/**
		 * 出库类别字典
		 * */
		public static var deliverTypeDict:ArrayCollection = new ArrayCollection([
			{deliverType:"201", deliverTypeName:"领用出库"},
			{deliverType:"202", deliverTypeName:"盘亏出库"},
			{deliverType:"203", deliverTypeName:"报损出库"},
			{deliverType:"209", deliverTypeName:"其他出库"}]);
	}
}