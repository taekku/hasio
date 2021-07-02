package h5.sap.inf.command;

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

import h5.sap.inf.provider.SapConnectionInfoProvider;
import h5.sys.command.AbsBusinessCommand;
import h5.sys.command.CommandExecuteException;
import h5.sys.context.IRequestContext;
import h5.sys.context.ResponseContext;
import h5.sys.message.IListBaseMessage;
import h5.sys.message.IMessageItem;

/**
 * SAP 급여전표 인터페이스 Command
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
public class DWSapRfcCommand extends AbsBusinessCommand {
	
	// 논리적인 명칭. 로그용 으로 사용 예정 ( SapConnectionInfoProvider.java와 공유함)
	private final static String destinationName = "PAY_SAP_INF";
	
	// H5 paramater 메세지명. 화면에서 JSON 구조로 전송
	private String PARAM_MESSAGE_NAME = "ME_PAY0099";
	
	// SAP RFC 함수 명 . 
	private String functionModule = "ZFI_EHR_PAY01"; 
	
	// parameter 조회용 SQL
//	private String INPUT_PARAM_SQL_ID = "PAY_SAP_TRANS_PARAM";
	
	// INPUT TABLE 용 SQL ID . 시스템관리 > 개발 및 수정작업 > SQL관리
	private String INPUT_TABLE_SQL_ID = "PAY_SAP_TRANS";
	
	// 전송후 후처리 SQL ID . 시스템관리 > 개발 및 수정작업 > SQL관리
	private String AFTER_SQL_ID = "PAY_SAP_TRANS_UPT";
		
	@Override
	protected ResponseContext execute( IRequestContext requestContext ) throws CommandExecuteException {

		ResponseContext resContext = requestContext.getResponseContext();
		SapConnectionInfoProvider.initConnection();
		
		SQLInvoker invoker	= null;
		GridResult result 	= null; 
		
		String companyCd 	= "";
		String pay_type_cd	= "";
		String pay_date 	= "";
		String emp_no		= "";
		
		String P_BUKRS 		= ""; 	// 회사코드 ( 시스템즈 : DS01)
		String P_DATE 		= ""; 	// 급여일
		String P_GUBUN 		= "";  	// I(INSERT) , D( DELETE 후 INSERT)

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
				pay_type_cd = (String) itemOne.getElement( "pay_type_cd" );
				pay_date 	= (String) itemOne.getElement( "pay_date" );
				emp_no 		= (String) itemOne.getElement( "emp_no" );
				
				P_BUKRS 	= (String) itemOne.getElement( "p_bukrs" );
				P_DATE 		= (String) itemOne.getElement( "p_date" );
				P_GUBUN 	= (String) itemOne.getElement( "p_gubun" );
			}
			
			HashMap<String, Object> paramMap = new HashMap<String, Object>();
	        paramMap.put( "company_cd"	, companyCd );
	        paramMap.put( "locale_cd"	, locale_cd );
	        paramMap.put( "pay_type_cd"	, pay_type_cd );
	        paramMap.put( "pay_date"	, pay_date );
	        paramMap.put( "emp_no"		, emp_no );
	        
			paramMap.put( "P_BUKRS"		, P_BUKRS );
			paramMap.put( "P_DATE"		, P_DATE );
			paramMap.put( "P_GUBUN"		, P_GUBUN );
			
			

			System.out.println("functionModule ===============> " + functionModule);
        	System.out.println("company_cd ===============> " + companyCd);
        	System.out.println("locale_cd ===============> " + locale_cd);
        	System.out.println("pay_type_cd ===============> " + pay_type_cd);
        	System.out.println("pay_date ===============> " + pay_date);
        	System.out.println("emp_no ===============> " + emp_no);
        	System.out.println("P_BUKRS ===============> " + P_BUKRS);
        	System.out.println("P_DATE ===============> " + P_DATE);
        	System.out.println("P_GUBUN ===============> " + P_GUBUN);
        	
			
			
//			invoker = new SQLInvoker( INPUT_PARAM_SQL_ID , paramMap );
//			result 	= (GridResult) invoker.doService();
//			
//			if ( result.next() ) {
//				
//				P_BUKRS = result.getValueString("P_BUKRS".toLowerCase());
//				P_DATE 	= result.getValueString("P_DATE".toLowerCase());
//				P_GUBUN = result.getValueString("P_GUBUN".toLowerCase());
//				
//				paramMap.put( "P_BUKRS".toLowerCase() 	, P_BUKRS );
//				paramMap.put( "P_DATE".toLowerCase() 	, P_DATE );
//				paramMap.put( "P_GUBUN".toLowerCase() 	, P_GUBUN );
//			}
			
			
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

	        try {
	        	JCoTable IT_RESULT = function.getTableParameterList().getTable( "IT_RESULT" );
		        if( IT_RESULT != null )
		        	System.out.println(IT_RESULT.toXML());
	        } catch (Exception e) {
	        	System.out.println("IT_RESULT가 없습니다.");
	        }
	        JCoTable RETURN = function.getTableParameterList().getTable( "RETURN" );
	        System.out.println(RETURN.toXML());
	        /*
	         RETURN 테이블 구조
	         
	         TYPE		메시지 유형
	         ID
	         NUMBER
	         MESSAGE	메시지 텍스트
	         
	         * */

	        // 7. 결과에 대한 처리를 한다.
        	RETURN.setRow( 0 );
        	
        	String TYPE 	= RETURN.getString( "TYPE" );
        	String MESSAGE 	= RETURN.getString( "MESSAGE" );
        	
        	System.out.println("TYPE : " + TYPE);
        	System.out.println("MESSAGE : " + MESSAGE);
        	
        	// S 성공
        	// E 오류
        	// W 경고
        	// I 정보
        	// A 중단
        	
        	if ( "E".equals(TYPE)) {
        		
        		throw new SapException( MESSAGE );
        		
        	} else {
        		// 전송 후 전송일자 업데이트
        		Result rs = null;
        		invoker = new SQLInvoker(AFTER_SQL_ID, paramMap);
        		rs = invoker.doService();
                invoker = null;
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
		}
		
		resContext.setResultType( ResponseContext.RESULT_TYPE_SUCCESS );
		
		return resContext;
	}
}
