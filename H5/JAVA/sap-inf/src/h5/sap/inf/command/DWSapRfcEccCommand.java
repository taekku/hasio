package h5.sap.inf.command;

import java.util.HashMap;

import com.sap.conn.jco.JCoDestination;
import com.sap.conn.jco.JCoDestinationManager;
import com.sap.conn.jco.JCoException;
import com.sap.conn.jco.JCoFunction;
import com.sap.conn.jco.JCoParameterList;
import com.sap.conn.jco.JCoRuntimeException;
import com.sap.conn.jco.JCoTable;
import com.win.frame.invoker.GridResult;
import com.win.rf.invoker.SQLInvoker;

import h5.biz.ela.context.ElaRequestContext;
import h5.ela.command.ElaServiceCommand;
import h5.sap.inf.provider.SapConnectionInfoProvider;
import h5.sys.command.CommandExecuteException;
import h5.sys.context.IRequestContext;
import h5.sys.context.ResponseContext;

/**
 * SAP 경조금 인터페이스 Command
 * 
 * param > 		
 * 
 * 커멘드클래스명 : h5.sap.inf.command.DWSapRfcEccCommand
 * 
 * */
public class DWSapRfcEccCommand extends ElaServiceCommand {

	// 논리적인 명칭. 로그용 으로 사용 예정 ( SapConnectionInfoProvider.java와 공유함)
	private String destinationName = "PAY_SAP_INF";
	
	// H5 paramater 메세지명. 화면에서 JSON 구조로 전송
	private String PARAM_MESSAGE_NAME = "ME_ECC0099";
	
	// SAP RFC 함수 명 .
	private String functionModule = "ZFI_EHR_GJ01"; 
	
	// parameter 조회용 SQL
	final private String INPUT_PARAM_SQL_ID = "ECC_SAP_TRANS_PARAM";
	
	// INPUT TABLE 용 SQL ID . 시스템관리 > 개발 및 수정작업 > SQL관리
	final private String INPUT_TABLE_SQL_ID = "ECC_SAP_TRANS";
	
	// 전송후 후처리 SQL ID . 시스템관리 > 개발 및 수정작업 > SQL관리
	final private String AFTER_SQL_ID = "ECC_SAP_TRANS_UPT";
	
