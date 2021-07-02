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

public class MobileAjax extends HttpServlet{
	 
	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		String reqName = request.getParameter("name");
		String reqEmpNo = request.getParameter("emp_no");
		String companyCd = request.getParameter("company_cd");
		String choice = request.getParameter("choice");
		
		System.out.println("$$$$$$$$$ reqName : "+reqName);
		System.out.println("$$$$$$$$$ reqEmpNo : "+reqEmpNo);
		System.out.println("$$$$$$$$$ companyCd : "+companyCd);
		System.out.println("$$$$$$$$$ choice : "+choice);
		
		String result = "";
		try {
			//loginId = getLoginId(reqEmpNo, companyCd);
			response.setContentType("application/x-json; charset=UTF-8");
			PrintWriter pw = response.getWriter();
			JSONObject obj = new JSONObject();
			result = setFrmMhrCode(reqName, reqEmpNo, companyCd, choice);
			
			//결과 코드
			obj.put("result", result);
			pw.print(obj);
			pw.flush();
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
	}
	
	public String setFrmMhrCode(String reqName, String reqEmpNo, String companyCd, String choice) throws Exception {
		IConfigurationInfoProvider provider = ConfigurationManager.getConfigurationInfoProvider();
		ServerConfig sConfig = ServerConfigFactory.getServerConfig();
		String jdbcJndiPrefix = sConfig.getConfigValue("jdbcJndiPrefix");
		String jndiName =jdbcJndiPrefix+ provider.getItem("h5prd.jdbc.jndi").getValue();
		Connection con = null;
		PreparedStatement stmt = null;
		ResultSet rset = null;
		
		String faultCode = null; // 오류 발생시 전달할 코드
		String faultMessage = null; // 오류 발생시 전달할 코드 값
		
		String rtn_code = "";	// 프로시저 코드
		String rtn_message = ""; // 프로시저 메시지
		
		String type = ""; // 방법 구분(email : M, phone : S)
		String exEmail = ""; //실제 이메일
		String exPhone = ""; //실제 전화번호
		String exEmpNm = ""; //실제 성명
		int exEmpId = 0;
		String str1 = ""; // 인증번호 문자
		
		try{
			Context ctx = new InitialContext();
			Object o = ctx.lookup(jndiName);
			DataSource ds = (DataSource) o;
			con = ds.getConnection();
			
			StringBuffer sb = new StringBuffer();
			sb.append("WITH INFO AS( ");
			sb.append("		SELECT EMP_ID ");
			sb.append("			 , COMPANY_CD ");
			sb.append("			 , EMP_NO ");
			sb.append("			 , EMP_NM ");
			sb.append("		  FROM VI_FRM_PHM_EMP ");
			sb.append("		 WHERE COMPANY_CD = ? ");
			sb.append("		   AND EMP_NO = ? ");
			sb.append("		   AND EMP_NM = ? ");
			sb.append(" ) ");
			sb.append("SELECT A.EMP_ID ");
			sb.append("     , A.EMP_NM ");
			sb.append("     , B.EMAIL ");
			sb.append("     , DBO.F_FRM_DECRYPT_C(F_PHONE_NO) AS PHONE_NUM ");
			sb.append("  FROM INFO A ");
			sb.append("  LEFT OUTER JOIN PHM_PRIVATE B ");
			sb.append("    ON A.EMP_ID = B.EMP_ID ");
			sb.append("  LEFT OUTER JOIN PHM_PHONE C ");
			sb.append("    ON A.EMP_ID = C.EMP_ID ");
			sb.append("   AND C.PHONE_TYPE_CD = 'HP' ");
			sb.append("   AND dbo.XF_SYSDATE(0) BETWEEN C.STA_YMD AND C.END_YMD ");
			
			
			stmt = con.prepareStatement(sb.toString());
			stmt.setString(1, companyCd);
			stmt.setString(2, reqEmpNo);
			stmt.setString(3, reqName);
			
			rset = stmt.executeQuery();
			
			if(rset.next()){
				exEmpId = rset.getInt("emp_id");
				exEmpNm = rset.getString("emp_nm");
				exEmail = rset.getString("email");
				exPhone = rset.getString("phone_num");
			}
			
			System.out.println("##### 이메일 : "+exEmail);
			System.out.println("##### 전화번호 : "+exPhone);
			System.out.println("##### 성명 : "+exEmpNm);
			
			// 난수 생성
			CharacterTable ct = new CharacterTable();
			str1 = ct.excuteRandomStr();
			
			if(choice == "email" || choice.equals("email")){
				type = "M";		
			}else if(choice == "phone" || choice.equals("phone")){
				type = "S";
			}
			
			//프로시저 
			CallableStatement  cs = con.prepareCall("{ call P_MHR_SEND_MAIL(?, ?, ?, ?, ?, ?, ?, ?)}");
			
			cs.setString(1, companyCd);
			cs.setInt(2, exEmpId);
			cs.setString(3, "KO");
			cs.setString(4, type);
			cs.setString(5, str1);
			cs.setString(6, reqEmpNo);
			cs.registerOutParameter(7, java.sql.Types.VARCHAR);
			cs.registerOutParameter(8, java.sql.Types.VARCHAR);
			
			System.out.println("### 회사코드 : "+companyCd +" 방법 : "+choice+" 난수 : "+str1);
			
			cs.execute();
			rtn_code = cs.getString(7);
			rtn_message = cs.getString(8);
			System.out.println("rtn_code : " + rtn_code);
			System.out.println("rtn_message : " + rtn_message);
			
			if(cs != null){
				cs.close();
				cs = null;
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
		return rtn_code;
	}
	
	
}
