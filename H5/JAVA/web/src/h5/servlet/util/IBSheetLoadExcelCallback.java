package h5.servlet.util;

import com.ibleaders.ibsheet7.ibsheet.excel.LoadExcel;
import com.ibleaders.ibsheet7.util.LoadExcelCallbackInterface;
import com.win.frame.invoker.GridResult;
import com.win.rf.invoker.SQLInvoker;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;

public class IBSheetLoadExcelCallback
  implements LoadExcelCallbackInterface
{
  HashMap<String, Integer> autoValueSequenceMap = null;

  HashMap<String, String> staticColumnValue = null;

  ArrayList<String> autoColumns = null;

  boolean hasParamLoaded = false;

  String baseYmdColumnName = null;
  String baseYmdValue = null;
  String companyCd = null;
  String langCd = null;

  HashMap<String, String[]> verifyMap = null;
  ArrayList<String> verifyColumns = null;

  LoadExcel ibExcel = null;

  public IBSheetLoadExcelCallback(LoadExcel ibExcel)
  {
    this.autoValueSequenceMap = new HashMap();
    this.staticColumnValue = new HashMap();
    this.autoColumns = new ArrayList();
    this.verifyMap = new HashMap();
    this.verifyColumns = new ArrayList();
    this.ibExcel = ibExcel;
  }

  String getAutoValue(String key)
  {
    String returnValue = null;

    if (this.autoValueSequenceMap.containsKey(key)) {
      int seq = ((Integer)this.autoValueSequenceMap.get(key)).intValue();
      returnValue = key + seq;
      ++seq;
      this.autoValueSequenceMap.put(key, new Integer(seq));
    }
    else if (this.staticColumnValue.containsKey(key)) {
      returnValue = (String)this.staticColumnValue.get(key);
    }

    return returnValue;
  }

  public void callback(HashMap<String, String> map)
  {
    try
    {
      String extendParam = this.ibExcel.getExtendParam();
      if ((extendParam == null) || (extendParam.trim().length() == 0)) {
        return;
      }
      if (!this.hasParamLoaded)
      {
        String[] extendArr = extendParam.split(",");

        int i = 0; for (int totCnt = extendArr.length; i < totCnt; ++i) {
          String key = extendArr[i].substring(0, extendArr[i].indexOf("="));
          String value = extendArr[i].substring(extendArr[i].indexOf("=") + 1);

          if ((key != null) && (!"".equals(key))) {
            if ("auto_value_column".equals(key)) {
              this.autoValueSequenceMap.put(value, new Integer(0));
              this.autoColumns.add(value);
            }
            else if ("addSeqColumns".equals(key)) {
              String[] tmps = value.split("@");
              for (int j = 0; j < tmps.length; ++j) {
                this.autoValueSequenceMap.put(tmps[j], new Integer(0));
                this.autoColumns.add(tmps[j]);
              }
            }
            else if ("verify".equals(key)) {
              String[] tmp = value.split("@");

              for (int j = 0; j < tmp.length; ++j) {
                String[] tmp2 = tmp[j].split(":");
                if (("base_ymd".equals(tmp2[0])) || ("company_cd".equals(tmp2[0])) || ("lang_cd".equals(tmp2[0])) || ("base_ymd_value".equals(tmp2[0]))) {
                  if ("base_ymd".equals(tmp2[0]))
                    this.baseYmdColumnName = tmp2[1];
                  else if ("company_cd".equals(tmp2[0]))
                    this.companyCd = tmp2[1];
                  else if ("lang_cd".equals(tmp2[0]))
                    this.langCd = tmp2[1];
                  else if ("base_ymd_value".equals(tmp2[0]))
                    this.baseYmdValue = tmp2[1];
                }
                else if (("emp_no".equals(tmp2[0])) || ("ctz_no".equals(tmp2[0])) || ("org_cd".equals(tmp2[0]))) {
                  String[] tmp3 = tmp2[1].split("&");

                  for (int k = 0; k < tmp3.length; ++k) {
                    String[] tmp4 = tmp3[k].split("#");
                    this.verifyColumns.add(tmp4[0]);
                    String[] val = { tmp2[0], tmp4[1] };
                    this.verifyMap.put(tmp4[0], val);
                  }
                }
              }
            }
            else {
              this.staticColumnValue.put(key, value);
              this.autoColumns.add(key);
            }
          }
        }

        this.hasParamLoaded = true;
      }

      Iterator keys = this.autoColumns.iterator();
      while (keys.hasNext()) {
        String key = (String)keys.next();
        String value = getAutoValue(key);
        map.put(key, value);
      }

      keys = this.verifyColumns.iterator();
      while (keys.hasNext()) {
        String key = (String)keys.next();
        String value = getAutoValue(key);
        verify(key, map);
      }
    }
    catch (Exception localException)
    {
    }
  }

  private void verify(String key, HashMap<String, String> map)
  {
    if ((map.get(key) != null) && (!"".equals(map.get(key)))) {
      String[] tmp1 = (String[])this.verifyMap.get(key);
      String verifyType = tmp1[0];

      String sqlId = null;
      if ("emp_no".equals(verifyType))
        sqlId = "FRM_SHEET_001";
      else if ("ctz_no".equals(verifyType))
        sqlId = "FRM_SHEET_002";
      else if ("org_cd".equals(verifyType)) {
        sqlId = "FRM_SHEET_003";
      }

      if (sqlId == null) return;
      try {
        HashMap paramMap = new HashMap();
        paramMap.put("company_cd", this.companyCd);
        paramMap.put("lang_cd", this.langCd);

        String baseYmd = null;

        if ((this.baseYmdValue != null) && (!"".equals(this.baseYmdValue)))
          baseYmd = this.baseYmdValue;
        else {
          baseYmd = (String)map.get(this.baseYmdColumnName);
        }

        if ((baseYmd != null) && (!"".equals(baseYmd))) {
          baseYmd = baseYmd.replaceAll("\\s|\\.|/|-|:", "");

          if (baseYmd.length() > 8) {
            baseYmd = baseYmd.substring(0, 8);
          }
        }
        paramMap.put("base_ymd", baseYmd);

        String searchValue = (String)map.get(key);

        if ("ctz_no".equals(verifyType)) {
          searchValue = searchValue.replaceAll("-", "");
        }

        paramMap.put("search_value", searchValue);

        String[] bindingColumns = tmp1[1].split("\\|");

        SQLInvoker invoker = new SQLInvoker(sqlId, paramMap);
        GridResult result = (GridResult)invoker.doService();

        boolean hasData = result.next();

        for (int i = 0; i < bindingColumns.length; ++i) {
          String[] tmp2 = bindingColumns[i].split("-");

          if (hasData)
            map.put(tmp2[1], result.getValueString(tmp2[0]));
          else
            map.put(tmp2[1], "");
        }
      }
      catch (Exception e) {
        e.printStackTrace();
      }
    }
  }
}