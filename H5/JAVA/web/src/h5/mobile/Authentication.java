package h5.mobile;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.sql.DataSource;

import org.json.simple.JSONObject;

import com.win.frame.server.ServerConfig;
import com.win.frame.server.ServerConfigFactory;
import com.win.rf.config.ConfigurationManager;
import com.win.rf.config.IConfigurationInfoProvider;

public class Authentication extends HttpServlet{
	
	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		String vali = request.getParameter("validation");
		String reqEmpNo = request.getParameter("emp_no");
		String companyCd = request.getParameter("company_cd");
		String reqLoginId = request.getParameter("login_id");
		
		System.out.println("$$$$$$$$$ 문자인증 확인 서블릿 ");
		System.out.println("$$$$$$$$$ reqEmpNo 	: "+reqEmpNo);
		System.out.println("$$$$$$$$$ vali 		: "+vali);
		System.out.println("$$$$$$$$$ companyCd : "+companyCd);
		System.out.println("$$$$$$$$$ reqLoginId : "+reqLoginId);
		
		String result = null;
		String loginId = null;
		int userId = 0;
		try {
			
			userId = getUserId(reqEmpNo, companyCd);
			
			result = getAuthentication(vali, userId, companyCd);
			
			System.out.println("##### 결과 : "+result);
			
			response.setContentType("application/x-json; charset=UTF-8");
			PrintWriter pw = response.getWriter();
			JSONObject obj = new JSONObject();
			if(result.equals("Y")){
				obj.put("result", result);
				obj.put("loginId", loginId);
				obj.put("userId", userId);
			}
			pw.print(obj);
			pw.flush();
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
	}
	
	/**
	 * 사용자가 입력한 문자와 DB에 저장된 문자 비교
	 * @param muja
	 * @param loginId
	 * @return
	 */
	public String getAuthentication(String str, int userId, String companyCd){
		IConfigurationInfoProvider provider = ConfigurationManager.getConfigurationInfoProvider();
		ServerConfig sConfig = ServerConfigFactory.getServerConfig();
		String jdbcJndiPrefix = sConfig.getConfigValue("jdbcJndiPrefix");
		String jndiName =jdbcJndiPrefix+ provider.getItem("h5prd.jdbc.jndi").getValue();
		Connection con = null;
		PreparedStatement stmt = null;
		ResultSet rset = null;
		
		String auth = "";
		
		try{
			Context ctx = new InitialContext();
			Object o = ctx.lookup(jndiName);
			DataSource ds = (DataSource) o;
			con = ds.getConnection();
			
			StringBuffer sb = new StringBuffer();
			sb.append(" SELECT CASE WHEN EXISTS ( ");
			sb.append("      SELECT VERIFICATION_CD ");
			sb.append("  FROM ( SELECT ROW_NUMBER() OVER( ");
			sb.append(" ORDER BY SEND_DATE DESC ) AS RK1 , ");
			sb.append("  VERIFICATION_CD ");
			sb.append("   FROM FRM_SMS_VERIFICATION ");
			sb.append("  WHERE DATEADD(MI, 5, SEND_DATE) > GETDATE() ");
			sb.append("   	AND COMPANY_CD = ? ");
			sb.append("   AND LOGIN_ID = ( ");
			sb.append("   SELECT LOGIN_ID ");
			sb.append("   FROM FRM_USER ");
			sb.append("   WHERE USER_ID = ?) ) K ");
			sb.append("   WHERE RK1 = 1 ");
			sb.append("   AND VERIFICATION_CD = ? ) THEN 'Y' ");
			sb.append("   ELSE 'N'END AS VERIFY_RESULT; ");
			
			stmt = con.prepareStatement(sb.toString());
			stmt.setString(1, companyCd);
			stmt.setInt(2, userId);
			stmt.setString(3, str);
			rset = stmt.executeQuery();
			
			while(rset.next()){
				auth = rset.getString("verify_result");
			}
			sb = null;
			
			if(rset != null){
				rset.close();
				rset = null;
			}
			
			if(stmt != null){
				stmt.close();
				stmt = null;
			}
			System.out.println("verificationRs : " + auth);
			if("N".equals(auth)){
				System.out.println("errMsg :" +  "인증번호 오류");
				System.out.println("throw new Exception");
				throw new Exception();
			}
			
		}catch(Exception e){
			e.printStackTrace();
		}finally{
			try{
				if(rset != null){
					rset.close();
					rset = null;
				}
				if(stmt != null){
					stmt.close();
					stmt = null;
				}
				if(con != null){
					con.close();
					con = null;
				}
			}catch(Exception ee){
				ee.printStackTrace();
			}
		}
		 
		return auth;
	}
	
