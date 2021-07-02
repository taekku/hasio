package h5.sap.dw.command;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Properties;

import com.sap.conn.jco.JCoDestination;
import com.sap.conn.jco.JCoDestinationManager;
import com.sap.conn.jco.JCoFunction;
import com.sap.conn.jco.JCoParameterList;
import com.sap.conn.jco.JCoTable;
import com.win.frame.invoker.GridResult;
import com.win.frame.invoker.Result;
import com.win.rf.invoker.SQLInvoker;

import h5.biz.ela.context.ElaRequestContext;
import h5.sap.inf.command.SapException;
import h5.sap.inf.provider.SapConnectionInfoProvider;
import h5.sys.command.AbsBusinessCommand;
import h5.sys.command.CommandExecuteException;
import h5.sys.context.IRequestContext;
import h5.sys.context.ResponseContext;
import h5.sys.message.IListBaseMessage;
import h5.sys.message.IMessageItem;
import h5.sys.util.LanguageUtil;

/**
 * SAP 공용 인터페이스 Command
 * 
 * param > 		company_cd		인사회사코드
 * 				p_bukrs			SAP회사코드
 * 				p_date			급여일
 * 				p_gubun			I(INSERT) , D( DELETE 후 INSERT)
 * 				pay_ymd_id		급여일자ID
 * 
 * 커멘드클래스명 : h5.sap.inf.command.DWSapRfcCommand
 * 
 * */
public class DWSapCommonRfcCommand extends AbsBusinessCommand {
	
	private final String ERROR_MSG_KEY = "FRM.ERRORMSG_0002";
	
	// 논리적인 명칭. 로그용 으로 사용 예정 ( SapConnectionInfoProvider.java와 공유함)
	private final static String destinationName = "PAY_SAP_INF";
	
	// H5 paramater 메세지명. 화면에서 JSON 구조로 전송
	private String PARAM_MESSAGE_NAME = "ME_PAY0099"; // SAP을 위한 메시지
	
	// SAP RFC 함수 명 . 
	private String functionModule = null; //"ZFI_EHR_PAY01"; 
	
	// 전송전 자료확인
	private String VALIDATION_SQL_ID = null;
	
	// parameter 조회용 SQL for SAP
	private String INPUT_PARAM_SQL_ID = null; //"PAY_SAP_TRANS_PARAM";
	
	// INPUT TABLE 용 SQL ID . 시스템관리 > 개발 및 수정작업 > SQL관리
	private String INPUT_TABLE_SQL_ID = null; //"PAY_SAP_TRANS";
	
	private String SAP_TABLE_ID = null; // "IT_PAY";
	
	// 전송후 후처리 SQL ID . 시스템관리 > 개발 및 수정작업 > SQL관리
	private String AFTER_SQL_ID = null; //"PAY_SAP_TRANS_UPT";
		
