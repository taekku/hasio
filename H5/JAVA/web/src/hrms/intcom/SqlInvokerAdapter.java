package hrms.intcom;

import h5.sys.util.ConnectionUtil;

import java.sql.Connection;
import java.util.HashMap;

import com.win.frame.invoker.Result;
import com.win.rf.invoker.SQLInvoker;

public class SqlInvokerAdapter {

	private String sqlId = null;
	private HashMap<String, Object> paramMap = null;
	
	public SqlInvokerAdapter(String sqlId, HashMap<String, Object> paramMap) {
		this.sqlId = sqlId;
		this.paramMap = paramMap;
	}
	
	public Result doService() throws Exception {
		Connection con = ConnectionUtil.getInstance().getConnection();
		
		SQLInvoker invoker = new SQLInvoker(sqlId, paramMap, con);
		Result rs = invoker.doService();
		con.close();
		con = null;
		
		return rs;
	}
}
