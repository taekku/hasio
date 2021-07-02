package h5.pay.cbpay;

import java.util.HashMap;
import java.util.Iterator;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.sql.DataSource;

import com.win.frame.server.ServerConfig;
import com.win.frame.server.ServerConfigFactory;
import com.win.rf.config.ConfigurationManager;
import com.win.rf.config.IConfigurationInfoProvider;

import com.win.frame.invoker.GridResult;
import com.win.rf.invoker.SQLInvoker;

import h5.sys.command.AbsBusinessCommand;
import h5.sys.command.CommandExecuteException;
import h5.sys.context.IRequestContext;
import h5.sys.context.ResponseContext;
import h5.sys.message.IListBaseMessage;
import h5.sys.message.IMessageItem;

/**
 * 급여이체내역생성
 * PAY0088 
 * @author taekg
 *
 */
public class KBPayTransferCommand extends AbsBusinessCommand {

	public static Connection getConnection(){
		IConfigurationInfoProvider provider = ConfigurationManager.getConfigurationInfoProvider();
		ServerConfig config = ServerConfigFactory.getServerConfig();
		String jdbcJndiPrefix = config.getConfigValue("jdbcJndiPrefix");
		System.out.println("jdbcJndiPrefix:" + jdbcJndiPrefix);
//		String jndiName = jdbcJndiPrefix+provider.getItem("h5prd.jdbc.jndi").getValue();
		String jndiName = jdbcJndiPrefix+provider.getItem("cbpay.jdbc.jndi").getValue();
		System.out.println("jndiName:" + jndiName);
		Connection con = null;

		try{
			Context ctx = new InitialContext();
			DataSource ds = (DataSource)ctx.lookup(jndiName);
//			DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/cbpay");
			con = ds.getConnection();
		}catch(Exception e){
			e.printStackTrace();
			con = null;
		}
		
		return con;
		
	}
	@Override
	protected ResponseContext execute(IRequestContext requestContext) throws CommandExecuteException {
		ResponseContext resContext = requestContext.getResponseContext();
		try {
			resContext = executeCyberBranch(requestContext);
		} catch (CommandExecuteException cee) {
			resContext.setResultType(ResponseContext.RESULT_TYPE_ERROR);
			String message = cee.getMessage();					
			resContext.setResultMessage(message);
			resContext.setResultCode(message);
			throw cee;
		}
		
		return resContext;
	}
	protected ResponseContext executeCyberBranch(IRequestContext requestContext) throws CommandExecuteException {

		ResponseContext resContext = requestContext.getResponseContext();
		
		System.out.println("================= KBPayTransferCommand START =======================");
		SQLInvoker invoker	= null;
		GridResult result 	= null;
		Connection cb_conn = null; // CB_PAY을 위한 DB CONNECTION
		
		String locale_cd = null;
		String company_cd = null;
		String site_cd = null;
		String give_ymd = null;
		String pay_ymd_id = null;
		String closeYn = null;
		String pay_type_cd = null;
		String pay_ymd = null;
		String pay_group = null;
		String mod_user_id = null;
		String work_ymd = null;
		String err_msg = null;
		
		String file_cnt = null;
		String file_seq = null;
		int seq = 0;

		
		// 1. 페이지에서 넘어온 parameter 를 처리한다.
		IListBaseMessage paramMessage = (IListBaseMessage) requestContext.getMessage( "ME_PAY0088_01_01" );
		
		Iterator<IMessageItem> items = paramMessage.iterator();
		
		if ( items.hasNext()) {
			
			IMessageItem itemOne = items.next();
			company_cd  = (String) itemOne.getElement("company_cd");
			locale_cd   = (String) itemOne.getElement("locale_cd");
			site_cd     = (String) itemOne.getElement("site_cd");
			pay_ymd_id 	= (String) itemOne.getElement("pay_ymd_id");
			give_ymd 	= (String) itemOne.getElement("give_ymd");
			mod_user_id = (String) itemOne.getElement("mod_user_id");
			work_ymd = (String) itemOne.getElement("work_ymd");
			
			for (Iterator<String> params = itemOne.getElementNamesIterator(); params.hasNext(); ) {
				String name = params.next();
			       System.out.println(name + "=" + (String) itemOne.getElement( name ));
			}
			/*
			tz_cd=null
			pay_ym=202103
			sDelete=
			mod_date=null
			_seq=
			mod_user_id=6639947
			tz_date=null
			site_cd=123-81-15163
			pay_ymd_id=25659204
			locale_cd=KO
			sStatus=U
			company_cd=C
			give_ymd=20210314
			sqlId : PAY0088_01_R01
			workSpaceId : null
			companyCd : null
			*/
		}
		
		HashMap<String, Object> paramMap = null;
		
		try {
			////////////
			// 마감체크
			////////////
			paramMap = new HashMap<String, Object>();
			paramMap.put("pay_ymd_id"	, pay_ymd_id );
			invoker = new SQLInvoker( "PAY0088_01_R01" , paramMap );
			result 	= (GridResult) invoker.doService();
		
			if( result.next() ) {
				closeYn = result.getValueString(0); // result.getValueString("company_cd");
				pay_type_cd = result.getValueString("pay_type_cd");
				pay_ymd = result.getValueString("pay_ymd");
				pay_group = result.getValueString("pay_group");
				err_msg = result.getValueString("err_msg");

				System.out.println("closeYn:" + closeYn);
				System.out.println("pay_type_cd:" + pay_type_cd);
				System.out.println("pay_ymd:" + pay_ymd);
				System.out.println("pay_group:" + pay_group);
				System.out.println("err_msg:" + err_msg);
				System.out.println("========================================");
				if( !err_msg.equals("") ) {
					
					CommandExecuteException cee = new CommandExecuteException(err_msg);
					cee.setErrCode("ALERT_WORK_FAIL1");
					throw cee;
				}
			} else {
				
				CommandExecuteException cee = new CommandExecuteException("급여마감이 되지 않았습니다.");
				cee.setErrCode("ALERT_WORK_FAIL1");
				throw cee;
			}
			////////////
			// CT_IF_EHRDATA 삭제
			// 예수금이체를 실행하는 것같지않음.
			////////////
			if( company_cd.equals("C") || company_cd.equals("T") ) {
				paramMap = new HashMap<String, Object>();
				paramMap.put("give_ymd"	, pay_ymd );
				paramMap.put("site_cd"	, site_cd );
				paramMap.put("pay_type_cd"	, pay_type_cd );
				paramMap.put("pay_group"	, pay_group );
				invoker = new SQLInvoker( "PAY0088_01_D01" , paramMap );
				invoker.doService();
			}
			
			////////////
			// 파일순번 
			////////////
			System.out.println("================ 파일 순번 ========================");
			
			cb_conn = getConnection();

			PreparedStatement ps = null;
			ResultSet rs = null;
			String sql =  
				"SELECT COUNT(*) + 1 AS FILE_CNT\n" + 
				"  FROM CB2_PAY_PAY_H A\n" + 
				" WHERE A.SITE_CD = ?" + //:site_cd\n" + 
				"   AND A.FILE_GB = ?" + //:pay_type_cd\n" + 
				"   AND A.FILE_DATE = ?"; //:give_ymd";
			try {
				ps = cb_conn.prepareStatement(sql);
				ps.setString(1, site_cd);
				ps.setString(2, pay_type_cd);
				ps.setString(3, give_ymd);
				
				rs = ps.executeQuery();
				System.out.println(sql);
				if(rs.next()){
					file_cnt = rs.getString("file_cnt");
					System.out.println("File_Cnt:" + file_cnt);
				} else {
					CommandExecuteException cee = new CommandExecuteException("파일순번없음1(CB2_PAY_PAY_H).");
					throw cee;
				}
				rs.close();
			} catch(CommandExecuteException cee) {
				throw cee;
			} catch(Exception e) {
				e.printStackTrace();
				if ( cb_conn == null ) {
					CommandExecuteException cbE = new CommandExecuteException("CyberBranch DB에 접근할 수 없습니다.");
					throw cbE;
				}
				CommandExecuteException cee = new CommandExecuteException(e);
				cee.setErrCode("ALERT_WORK_FAIL1");
				throw cee;
			} finally {
				try{
					if(ps != null) ps.close();
					ps = null;
				}catch(Exception ee){
					CommandExecuteException cee = new CommandExecuteException("파일순번없음3.");
					cee.setErrCode("ALERT_WORK_FAIL1");
					throw cee;
				}
			}
			//////////////
			// 헤더정보 얻기 
			//////////////
			System.out.println("================ 헤더정보 ========================");
			paramMap = new HashMap<String, Object>();
			paramMap.put("pay_ymd_id"	, pay_ymd_id );
			invoker = new SQLInvoker( "PAY0088_01_R03" , paramMap );
			result 	= (GridResult) invoker.doService();
			String sum_cnt, sum_amt, trans_ymd, trans_hhmmss, flag, trans_kind;
			HashMap<String, Object> headerMap;
			String headSql = "INSERT CB2_PAY_PAY_H(\r\n" + 
					"					  SITE_CD --	사업장코드\r\n" + 
					"					, FILE_GB --	파일구분\r\n" + 
					"					, FILE_DATE --	파일생성일\r\n" + 
					"					, FILE_CNT --	회차\r\n" + 
					"					, FILE_NM --	파일이름\r\n" + 
					"					, SUM_CNT --	총건수\r\n" + 
					"					, SUM_AMT --	총금액\r\n" + 
					"					, ERP_GET_USER_ID --	등록자\r\n" + 
					"					, ERP_GET_DATE --	등록일\r\n" + 
					"					, ERP_GET_TIME --	등록시간\r\n" + 
					"					, FLAG --	파일상태\r\n" + 
					"				)\r\n" + 
					"VALUES(\r\n" + 
					"					  ? -- SITE_CD --	사업장코드\r\n" + 
					"					, ? -- FILE_GB --	파일구분\r\n" + 
					"					, ? -- FILE_DATE --	파일생성일\r\n" + 
					"					, ? -- FILE_CNT --	회차\r\n" + 
					"					, ? -- FILE_NM --	파일이름\r\n" + 
					"					, ? -- SUM_CNT --	총건수\r\n" + 
					"					, ? -- SUM_AMT --	총금액\r\n" + 
					"					, ? -- ERP_GET_USER_ID --	등록자\r\n" + 
					"					, ? -- ERP_GET_DATE --	등록일\r\n" + 
					"					, ? -- ERP_GET_TIME --	등록시간\r\n" + 
					"					, ? -- FLAG --	파일상태\r\n" + 
					"				)";
			String []headParam = {
					"site_cd",
					"file_gb",
					"file_date",
					"file_cnt",
					"file_nm",
					"sum_cnt",
					"sum_amt",
					"erp_get_user_id",
					"erp_get_date",
					"erp_get_time",
					"flag"
			};
			if( result.next() ) {
				sum_cnt = result.getValueString("sum_cnt");
				sum_amt = result.getValueString("sum_amt");
				trans_ymd = result.getValueString("trans_ymd");
				trans_hhmmss = result.getValueString("trans_hhmmss");
				flag = result.getValueString("flag");
				trans_kind = result.getValueString("trans_kind");
				System.out.println("sum_cnt=" + sum_cnt);
				System.out.println("sum_amt=" + sum_amt);
				System.out.println("trans_ymd=" + trans_ymd);
				System.out.println("trans_hhmmss=" + trans_hhmmss);
				System.out.println("flag=" + flag);
				System.out.println("trans_kind=" + trans_kind);
				
				headerMap = new HashMap<String, Object>();

				headerMap.put("site_cd", site_cd);
				headerMap.put("file_gb", pay_type_cd);
				headerMap.put("file_date", pay_ymd);
				headerMap.put("file_cnt", file_cnt);
				headerMap.put("file_nm", pay_group.substring(1, 4) + pay_type_cd + give_ymd + file_cnt);
				headerMap.put("sum_cnt", sum_cnt);
				headerMap.put("sum_amt", sum_amt);
				headerMap.put("erp_get_user_id", mod_user_id);
				headerMap.put("erp_get_date", trans_ymd);
				headerMap.put("erp_get_time", trans_hhmmss);
				headerMap.put("flag", flag);
				System.out.println(headerMap);

				//invoker = new SQLInvoker( "PAY0088_01_I01" , headerMap, cb_conn );
				//invoker.doService();
				try {
					ps = cb_conn.prepareStatement(headSql);
					for(int i=0; i < headParam.length; i++) {
						ps.setObject(i + 1, headerMap.get(headParam[i]));
					}
					ps.executeUpdate();
				} finally {
					if(ps != null) ps.close();
					ps = null;
				}
			} else {
				CommandExecuteException cee = new CommandExecuteException("전송할 자료가 없습니다.");
				cee.setErrCode("ALERT_WORK_FAIL1");
				throw cee;
			}

			//////////////
			// 상세정보 얻기 
			//////////////
			System.out.println("================ 상세정보 ========================");
			paramMap = new HashMap<String, Object>();
			paramMap.put("pay_ymd_id"	, pay_ymd_id );
			paramMap.put("company_cd"	, company_cd );
			paramMap.put("pay_type_cd"	, pay_type_cd );
			paramMap.put("give_ymd"	    , pay_ymd );
			paramMap.put("pay_group"	, pay_group );
			invoker = new SQLInvoker( "PAY0088_01_R04" , paramMap );
			result 	= (GridResult) invoker.doService();
			HashMap<String, Object> detailMap;
			String in_bank_cd, in_acct_no, real_amt, pre_reci_man, emp_no;
			String remark;
			String detailSql = "INSERT CB2_PAY_REQ_D( SITE_CD, --	사업장코드\r\n" + 
					"					FILE_GB, --	파일구분\r\n" + 
					"					FILE_DATE, --	파일생성일\r\n" + 
					"					FILE_CNT, --	파일회차\r\n" + 
					"					FILE_SEQ, --	SEQ\r\n" + 
					"					IN_BANK_CD, --	입금은행코드\r\n" + 
					"					IN_ACCT_NO, --	입금계좌번호\r\n" + 
					"					TRAN_AMT, --	이체금액\r\n" + 
					"					PRE_RECI_MAN, --	예상수취인명\r\n" + 
					"					PAY_GB, --	지급구분\r\n" + 
					"					REMARK, --	적요\r\n" + 
					"					ERP_REC_NO, --	ERP_REC_NO\r\n" + 
					"					ERP_DATE, --	ERP_DATE\r\n" + 
					"					ERP_TIME --	ERP_TIME\r\n" + 
					"					) VALUES ( ?, -- SITE_CD, --	사업장코드\r\n" + 
					"					?, -- FILE_GB, --	파일구분\r\n" + 
					"					?, -- FILE_DATE, --	파일생성일\r\n" + 
					"					?, -- FILE_CNT, --	파일회차\r\n" + 
					"					?, -- FILE_SEQ, --	SEQ\r\n" + 
					"					?, -- IN_BANK_CD, --	입금은행코드\r\n" + 
					"					?, -- IN_ACCT_NO, --	입금계좌번호\r\n" + 
					"					?, -- TRAN_AMT, --	이체금액\r\n" + 
					"					?, -- PRE_RECI_MAN, --	예상수취인명\r\n" + 
					"					?, -- PAY_GB, --	지급구분\r\n" + 
					"					?, -- REMARK, --	적요\r\n" + 
					"					?, -- ERP_REC_NO, --	ERP_REC_NO\r\n" + 
					"					?, -- ERP_DATE, --	ERP_DATE\r\n" + 
					"					? -- ERP_TIME --	ERP_TIME\r\n" + 
					"					)";
			String []detailParam = {
					"site_cd",
					"file_gb",
					"file_date",
					"file_cnt",
					"file_seq",
					"in_bank_cd",
					"in_acct_no",
					"tran_amt",
					"pre_reci_man",
					"pay_gb",
					"remark",
					"erp_rec_no",
					"erp_date",
					"erp_time"
			};
			detailMap = new HashMap<String, Object>();
			detailMap.put("site_cd", site_cd);
			detailMap.put("file_gb", pay_type_cd);
			detailMap.put("file_date", pay_ymd);
			detailMap.put("file_cnt", file_cnt);
			seq = 0;
			while( result.next() ) {
				in_bank_cd = result.getValueString("in_bank_cd");
				in_acct_no = result.getValueString("in_acct_no");
				real_amt = result.getValueString("real_amt");
				pre_reci_man = result.getValueString("pre_reci_man");
				emp_no = result.getValueString("emp_no");
				remark = result.getValueString("remark");
				System.out.print("in_bank_cd=" + in_bank_cd);
				System.out.print(",in_acct_no=" + in_acct_no);
				System.out.print(",real_amt=" + real_amt);
				System.out.print(",pre_reci_man=" + pre_reci_man);
				System.out.println(",emp_no=" + emp_no);
				
				seq = seq + 1;
				file_seq = String.valueOf(seq);
				
				detailMap.put("file_seq", file_seq);
				detailMap.put("in_bank_cd", in_bank_cd);
				detailMap.put("in_acct_no", in_acct_no);
				detailMap.put("tran_amt", real_amt);
				detailMap.put("pre_reci_man", pre_reci_man);
				detailMap.put("pay_gb", pay_type_cd);
				detailMap.put("remark", remark);
				detailMap.put("erp_rec_no", pay_ymd + emp_no);
				detailMap.put("erp_date", trans_ymd);
				detailMap.put("erp_time", trans_hhmmss);
				System.out.println(detailMap);
				
				try {
//					invoker = new SQLInvoker( "PAY0088_01_I02" , detailMap, cb_conn );
//					invoker.doService();
					ps = cb_conn.prepareStatement(detailSql);
					for(int i=0; i < detailParam.length; i++) {
						ps.setObject(i + 1, detailMap.get(detailParam[i]));
					}
					ps.executeUpdate();
				} finally {
					if(ps != null) ps.close();
					ps = null;
				}
				if( company_cd.equals("C") || company_cd.equals("T") ) {
					invoker = new SQLInvoker( "PAY0088_01_I03" , detailMap );
					invoker.doService();
				}
			}

		} catch(CommandExecuteException cee) {
			throw cee;
		} catch (Exception ex) {
			throw new CommandExecuteException( ex.getMessage() );
		} finally {
			try {
				System.out.println("Closing cb_conn!");
				if(cb_conn != null) cb_conn.close();
				cb_conn = null;
				System.out.println("Closed cb_conn!");
			} catch (SQLException e) {
				throw new CommandExecuteException( e.getMessage() );
			}
		}
		
		resContext.setResultType( ResponseContext.RESULT_TYPE_SUCCESS );
		System.out.println("================== KBPayTransferCommand END ======================");
		return resContext;
	}

}