	/**
	 * 실제 아이디를 조회한다.(FRM_USER, FRM_USER_EMP_MAP)
	 * @param empNo
	 * @param companyCd
	 * @return
	 */
	public String getLoginId(String empNo, String companyCd){
		
		IConfigurationInfoProvider provider = ConfigurationManager.getConfigurationInfoProvider();
		ServerConfig sConfig = ServerConfigFactory.getServerConfig();
		String jdbcJndiPrefix = sConfig.getConfigValue("jdbcJndiPrefix");
		String jndiName =jdbcJndiPrefix+ provider.getItem("h5prd.jdbc.jndi").getValue();
		Connection con = null;
		PreparedStatement stmt = null;
		ResultSet rset = null;
		
		String result = "";
		StringBuffer sb = null;
		int empId = 0 ;
		try{
			Context ctx = new InitialContext();
			Object o = ctx.lookup(jndiName);
			DataSource ds = (DataSource) o;
			con = ds.getConnection();
			
			sb = new StringBuffer();
			
			sb.append(" SELECT EMP_ID ");
			sb.append("   FROM VI_FRM_PHM_EMP ");
			sb.append("  WHERE EMP_NO = ? ");
			sb.append("    AND COMPANY_CD = ? ");
			
			stmt = con.prepareStatement(sb.toString());
			stmt.setString(1, empNo);
			stmt.setString(2, companyCd);
			
			rset = stmt.executeQuery();
			if(rset.next()){
				empId = rset.getInt("emp_id");
			}
			sb = null;
			
			if(rset != null){
				rset.close();
				rset = null;
			}
			
			if(stmt != null){
				stmt.close();
				stmt = null;
			}
			
			sb = new StringBuffer();
			
			sb.append("SELECT A.LOGIN_ID ");
			sb.append("	 FROM FRM_USER A ");
			sb.append("	INNER JOIN FRM_USER_EMP_MAP B ");
			sb.append("	   ON A.USER_ID = B.USER_ID ");
			sb.append("	WHERE B.EMP_ID = ? ");
			sb.append("	  AND A.COMPANY_CD = ? ");
			
			
			stmt = con.prepareStatement(sb.toString());
			stmt.setInt(1, empId);
			stmt.setString(2, companyCd);
			
			rset = stmt.executeQuery();
			
			if(rset.next()){
				result = rset.getString("login_id");
			}
			
			System.out.println("##### 실제 ID : "+result);
			
		}catch(Exception e){
			e.printStackTrace();
		}finally{
			try{
				if(rset != null){
					rset.close();
					rset = null;
				}
				if(stmt != null){
					stmt.close();
					stmt = null;
				}
				if(con != null){
					con.close();
					con = null;
				}
			}catch(Exception ee){
				ee.printStackTrace();
			}
		}
		
		return result;
		
	}
	
	/**
	 * USER_ID 찾기
	 * @param loginId
	 * @param companyCd
	 * @return
	 */
	public int getUserId(String loginId, String companyCd){
		IConfigurationInfoProvider provider = ConfigurationManager.getConfigurationInfoProvider();
		ServerConfig sConfig = ServerConfigFactory.getServerConfig();
		String jdbcJndiPrefix = sConfig.getConfigValue("jdbcJndiPrefix");
		String jndiName =jdbcJndiPrefix+ provider.getItem("h5prd.jdbc.jndi").getValue();
		Connection con = null;
		PreparedStatement stmt = null;
		ResultSet rset = null;
		
		int result = 0;
		StringBuffer sb = null;
		try{
			Context ctx = new InitialContext();
			Object o = ctx.lookup(jndiName);
			DataSource ds = (DataSource) o;
			con = ds.getConnection();
			
			sb = new StringBuffer();
			
			sb.append("SELECT USER_ID ");
			sb.append("	 FROM FRM_USER  ");
			sb.append("	WHERE LOGIN_ID = ? ");
			sb.append("	  AND COMPANY_CD = ? ");
			
			
			stmt = con.prepareStatement(sb.toString());
			stmt.setString(1, loginId);
			stmt.setString(2, companyCd);
			
			rset = stmt.executeQuery();
			
			if(rset.next()){
				result = rset.getInt("user_id");
			}
			
			System.out.println("##### USER ID : "+result);
			
		}catch(Exception e){
			e.printStackTrace();
		}finally{
			try{
				if(rset != null){
					rset.close();
					rset = null;
				}
				if(stmt != null){
					stmt.close();
					stmt = null;
				}
				if(con != null){
					con.close();
					con = null;
				}
			}catch(Exception ee){
				ee.printStackTrace();
			}
		}
		return result ;
	}
}
