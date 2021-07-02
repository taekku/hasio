package hrms.intcom;

import h5.sys.util.ConnectionUtil;

import java.sql.Connection;
import java.util.HashMap;

import com.win.frame.invoker.Result;
import com.win.rf.invoker.DBModelInvoker;

public class DBModelInvokerAdapter {

	private String tableName = null;
	private HashMap<String, Object> paramMap = null;
	
	public DBModelInvokerAdapter(String tableName, HashMap<String, Object> paramMap) {
		this.tableName = tableName;
		this.paramMap = paramMap;
	}
	
	public Result doService() throws Exception {
		Connection con = ConnectionUtil.getInstance().getConnection();
		DBModelInvoker invoker = new DBModelInvoker(tableName, paramMap, con);
		Result rs = invoker.doService();
		con.close();
		con = null;
		
		return rs;
	}
}