	@Override
	protected ResponseContext execute(IRequestContext requestContext) throws CommandExecuteException {
		SapConnectionInfoProvider.initConnection();
		ResponseContext rCtx = super.execute(requestContext);
		
		// Sap 전송
		try {
			sendSap((ElaRequestContext)requestContext);
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
		
		return rCtx;
	}
	protected boolean sendSap(ElaRequestContext requestContext) throws CommandExecuteException {
		String applId = requestContext.getApplId();
		String applCd = requestContext.getApplCd();
		String applStatus = requestContext.getApplStatus();
		System.out.println("결재요청:" + applId + ":" + applCd + ":" + applStatus);
		if( !applStatus.equals("132") )
			return true;
		SQLInvoker invoker	= null;
		GridResult result 	= null;
		try {
			// 결재문서의 상태값을 얻어서 SAP전송여부확인
			
			String locale_cd 	= requestContext.getSessionValue( "session_locale_cd" );
			String companyCd 	= requestContext.getSessionValue( "session_company_cd" );
			String P_EBELN		= null;
			String ACC_NO		= null; // 전표번호
	        
	        HashMap<String, Object> paramMap = new HashMap<String, Object>();
	        paramMap.put("appl_id"	, applId );
	        paramMap.put("locale_cd", locale_cd );
	        paramMap.put("stat_cd"  , "132"); // 결재완료인 경우만
	        invoker = new SQLInvoker( INPUT_PARAM_SQL_ID , paramMap );
			result 	= (GridResult) invoker.doService();
			if( result.next() ) {
				
				companyCd = result.getValueString(0); // result.getValueString("company_cd");
				paramMap.put("company_cd", companyCd);
				
				System.out.println("company_cd:" + companyCd + "====>");

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

					int colCount = result.getColumnCount();
		        	
		        	for ( int i = 1 ; i < colCount ; i++ ) {
		        		
		        		String columnName 	= result.getTitleValue( i );
		        		String colValue 	= result.getValueString( i );
		        		
		        		// 칼럼명을 대문자로 한다.
		        		paramList.setValue( columnName.toUpperCase() , colValue );
		        		System.out.println(columnName.toUpperCase() + "=" + colValue);
		        	}
		        
		        JCoTable IT_IMPORT = function.getTableParameterList().getTable( "IT_IMPORT" );
		        /*
		         IT_IMPORT 테이블 구조 
		         
		         GL_ACCOUNT			총계정원장 계정
		         POSITION_TEXT		적요
		         KOSTL				코스트센터
		         WRBTR				금액
		         * */
		        
		        invoker = null;
		        result 	= null;
		        
		        // 4. SQL 을 실행하여 INPUT TABLE 을 설정한다.
//		        System.out.println("QUERY_ID=" + INPUT_TABLE_SQL_ID);
//		        System.out.println("");
		        invoker = new SQLInvoker( INPUT_TABLE_SQL_ID , paramMap );
		        result 	= (GridResult) invoker.doService();
//		        System.out.println("조회건수:");
//		        System.out.println(result.getRowCount());
//		        System.out.println(paramMap);
//		        System.out.println(paramMap);
		        if( result.getRowCount() <= 0 ) {
		        	CommandExecuteException cee = new CommandExecuteException("전송할 자료가 없습니다.");
					cee.setErrCode("ALERT_WORK_FAIL1");
					throw cee;
		        }
		        while( result.next() ) {
		        
		        	IT_IMPORT.appendRow();
		        	
		        	int colCount1 = result.getColumnCount();
		        	
		        	for ( int i = 0 ; i < colCount1 ; i++ ) {
		        		
		        		String columnName 	= result.getTitleValue( i );
		        		String colValue 	= result.getValueString( i );
		        		
		        		// 칼럼명을 대문자로 한다.
		        		IT_IMPORT.setValue( columnName.toUpperCase() , colValue );
		        		System.out.println(columnName.toUpperCase() + "=" + colValue);
		        	}
		        }
		        
		        // 5. 함수를 실행한다.
		        function.execute( DES_ABAP_AS );
		        
		        // 6. 실행한 결과 테이블을 받아온다.
		        System.out.println( function.getTableParameterList().toXML() );
		        JCoTable RETURN = function.getTableParameterList().getTable( "RETURN" );
		        JCoTable IT_RESULT = function.getTableParameterList().getTable( "IT_RESULT" );
		        System.out.println(RETURN.toXML());
		        System.out.println(IT_RESULT.toXML());
		        /*
		         RETURN 테이블 구조
		         
		         TYPE		메시지 유형
		         ID
		         NUMBER
		         MESSAGE	메시지 텍스트
		         
		         * */

		        // 7. 결과에 대한 처리를 한다.
		        //System.out.println("레코드갯수:" + RETURN.)
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

        		// 8. 전표번호 업데이트 --전송 후 전송일자 업데이트
        		//Result rs = null;
		        IT_RESULT.firstRow();
		        if( 0 < IT_RESULT.getNumRows() ) {
		        	IT_RESULT.setRow(0);
		        	ACC_NO = IT_RESULT.getString( "DOCNUMBER" );
	        		paramMap.put("acc_no", ACC_NO); // 전표번호Update
	        		invoker = new SQLInvoker(AFTER_SQL_ID, paramMap);
	        		//rs = invoker.doService();
	        		invoker.doService();
	                invoker = null;
	                System.out.println("IT_RESULT ECC전표번호:" + ACC_NO);
	                return true;
		        } else {
	        		CommandExecuteException cee = new CommandExecuteException( "SAP Error: 전표번호를 구할 수 없습니다.");
	        		cee.setErrCode(  "SAP Error: 전표번호를 구할 수 없습니다.");
	        		throw cee;
		        }
			} else {
				System.out.println("SAPTEST:전표미생성");
				System.out.println("applId:" + applId);
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
		return true;
	}

}
