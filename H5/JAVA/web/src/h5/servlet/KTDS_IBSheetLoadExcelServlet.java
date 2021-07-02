package h5.servlet;

import java.util.ArrayList;
import java.util.Iterator;

import h5.servlet.vo.IBSheetExcelData;
import h5.servlet.vo.IBSheetExcelDataItem;

public class KTDS_IBSheetLoadExcelServlet extends IBSheetLoadExcelServlet {

	@Override
	protected void dataProcessing(IBSheetExcelData excelData, String extendParam) {

		if (extendParam == null || "".equals(extendParam))
			return;

		String[] extendArr = extendParam.split(",");

		if (extendArr != null && extendArr.length > 0) {
			ArrayList<String> autoValues = new ArrayList<String>();

			ArrayList<String> autoKey = new ArrayList<String>();
			ArrayList<String> autoValue = new ArrayList<String>();

			for (int i = 0, totCnt = extendArr.length; i < totCnt; i++) {
				String key = extendArr[i].substring(0, extendArr[i].indexOf("="));
				String value = extendArr[i].substring(extendArr[i].indexOf("=") + 1);

				if (key != null && !"".equals(key)) {
					if ("auto_value_column".equals(key)) {
						autoValues.add(value);

					} else if ("addSeqColumns".equals(key)) {
						String[] tmps = value.split("@");

						for (int j = 0; j < tmps.length; j++) {
							autoValues.add(tmps[j]);
						}
					} else {
						autoKey.add(key);
						autoValue.add(value);
					}
				}

				ArrayList<IBSheetExcelDataItem> rowList = excelData.getRowList();

				if (rowList != null) {
					Iterator<IBSheetExcelDataItem> it1 = rowList.iterator();

					if (it1 != null) {
						int seq = 0;
						while (it1.hasNext()) {
							IBSheetExcelDataItem item = it1.next();

							if (item.useData()) {
								if (autoValues.size() > 0) {
									Iterator<String> it2 = autoValues.iterator();

									if (it2 != null) {
										while (it2.hasNext()) {
											String colNm = it2.next();

											item.setData(colNm, colNm + (seq++));
										}
									}
								}

								int keySize = autoKey.size();
								if (keySize > 0) {
									for (int j = 0; j < keySize; j++) {
										String colNm = autoKey.get(j);
										String colValue = autoValue.get(j);

										item.setData(colNm, colValue);
									}
								}
							}
						}
					}
				}
			}
		}
	}
}
