package h5.servlet;

import com.win.frame.server.ServerConfig;
import com.win.frame.server.ServerConfigFactory;
import com.win.rf.config.ConfigurationManager;
import com.win.rf.config.IConfigurationInfoProvider;
import h5.sys.command.CommandExecuteException;
import h5.sys.registry.RegistryItem;
import h5.sys.registry.SystemRegistry;
import h5.sys.util.LanguageUtil;
import org.json.simple.JSONObject;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.sql.DataSource;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.regex.Pattern;

public class ChangePassword extends HttpServlet { 
	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		String cur_password = req.getParameter("cur_password");
		String new_password = req.getParameter("new_password");
		System.out.println("new_password : " + new_password);
		String user_id = req.getParameter("user_id");
		String company_cd = req.getParameter("company_cd");
		String verification_cd = req.getParameter("verificationCd");
		String result = null;
		String errMsg = null;
		String errorMsg = null;
		
		try{ 
			
			result = firstWork(cur_password, new_password, user_id, company_cd, verification_cd);
			String[] rs = result.split("&"); 
			result = rs[0]; 
			errMsg = rs[1];
		
			if(errMsg.equals("null")){
				errorMsg = errMsg;
			}else{
				errorMsg = LanguageUtil.getLocaleValue(errMsg, "KO");
			}
			resp.setContentType("application/x-json; charset=UTF-8");
			PrintWriter pw = resp.getWriter();
			JSONObject obj = new JSONObject();
			
			obj.put("result", result);
			obj.put("errMsg", errorMsg);
			
			pw.print(obj);
			pw.flush();
		}catch(IOException e){
			e.printStackTrace();
		}catch(ServletException ee){
			ee.printStackTrace();
		}catch(Exception eee){
			eee.printStackTrace();
		}
	}
	
	public String firstWork(String curPwd, String newPwd, String userId, String companyCd , String verificationCd) throws Exception {
		IConfigurationInfoProvider provider = ConfigurationManager.getConfigurationInfoProvider();
		ServerConfig sConfig = ServerConfigFactory.getServerConfig();
		String jdbcJndiPrefix = sConfig.getConfigValue("jdbcJndiPrefix");
		String jndiName =jdbcJndiPrefix+ provider.getItem("h5prd.jdbc.jndi").getValue();
		Connection con = null;
		PreparedStatement stmt = null;
		ResultSet rset = null;
		
		Boolean bException = Boolean.valueOf(false);
		String errMsg = "";
		try{
			Context ctx = new InitialContext();
			Object o = ctx.lookup(jndiName);
			DataSource ds = (DataSource) o;
			con = ds.getConnection();

			System.out.println("curPwd : " + curPwd);
			System.out.println("userId : " + userId);
			System.out.println("companyCd : " + companyCd);
			System.out.println("verificationCd : " + verificationCd);

			StringBuffer sb = new StringBuffer();

//			인증번호 조회/비교
			sb.append(" SELECT CASE WHEN EXISTS ( ");
			sb.append("      SELECT VERIFICATION_CD ");
			sb.append("  FROM ( SELECT ROW_NUMBER() OVER( ");
			sb.append(" ORDER BY SEND_DATE DESC ) AS RK1 , ");
			sb.append("  VERIFICATION_CD ");
			sb.append("   FROM FRM_SMS_VERIFICATION ");
			sb.append("  WHERE COMPANY_CD = ? ");
			sb.append("   AND LOGIN_ID = ( ");
			sb.append("   SELECT LOGIN_ID ");
			sb.append("   FROM FRM_USER ");
			sb.append("   WHERE USER_ID = ?) ) K ");
			sb.append("   WHERE RK1 = 1 ");
			sb.append("   AND VERIFICATION_CD = ? ) THEN 'Y' ");
			sb.append("   ELSE 'N'END AS VERIFY_RESULT; ");
			
			stmt = con.prepareStatement(sb.toString());
			stmt.setString(1, companyCd);
			stmt.setString(2, userId);
			stmt.setString(3, verificationCd);
			rset = stmt.executeQuery();
			
			String verificationRs = "";
			while(rset.next()){
				verificationRs = rset.getString("verify_result");
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
			System.out.println("verificationRs : " + verificationRs);
			if("N".equals(verificationRs)){
				errMsg = "FRM.ERRORMSG_0009";
				System.out.println("errMsg :" +  errMsg);
				bException = Boolean.valueOf(true);
				System.out.println("throw new Exception");
				throw new Exception();
			}
			
//			비밀번호 변경 시에는 현재 비밀번호 체크를 하지 않기 때문에 checkPwd 값을 TRUE로 설정
			String checkPwd = "TRUE";

			System.out.println("newPwd.length():" + newPwd.length());

			int pLength = newPwd.length();
			if(pLength < 8){
				errMsg = "FRM.ERRORMSG_0010";
				bException = Boolean.valueOf(true); 
				throw new Exception();
			}else{
				String pattern = "^[ㄱ-ㅎ가-힣a-zA-Z0-9]*$";
				
				boolean cb1 = newPwd.matches(".*[a-z]+.*");
				boolean cb2 = newPwd.matches(".*[A-Z]+.*");
				boolean cb3 = newPwd.matches(".*[0-9]+.*");
				boolean cb4 = Pattern.matches(pattern , newPwd);
				
				if (((!cb1) && (!cb2)) || (!cb3) || (cb4)){
					errMsg = "FRM.ERRORMSG_0011";
					bException = Boolean.valueOf(true);
					throw new Exception();
				}
			}
			
			if(!bException.booleanValue()){
				System.out.println("checkPwd : " + checkPwd);
				if("TRUE".equals(checkPwd)){
					RegistryItem regItem = SystemRegistry.getRegistryItem("GLOBAL_ATTR/MODULES/FRM/PWD_HIS_YN");
					String pwdHisYn = null;
					String pwdCnt = "0";
					if(regItem != null){
						pwdHisYn = regItem.getValue();
					}
					regItem = SystemRegistry.getRegistryItem("GLOBAL_ATTR/MODULES/FRM/PWD_HIS_CNT");
					if(regItem != null){
						System.out.println("## regItem.getValue [ pwdCnt ] : "+regItem.getValue() );
						pwdCnt = regItem.getValue();
					}
					if(("Y".equals(pwdHisYn)) && ("0".equals(pwdCnt))){
						System.out.println("### Y && 0 ? : "+pwdHisYn +" / "+pwdCnt);
						checkPwd = "FALSE";
						errMsg = "FRM.ERRORMSG_0009";
						bException = Boolean.valueOf(true);
						
						CommandExecuteException ee = new CommandExecuteException(errMsg); 
						ee.setErrCode(errMsg);
						
						throw new Exception();
					}
//					최근 비밀번호와의 중복 여부 확인
					if("Y".equals(pwdHisYn)){
						System.out.println("## pwdHisYn : "+pwdHisYn+" / pwdCnt : "+pwdCnt);
						sb = new StringBuffer();
						sb.append(" SELECT CASE WHEN ISNULL(COUNT(PASSWORD),0) > 0 THEN 'FALSE' ");
						sb.append("        ELSE 'TRUE' END AS CHK_PWD ");
						sb.append("   FROM (SELECT PASSWORD ");
						sb.append("           FROM (SELECT PASSWORD ");
						sb.append("                      , ROW_NUMBER() OVER ( ORDER BY PWD_DATE DESC) AS RN");
						sb.append("                   FROM FRM_PWD_HIS ");
						sb.append("                 WHERE USER_ID = ? ");
						sb.append("               ) A ");
						sb.append("         WHERE RN <= dbo.XF_TO_NUMBER(?) ");
						sb.append("        ) AA ");
						sb.append(" WHERE AA.PASSWORD = dbo.F_SHAENCRYPTOR(?) ");
						
						stmt = con.prepareStatement(sb.toString());
						stmt.setString(1, userId);
						stmt.setString(2, pwdCnt);
						stmt.setString(3, newPwd);
						
						rset = stmt.executeQuery();
						while(rset.next()){
							checkPwd = rset.getString("chk_pwd");
				            sb = null;
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
					}
					if("TRUE".equals(checkPwd)){
						sb = new StringBuffer();

						System.out.println("newPwd : "+ newPwd);

//						새 비밀번호 업데이트
						sb.append("UPDATE FRM_USER ");
			            sb.append("   SET PASSWORD = dbo.F_SHAENCRYPTOR('" + newPwd + "'),");
			            sb.append("       PWD_DATE = GETDATE(), ");
			            sb.append("       STATUS_CD = 'Y', ");
			            sb.append("       INIT_YN = 'N', ");
			            sb.append("       TRY_CNT = 0 " );
			            sb.append(" WHERE USER_ID = " + userId);
						
			            stmt = con.prepareStatement(sb.toString());
			            stmt.executeUpdate();
			            
//			          	 비밀번호 이력에 새 비밀번호 삽입
			            if("Y".equals(pwdHisYn)){
			            	sb = new StringBuffer();
			            	sb.append("INSERT INTO FRM_PWD_HIS ");
			                sb.append("SELECT NEXT VALUE FOR S_FRM_SEQUENCE ");
			                sb.append("     , " + userId);
			                sb.append("     , dbo.F_SHAENCRYPTOR('" + newPwd + "')");
			                sb.append("     , GETDATE() ");
			                sb.append("     , " + userId);
			                sb.append("     , GETDATE() ");
			                
			                stmt = con.prepareStatement(sb.toString());
			                stmt.executeUpdate();
			                
			                sb = new StringBuffer();
//			               	오래된 비밀번호 이력 삭제
			                sb.append("DELETE FROM FRM_PWD_HIS ");
			                sb.append(" WHERE PWD_DATE < (SELECT MIN(PWD_DATE) AS PWD_DATE ");
			                sb.append("                     FROM (SELECT ROW_NUMBER() OVER( ORDER BY PWD_DATE DESC ) AS ROWNUM ");
			                sb.append("                                , PWD_DATE ");
			                sb.append("                             FROM FRM_PWD_HIS ");
			                sb.append("                            WHERE USER_ID = " + userId);
			                sb.append("                           ) A ");
			                sb.append("                    WHERE ROWNUM <= dbo.XF_TO_NUMBER(" + pwdCnt + "))");
			                sb.append("   AND USER_ID = " + userId);
			                
			                stmt = con.prepareStatement(sb.toString());
			                stmt.executeUpdate();
			            }
					}else{
						errMsg = "FRM.ERRORMSG_0008";
						bException = Boolean.valueOf(true);
						throw new Exception();
					}
				}else{
					errMsg = "FRM.ERRORMSG_0005";
					bException = Boolean.valueOf(true);
					throw new Exception();
				}
			}
			
		}catch(Exception e){
			e.printStackTrace();
			if("".equals(e.getMessage())){
				errMsg = "FRM.ERRORMSG_000";
				bException = Boolean.valueOf(true);
			}
			try{
				if (stmt != null)
		        {
		          stmt.close();
		          stmt = null;
		        }
		        if(con == null){
		        	throw new Exception();
		        }
		        con.close();
		        con = null;
			}catch(Exception ee){
				ee.printStackTrace();
				throw new Exception();
			}
		}finally{
			try{
		        if (stmt != null){
		          stmt.close();
		          stmt = null;
		        }
		        if (con != null){
		          con.close();
		          con = null;
		        }
		      }catch (Exception e){
		        e.printStackTrace();
		        if ("".equals(e.getMessage())){
		          errMsg = "FRM.ERRORMSG_000";
		          bException = Boolean.valueOf(true);
		          throw new Exception();
		        }
		      }
		}
		
		if(bException.booleanValue()){
			return "FAILURE!&"+errMsg;
		}else{
			return "SUCCESS!&null";
		}
	}
	
}
