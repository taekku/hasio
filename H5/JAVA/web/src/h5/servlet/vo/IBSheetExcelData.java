package h5.servlet.vo;

import java.util.ArrayList;
import java.util.Iterator;

/**
 * 간단하게 row, column 데이터를 보관하는 객체
 * 
 * @author HongYS
 * 
 */
public class IBSheetExcelData {
	ArrayList<String> headerList = null;
	ArrayList<IBSheetExcelDataItem> rowList = null;
	IBSheetExcelDataItem currentItem = null;
	
	String statusCol = null;
	
	public String getStatusCol() {
		return this.statusCol;
	}
	
	public void setStatusCol(String statusCol) {
		this.statusCol = statusCol;
	}
	
	public IBSheetExcelDataItem newDataItem() {
		if (headerList == null)
			headerList = new ArrayList<String>();

		if (rowList == null)
			rowList = new ArrayList<IBSheetExcelDataItem>();

		currentItem = new IBSheetExcelDataItem(headerList);
		rowList.add(currentItem);
		
		return currentItem;
	}
	
	public IBSheetExcelDataItem getCurrentItem() {
		return currentItem;
	}
	
	public ArrayList<String> getHeaderList() {
		return this.headerList;
	}
	
	public ArrayList<IBSheetExcelDataItem> getRowList() {
		return this.rowList;
	}


	@Override
	/**
	 * json 구조로 반환한다....
	 */
	public String toString() {
		StringBuffer sb = new StringBuffer();

		if (rowList != null) {
			Iterator<IBSheetExcelDataItem> it = rowList.iterator();

			if (it != null) {
				sb.append("[");
				while (it.hasNext()) {
					IBSheetExcelDataItem item = it.next();
					
					if(!item.useData())
						continue;
					
					sb.append("{");
					
					for(int i = 0, headerSize = headerList.size(); i < headerSize; i++) {
						String key = headerList.get(i);
						String value = item.getData(key);
						
						sb.append("\"" + key + "\":\"" + value + "\"");
						
						if(i < headerSize-1)
							sb.append(",");
					}
					sb.append("}");

					if (it.hasNext())
						sb.append(",");
				}
				
				sb.append("]");
			}
		}

		return sb.toString();
	}
}
