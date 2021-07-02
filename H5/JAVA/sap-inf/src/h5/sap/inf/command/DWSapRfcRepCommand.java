package h5.sap.inf.command;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Properties;

import com.sap.conn.jco.JCoDestination;
import com.sap.conn.jco.JCoDestinationManager;
import com.sap.conn.jco.JCoException;
import com.sap.conn.jco.JCoFunction;
import com.sap.conn.jco.JCoParameterList;
import com.sap.conn.jco.JCoRuntimeException;
import com.sap.conn.jco.JCoTable;
import com.win.frame.invoker.GridResult;
import com.win.frame.invoker.Result;
import com.win.rf.invoker.SQLInvoker;

import h5.sap.inf.provider.SapConnectionInfoProvider;
import h5.sys.command.AbsBusinessCommand;
import h5.sys.command.CommandExecuteException;
import h5.sys.context.IRequestContext;
import h5.sys.context.ResponseContext;
import h5.sys.message.IListBaseMessage;
import h5.sys.message.IMessageItem;

/**
 * SAP 퇴직자전표 인터페이스 Command
 * 
 * param > 		company_cd		인사회사코드
 * 				p_bukrs			SAP회사코드
 * 				p_date			급여일
 * 				p_gubun			I(INSERT) , D( DELETE 후 INSERT)
 * 				pay_ymd_id		급여일자ID
 * 
 * 커멘드클래스명 : h5.sap.inf.command.DWSapRfcRepCommand
 * 
 * */
public class DWSapRfcRepCommand extends AbsBusinessCommand {

	
	// 논리적인 명칭. 로그용 으로 사용 예정 ( SapConnectionInfoProvider.java와 공유함)
	private String destinationName = "PAY_SAP_INF";
	
	// H5 paramater 메세지명. 화면에서 JSON 구조로 전송
	private String PARAM_MESSAGE_NAME = "ME_REP0099_01";
	
	// SAP RFC 함수 명 . 
	private String functionModule = "ZFI_EHR_PAY01"; 
	
	// parameter 조회용 SQL
	private String INPUT_PARAM_SQL_ID = "PAY_SAP_TRANS_PARAM";
	
	// INPUT TABLE 용 SQL ID . 시스템관리 > 개발 및 수정작업 > SQL관리
	private String INPUT_TABLE_SQL_ID = "PAY_SAP_TRANS";
	
	// 전송후 후처리 SQL ID . 시스템관리 > 개발 및 수정작업 > SQL관리
	private String AFTER_SQL_ID = "PAY_SAP_TRANS_UPT";
	
	// 전송후 후처리 SQL ID . 시스템관리 > 개발 및 수정작업 > SQL관리
	private String AFTER_PROC_ID = null;
		
	
	
	@Override
	protected ResponseContext execute(IRequestContext requestContext) throws CommandExecuteException {
//		ResponseContext rCtx = super.execute(requestContext);
		ResponseContext rCtx = requestContext.getResponseContext();
		
		// Sap 전송
		// Sap 전송
		try {
			sendSap(requestContext);
		} catch (SapException sapException) {
			rCtx.setResultType(ResponseContext.RESULT_TYPE_ERROR);
			String message = sapException.getMessage();					
			rCtx.setResultMessage(message);
			throw sapException;
		} catch (CommandExecuteException comException) {
			rCtx.setResultType(ResponseContext.RESULT_TYPE_ERROR);
			String message = comException.getMessage();					
			rCtx.setResultMessage(message);
			throw comException;
		}

		rCtx.setResultType( ResponseContext.RESULT_TYPE_SUCCESS );
		return rCtx;
	}
	
