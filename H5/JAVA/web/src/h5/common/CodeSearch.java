package h5.common;

import com.win.commonlib.jrlib.jrTools;
import h5.sys.message.IListBaseMessage;
import h5.sys.message.IMessageItem;
import h5.sys.util.CodeUtil;

import java.util.HashMap;
import java.util.Iterator;

/**
 * 코드 데이터를 가져오기 위한 유틸 클래스
 *
 * @author HongYS
 *
 */
public class CodeSearch {
	private IListBaseMessage codeData = null;
	private String cdKind = null;

	/**
	 * 공통코드에 등록된 데이터를 이용하여 콤보 생성
	 *
	 * @param paramMap
	 *            코드데이터를 가져올시 조건이 들어간다
	 * @throws Exception
	 */
	public CodeSearch(HashMap<String, String> paramMap) {
		String companyCd = paramMap.get("company_cd");
		String localeCd = paramMap.get("locale_cd");
		String stdDate = paramMap.get("std_ymd");
		String orderNm = paramMap.get("order_nm");
		cdKind = paramMap.get("cd_kind");

		this.codeData = CodeUtil.getCodeByCodeKind(companyCd, localeCd, cdKind, orderNm, stdDate);
	}

	/**
	 * sql관리에 등록된 쿼리를 이용하여 콤보 생성
	 *
	 * @param paramMap
	 *            코드데이터를 가져올시 조건이 들어간다
	 * @param sqlId
	 * @throws Exception
	 */
	public CodeSearch(HashMap<String, String> paramMap, String sqlId) {
		String companyCd = paramMap.get("company_cd");
		cdKind = sqlId;

		this.codeData = CodeUtil.getCodeBySqlId(companyCd, sqlId, paramMap);
	}

	public boolean hasCodeData() {
		return ((this.codeData != null && this.codeData.size() > 0) ? true : false);
	}

	public String getScriptValue() {
		if (this.codeData == null)
			return "";

		StringBuffer value = new StringBuffer(" var "+ cdKind + " = [");
		Iterator<IMessageItem> it = codeData.iterator();

		while(it != null && it.hasNext()) {
			IMessageItem item = it.next();

			String cd = item.getElement("cd").toString();
			String cd_nm = item.getElement("cd_nm").toString();
			if (cd_nm == null || cd_nm.length() == 0)
				cd = "";

			value.append("{cd:'"+cd+"', cd_nm:'" + cd_nm +"'}");

			if(it.hasNext())
				value.append(",");
		}

		value.append("];");

		return value.toString();
	}

	public String getCodes() {
		return getCodeValue("cd");
	}

	public String getCodeNames() {
		return getCodeValue("cd_nm");
	}

	public String getCodeValue(String column) {
		if (this.codeData == null)
			return "";

		StringBuffer value = new StringBuffer();
		Iterator<IMessageItem> it = codeData.iterator();

		while (it != null && it.hasNext()) {
			IMessageItem item = it.next();
			String valueString = item.getElement(column).toString();

			if (valueString == null || valueString.length() == 0)
				continue;

			value.append("|");
			value.append(valueString);
		}

		return value.toString();
	}

	public String getOptions() {
		//System.out.println("getOptions() ==============");
		return getOptions(null);
	}

	public String getOptions(String selectedValue) {
		if (this.codeData == null)
			return "";

		StringBuffer value = new StringBuffer();
		Iterator<IMessageItem> it = codeData.iterator();

		while (it != null && it.hasNext()) {
			IMessageItem item = it.next();

			String cd = item.getElement("cd").toString();
			String cd_nm = item.getElement("cd_nm").toString();

			//System.out.println("CodeSearch -> value : " + cd);

			if (cd_nm == null || cd_nm.length() == 0)
				cd = "";
			value.append("<option value=\"" + cd + "\"");
			if (cd.equals(selectedValue))
				value.append(" selected");
			value.append(">");
			value.append(cd_nm);
			value.append("</option>");
		}
		return value.toString();
	}

	public String getOptions(String selectedValue, String labelCol) {
		if (this.codeData == null)
			return "";

		StringBuffer value = new StringBuffer();
		Iterator<IMessageItem> it = codeData.iterator();

		while (it != null && it.hasNext()) {
			IMessageItem item = it.next();

			String cd = jrTools.getNVL(item.getElement("cd").toString());
			String cd_nm = jrTools.getNVL(item.getElement("cd_nm").toString());
			String label = jrTools.getNVL(item.getElement(labelCol).toString());
			if (cd_nm.equals(""))
				cd = "";
			value.append("<option value=\"" + cd + "\"");
			value.append(" label=\"" + label + "\"");
			if (cd.equals(selectedValue))
				value.append(" selected");
			value.append(">");
			value.append(cd_nm);
			value.append("</option>");
		}

		return value.toString();
	}
}
