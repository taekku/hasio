package h5.servlet.vo;

import java.util.ArrayList;

public class IBSheetExcelDataItem {
	ArrayList<String> headerList = null;
	ArrayList<String> valueList = null;
	boolean hasData = false;
	
	public IBSheetExcelDataItem(ArrayList<String> headerList) {
		this.headerList = headerList;
	}
	
	public boolean useData() {
		return this.hasData;
	}

	public void setData(String columnName, String columnValue) {
		if (columnName == null)
			return;

		int idx = headerList.indexOf(columnName);

		if (idx == -1) {
			headerList.add(columnName);
			idx = headerList.indexOf(columnName);
		}

		if(!hasData && columnValue != null && !"".equals(columnValue))
			hasData = true;

		if (valueList == null)
			valueList = new ArrayList<String>();

		int size = valueList.size();
		int loopValue = idx+1;
		
		if (size < loopValue) {
			for (int i = size; i < loopValue; i++) {
				valueList.add("");
			}
		}
		
		valueList.set(idx, columnValue);
	}

	public String getData(String columnName) {
		if(headerList != null) {
			int idx = headerList.indexOf(columnName);
			
			if(idx > -1)
				return valueList.get(idx);
		}
		
		return "";
	}
}