	protected boolean sendSap(IRequestContext requestContext) throws CommandExecuteException {
		SapConnectionInfoProvider.initConnection();
		
		SQLInvoker invoker	= null;
		GridResult result 	= null; 
		
		String companyCd 	= "";
		String rep_calc_list_id	= "";
		String mod_user_id 	= "";
		String acct_type = "";
		
		String P_BUKRS 		= ""; 	// 회사코드 ( 시스템즈 : DS01)
		String P_DATE 		= ""; 	// 급여일
		String P_GUBUN 		= "";  	// I(INSERT) , D( DELETE 후 INSERT)
		
		String FILLDT = "";
		String FILLNO = "";

		try {
			
//
			// Register the MyDestinationDataProvider environment registration
//			if ( !Environment.isDestinationDataProviderRegistered()){
//				Environment.registerDestinationDataProvider(myProvider);
//			}
			
			Properties connectProperties = new Properties();
			
			String locale_cd 	= requestContext.getSessionValue( "session_locale_cd" );
			
			// 1. 페이지에서 넘어온 parameter 를 처리한다.
			IListBaseMessage paramMessage = (IListBaseMessage) requestContext.getMessage( PARAM_MESSAGE_NAME );
			
			Iterator<IMessageItem> items = paramMessage.iterator();
			
			if ( items.hasNext()) {
				
				IMessageItem itemOne = items.next();

				companyCd 	= (String) itemOne.getElement( "company_cd" );
				locale_cd	= (String) itemOne.getElement( "locale_cd" );
				INPUT_PARAM_SQL_ID = (String) itemOne.getElement("INPUT_PARAM_SQL_ID");
				INPUT_TABLE_SQL_ID = (String) itemOne.getElement("INPUT_TABLE_SQL_ID");
				AFTER_SQL_ID = (String) itemOne.getElement("AFTER_SQL_ID");
				AFTER_PROC_ID = (String) itemOne.getElement("AFTER_PROC_ID");
				rep_calc_list_id 	= (String) itemOne.getElement( "rep_calc_list_id" );
				acct_type 	= (String) itemOne.getElement( "acct_type" );
				mod_user_id 		= (String) itemOne.getElement( "mod_user_id" );
				System.out.println("mod_user_id:" + mod_user_id);
				
				P_BUKRS 	= (String) itemOne.getElement( "p_bukrs" );
				P_DATE 		= (String) itemOne.getElement( "p_date" );
				P_GUBUN 	= (String) itemOne.getElement( "p_gubun" );
			}
			
			HashMap<String, Object> paramMap = new HashMap<String, Object>();
	        paramMap.put( "company_cd"	, companyCd );
	        paramMap.put( "locale_cd"	, locale_cd );
	        paramMap.put( "rep_calc_list_id"	, rep_calc_list_id );
	        paramMap.put( "acct_type", acct_type);
	        paramMap.put( "mod_user_id", mod_user_id);
	        
			paramMap.put( "P_BUKRS"		, P_BUKRS );
			paramMap.put( "P_DATE"		, P_DATE );
			paramMap.put( "P_GUBUN"		, P_GUBUN );
			
			

        	System.out.println("company_cd ===============> " + companyCd);
        	System.out.println("locale_cd ===============> " + locale_cd);
        	System.out.println("rep_calc_list_id ===============> " + rep_calc_list_id);
//        	System.out.println("P_BUKRS ===============> " + P_BUKRS);
//        	System.out.println("P_DATE ===============> " + P_DATE);
//        	System.out.println("P_GUBUN ===============> " + P_GUBUN);
        	System.out.println("INPUT_PARAM_SQL_ID ===============> " + INPUT_PARAM_SQL_ID);
        	System.out.println("INPUT_TABLE_SQL_ID ===============> " + INPUT_TABLE_SQL_ID);
        	System.out.println("AFTER_SQL_ID ===============> " + AFTER_SQL_ID);
        	System.out.println("AFTER_PROC_ID ===============> " + AFTER_PROC_ID);
			
			
			invoker = new SQLInvoker( INPUT_PARAM_SQL_ID , paramMap );
			result 	= (GridResult) invoker.doService();
			
			if ( result.next() ) {
				
				FILLDT = result.getValueString("FILLDT".toLowerCase());
				FILLNO 	= result.getValueString("FILLNO".toLowerCase());
				//P_BUKRS = result.getValueString("COMPANY_CD".toLowerCase());
				P_BUKRS = result.getValueString("P_BUKRS".toLowerCase());
				P_DATE 	= FILLDT;
				P_GUBUN = "I";
				
				paramMap.put( "P_BUKRS".toLowerCase() 	, P_BUKRS );
				paramMap.put( "P_DATE".toLowerCase() 	, P_DATE );
				paramMap.put( "P_GUBUN".toLowerCase() 	, P_GUBUN );
				
				paramMap.put( "filldt", FILLDT);
				paramMap.put( "fillno", FILLNO);
			} else {
				String message = "전송정보를 얻을 수 없습니다.(00_R03)";
        		CommandExecuteException cee = new CommandExecuteException( "H5 Message : " + message );
        		cee.setErrCode( "H5 Message : " + message);
        		throw cee;
			}
			
			
			// Get a destination
			JCoDestination DES_ABAP_AS = JCoDestinationManager.getDestination( destinationName + "_" + companyCd );
			// Test the destination with the name of "ABAP_AS"

			//DES_ABAP_AS.ping();
			//System.out.println("Destination - " + destinationName + " is ok");
			
			// 3. JCO 함수를 가져온다.
			JCoFunction function = DES_ABAP_AS.getRepository().getFunction( functionModule ); 
			  
			if (function == null) { 
				
				throw new RuntimeException("<"+functionModule+"> not found in SAP.");
			}
			
			JCoParameterList paramList = function.getImportParameterList();	 
			
			paramList.setValue( "P_BUKRS"	, P_BUKRS ); 	// 회사코드 ( 시스템즈 : DS01)
			paramList.setValue( "P_DATE"	, P_DATE );		// 급여일
			paramList.setValue( "P_GUBUN"	, P_GUBUN );	// I(INSERT) , D( DELETE 후 INSERT)
			
			System.out.println("P_BUKRS=" + P_BUKRS);
			System.out.println("P_DATE=" + P_DATE);
			System.out.println("P_GUBUN=" + P_GUBUN);
	        
	        JCoTable IT_PAY = function.getTableParameterList().getTable( "IT_PAY" );
	        /*
	         IT PAY 테이블 구조 
	         
	         CD_COMPANY			회사코드
	         SEQNO_S			급여 항목별 관리번호
	         DRAW_DATE			급여일
	         SNO				사원번호
	         SAP_ACCTCODE		계정번호
	         SEQ				순번
	         ACCT_TYPE			인사전표유형
	         MANDT_S			
	         GSBER_S			사업영역
	         LIFNR_S			공급업체 또느 채권자의 계정 번호
	         ZPOSN_S			직급텍스트
	         SNM			
	         COST_CENTER		코스트센터
	         AMT				전표금액
	         DBCR_GU			개별항목의 전기키
	         FLAG
	         PAY_YM				년월
	         PAY_DATE			급여일
	         PAY_SUPP
	         ITEM_CODE			아이템코드
	         PAYGP_CODE			급여그룹 코드
	         IFC_SORT
	         SLIP_DATE
	         REMARK				Remark
	         XNEGP				마이너스 전기 지시자
	         ACCNT_CD			
	         SEQ_H				급여헤더 Sequence
	         GUBUN				구분	
	         
	         * */
	        
	        invoker = null;
	        result 	= null;
	        
	        // 4. SQL 을 실행하여 INPUT TABLE 을 설정한다.
	        System.out.println("INPUT_TABLE_SQL_ID:" + INPUT_TABLE_SQL_ID);
	        System.out.println(paramMap);
	        invoker = new SQLInvoker( INPUT_TABLE_SQL_ID , paramMap );
	        result 	= (GridResult) invoker.doService();
	        
	        while( result.next() ) {
	        
	        	IT_PAY.appendRow();
	        	
	        	int colCount = result.getColumnCount();
	        	
	        	for ( int i = 0 ; i < colCount ; i++ ) {
	        		
	        		String columnName 	= result.getTitleValue( i );
	        		String colValue 	= result.getValueString( i );
	        		
	        		// 칼럼명을 대문자로 한다.
	        		IT_PAY.setValue( columnName.toUpperCase() , colValue );
	        	}
	        }
	        
	        // 5. 함수를 실행한다.
	        function.execute( DES_ABAP_AS );
	        
	        // 6. 실행한 결과 테이블을 받아온다.
	        System.out.println( function.getTableParameterList().toXML() );
	        JCoTable RETURN = function.getTableParameterList().getTable( "RETURN" );
	        /*
	         RETURN 테이블 구조
	         
	         TYPE		메시지 유형
	         ID
	         NUMBER
	         MESSAGE	메시지 텍스트
	         
	         * */

	        // 7. 결과에 대한 처리를 한다.
	        RETURN.firstRow();
	        for(int i=0 ; i < RETURN.getNumRows(); i++) {
	        	RETURN.setRow( i );
	        	
	        	String TYPE 	= RETURN.getString( "TYPE" );
	        	String MESSAGE 	= RETURN.getString( "MESSAGE" );
	        	
	        	 System.out.println("row : " + i);
	        	 System.out.println("TYPE : " + TYPE);
	        	 System.out.println("MESSAGE : " + MESSAGE);		        	
	        	// S 성공
	        	// E 오류
	        	// W 경고
	        	// I 정보
	        	// A 중단
	        	
	        	if ( "E".equals(TYPE)) {
	        		CommandExecuteException cee = new CommandExecuteException( "SAP Message : " + MESSAGE );
	        		cee.setErrCode( "SAP Message : " + MESSAGE);
	        		throw cee;
	        	}
	        }
        	
        	// S 성공
        	// E 오류
        	// W 경고
        	// I 정보
        	// A 중단
        	
        	
        		// 전송 후 전송일자 업데이트
        		Result rs = null;
        		invoker = new SQLInvoker(AFTER_SQL_ID, paramMap);
        		//rs = invoker.doService();
        		invoker.doService();
                invoker = null;
                
                if( AFTER_PROC_ID == null || AFTER_PROC_ID.equals("") ){
                } else {
            		invoker = new SQLInvoker(AFTER_PROC_ID, paramMap);
            		invoker.doService();
                    invoker = null;
                }

		} catch (JCoException sapE) {
    		CommandExecuteException cee = new CommandExecuteException(sapE.getMessage());
    		cee.setErrCode( sapE.getMessage() );
    		throw cee;
		} catch (JCoRuntimeException sapE) {
			CommandExecuteException cee = new CommandExecuteException(sapE.getMessage());
			cee.setErrCode( sapE.getMessage() );
			throw cee;
		} catch (SapException sapE) {
			sapE.printStackTrace();
			throw sapE;
		} catch (CommandExecuteException ceE) {
			ceE.printStackTrace();
			throw ceE;
		} catch (Exception e) {
			e.printStackTrace();
			CommandExecuteException cee = new CommandExecuteException("SAP전송중 에러발생",e);
			cee.setErrCode("ALERT_WORK_FAIL1");
			throw cee;
		}
		
//		ResponseContext resContext = requestContext.getResponseContext();
//		resContext.setResultType( ResponseContext.RESULT_TYPE_SUCCESS );
		
		return true;
	}
}