	@Override
	protected ResponseContext execute(IRequestContext requestContext) throws CommandExecuteException {

		SapConnectionInfoProvider.initConnection();
		ResponseContext rCtx = requestContext.getResponseContext();
		
		// Sap 전송
		try {
			rCtx = sendSap(requestContext);
		} catch (SapException sapException) {
			rCtx.setResultType(ResponseContext.RESULT_TYPE_ERROR);
			String message = sapException.getMessage();					
			rCtx.setResultMessage(message);
			sapException.setErrCode(message);
			throw sapException;
		} catch (CommandExecuteException comException) {
			rCtx.setResultType(ResponseContext.RESULT_TYPE_ERROR);
			String message = comException.getMessage();					
			rCtx.setResultMessage(message);
			comException.setErrCode(message);
			throw comException;
		}
		
		return rCtx;
	}
	protected ResponseContext sendSap( IRequestContext requestContext ) throws CommandExecuteException {

		ResponseContext resContext = requestContext.getResponseContext();
		
		SQLInvoker invoker	= null;
		GridResult result 	= null; 
		
		String companyCd 	= "";

		try {
			
			String locale_cd 	= requestContext.getSessionValue( "session_locale_cd" );
			
			// 1. 페이지에서 넘어온 parameter 를 처리한다.
			IListBaseMessage paramMessage = (IListBaseMessage) requestContext.getMessage( PARAM_MESSAGE_NAME );
			
			Iterator<IMessageItem> items = paramMessage.iterator();
			HashMap<String, Object> paramMap = new HashMap<String, Object>();
			
			if ( items.hasNext()) {
				
				IMessageItem itemOne = items.next();
				Iterator<String> iter =	itemOne.getElementNamesIterator();
				while(iter.hasNext()){
					String name = iter.next();
					String value = (String) itemOne.getElement(name);
					
					if ( name.equalsIgnoreCase("function_module") )
						functionModule 	= value;
					else if ( name.equalsIgnoreCase("VALIDATION_SQL_ID") )
						VALIDATION_SQL_ID = value;
					else if ( name.equalsIgnoreCase("INPUT_PARAM_SQL_ID") )
						INPUT_PARAM_SQL_ID = value;
					else if ( name.equalsIgnoreCase("INPUT_TABLE_SQL_ID") )
						INPUT_TABLE_SQL_ID 	= value;
					else if ( name.equalsIgnoreCase("SAP_TABLE_ID") )
						SAP_TABLE_ID 	= value;
					else if ( name.equalsIgnoreCase("AFTER_SQL_ID") )
						AFTER_SQL_ID 	= value;
					else if ( name.equalsIgnoreCase("company_cd") )
						companyCd 	= value;
					else 
						paramMap.put(name, value);

		        	System.out.println(name + " ===============> " + value);
				}
				
			}
			
	        paramMap.put( "company_cd"	, companyCd );
	        paramMap.put( "locale_cd"	, locale_cd );

	        if( VALIDATION_SQL_ID != null) {
		        invoker = new SQLInvoker( VALIDATION_SQL_ID , paramMap );
				result 	= (GridResult) invoker.doService();
				if ( result.next() ) { // 결과값이 있으면( 에러가 있으면 )
					String err_code = result.getValueString("err_code");
					if( !"000".equals(err_code) ) {
						String err_msg = result.getValueString("err_msg");
						System.out.println(err_code + "-"+ err_msg);
		        		CommandExecuteException cee = new CommandExecuteException( err_msg );
		        		cee.setErrCode( err_msg);
		        		throw cee;
					}
				}
	        }
	        
			
			invoker = new SQLInvoker( INPUT_PARAM_SQL_ID , paramMap );
			result 	= (GridResult) invoker.doService();
			if ( result.next() ) { // 파라미터를 구하면..
				System.out.println("================ DWSapCommandRfcCommand Start ================");
				System.out.println("================ " + functionModule + " ================");
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
				
//				paramList.setValue( "P_BUKRS"	, P_BUKRS ); 	// 회사코드 ( 시스템즈 : DS01)
//				paramList.setValue( "P_DATE"	, P_DATE );		// 급여일
//				paramList.setValue( "P_GUBUN"	, P_GUBUN );	// I(INSERT) , D( DELETE 후 INSERT)
		        System.out.println( function.getTableParameterList().toXML() );
		        JCoTable IT_PAY = function.getTableParameterList().getTable( SAP_TABLE_ID );
		        /**
		         SAP 테이블 구조는   INPUT_TABLE_SQL_ID결과에 따라서
		         **/
		        
		        invoker = null;
		        result 	= null;
		        
		        // 4. SQL 을 실행하여 INPUT TABLE 을 설정한다.
		        invoker = new SQLInvoker( INPUT_TABLE_SQL_ID , paramMap );
		        result 	= (GridResult) invoker.doService();
		        
		        if( result.getRowCount() > 0 ) {
		        	System.out.println("============ Begin of " + SAP_TABLE_ID + " ============" );
			        while( result.next() ) {
				        
			        	IT_PAY.appendRow();
			        	
			        	colCount = result.getColumnCount();
			        	
			        	for ( int i = 0 ; i < colCount ; i++ ) {
			        		
			        		String columnName 	= result.getTitleValue( i );
			        		String colValue 	= result.getValueString( i );
			        		
			        		// 칼럼명을 대문자로 한다.
			        		IT_PAY.setValue( columnName.toUpperCase() , colValue );
			        		if( i > 0 )
			        			System.out.print("|");
			        		System.out.print(colValue);
			        	}
			        	System.out.println();
			        }
		        	System.out.println("============ End of " + SAP_TABLE_ID + " ============" );
		        } else {
		        	//throw new SapException(functionModule + "의 전송Table이 없습니다.");
		        	System.out.println(functionModule + "의 전송Table이 없습니다.");
		        }
		        
		        // 5. 함수를 실행한다.
		        function.execute( DES_ABAP_AS );
		        
		        // 6. 실행한 결과 테이블을 받아온다.
		        //System.out.println( function.getTableParameterList().toXML() );
		        JCoTable RETURN = function.getTableParameterList().getTable( "RETURN" );
		        // System.out.println(RETURN.toXML());
		        /*
		         RETURN 테이블 구조
		         
		         TYPE		메시지 유형
		         ID
		         NUMBER
		         MESSAGE	메시지 텍스트
		         
		         * */
	
		        // 7. 결과에 대한 처리를 한다.
	        	RETURN.setRow( 0 );
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
		        if( AFTER_SQL_ID != null ) {
	        		invoker = new SQLInvoker(AFTER_SQL_ID, paramMap);
	        		//rs = invoker.doService();
	        		invoker.doService();
	                invoker = null;
	                System.out.println(functionModule + "의 " + AFTER_SQL_ID + "를 성공적으로 업데이트 하였습니다.");
	                //return true;
		        }

		        System.out.println("[" + functionModule +  "] 성공했습니다");
			} else {
				throw new SapException("파라메터를 구할수없습니다." + INPUT_PARAM_SQL_ID );
			}
		} catch (SapException ex) {
			resContext.setResultType(ResponseContext.RESULT_TYPE_ERROR);
			String message = ex.getMessage();					
			resContext.setResultMessage(message);
			ex.printStackTrace();
			throw new CommandExecuteException( ex.getMessage() );
		} catch (Exception ex) {
			resContext.setResultType(ResponseContext.RESULT_TYPE_ERROR);
			String message = ex.getMessage();					
			resContext.setResultMessage(message);
			ex.printStackTrace();
			throw new CommandExecuteException( ex.getMessage() );
		} finally {
			System.out.println("================ DWSapCommandRfcCommand End ================");
		}
		
		resContext.setResultType( ResponseContext.RESULT_TYPE_SUCCESS );
		
		return resContext;
	}
}
