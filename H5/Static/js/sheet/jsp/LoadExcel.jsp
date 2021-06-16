<%@page import="com.fasoo.adk.packager.*"%>
<%@ page language="java" contentType="text/html;charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.io.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.ibleaders.ibsheet7.ibsheet.excel.LoadExcel" %>
<%@ page import="com.ibleaders.ibsheet7.util.LoadExcelCallbackInterface" %>
<%@ page import="com.ibleaders.ibsheet7.util.Synchronizer" %>
<%@ page import="com.ibleaders.ibsheet7.util.IBPacketParser" %>
<%@ page import="java.net.InetAddress" %>
<%@ page import="h5.servlet.util.IBSheetLoadExcelCallback" %>
<%!
public  static String FileTypeStr(int i) {
	String ret = null;
	switch(i) {
    	case 20 : ret = "파일을 찾을 수 없습니다."; break;
    	case 21 : ret = "파일 사이즈가 0 입니다.";  break;
    	case 22 : ret = "파일을 읽을 수 없습니다."; break;
    	case 29 : ret = "암호화 파일이 아닙니다.";  break;
    	case 26 : ret = "FSD 파일입니다.";       	break;
    	case 105: ret = "Wrapsody 파일입니다.";  	break;
    	case 106: ret = "NX 파일입니다.";			break;	    	
    	case 101: ret = "MarkAny 파일입니다.";   	break;
    	case 104: ret = "INCAPS 파일입니다.";    	break;
    	case 103: ret = "FSN 파일입니다.";       	break;
	}
	return ret;		
}
%>
<%

	out.clear();
    out = pageContext.pushBody();

	LoadExcel ibExcel = new LoadExcel();
	ibExcel.setService(request, response);

	//System.out.println(com.ibleaders.ibsheet7.util.Version.getVersion());

    //====================================================================================================
    // [ 사용자 환경 설정 #1 ]
    //====================================================================================================
    // Html 페이지의 인코딩이 UTF-8 로 구성되어 있으면 "ibExcel.setPageEncoding("UTF-8")" 로 설정하십시오.
    // 한글 헤더가 있는 그리드에서 엑셀 로딩이 동작하지 않으면 이 값을 바꿔 보십시오.
    // Down2Excel.jsp 에서의 설정값과 동일하게 바꿔주십시오.
    //====================================================================================================
	ibExcel.setPageEncoding("UTF-8");

    //====================================================================================================
    // [ 사용자 환경 설정 #2 ]
	//====================================================================================================
	// LoadExcel 용도의 엑셀파일을 업로드하여 임시보관할 임시폴더경로를 지정해 주십시오.
	// 예 : "C:/tmp/"   "/usr/tmp/"
	//====================================================================================================
	
	InetAddress local = InetAddress.getLocalHost();

	String ip = local.getHostAddress();

	System.out.println("LoadExcel.jsp ip --> " + ip);

	
	if( ip.equals("172.20.31.51") || ip.equals("172.20.31.52") ) {
		//운영
		ibExcel.setTempFolder("/app/excelTemp/");	
	} else {
		//나머지
		ibExcel.setTempFolder("D:/temp/");
	}

	
    //====================================================================================================
    // [ 사용자 환경 설정 #3 ]
	//====================================================================================================
	// LoadExcel 처리를 허용할 최대 행 수를 설정한다. 
	// 엑셀 데이터가 지정한 행 수보다 많은 경우 메시지를 출력하고 처리가 종료된다.
	//====================================================================================================
	// ibExcel.setMaxRows(100);

    //====================================================================================================
    // [ 사용자 환경 설정 #4 ]
	//====================================================================================================
	// HeaderMatch 사용 시 시트에 있는 헤더가 엑셀에 하나라도 존재하지 않는 경우 오류메시지를 출력하고 데이터를 로딩하지 않을지 여부.
	//====================================================================================================
	// ibExcel.setStrictHeaderMatch(true);

    //====================================================================================================
    // [ 사용자 환경 설정 #5 ]
    //====================================================================================================
    // LoadExcel 처리를 허용할 최대 열 수를 설정한다.
    // 엑셀 데이터가 지정한 열 수보다 많은 경우 메시지를 출력하고 처리가 종료된다.
    //====================================================================================================
    //ibExcel.setMaxColumns(3);

    //====================================================================================================
    // [ 사용자 환경 설정 #6 ]
    //====================================================================================================
    // 엑셀 전문의 MarkupTag Delimiter 사용자 정의 시 설정하세요.
    // 설정 값은 IBSheet7 환경설정(ibsheet.cfg)의 MarkupTagDelimiter 설정 값과 동일해야 합니다. 
    //====================================================================================================
    //IBPacketParser.setMarkupTagDelimiter("[s1]","[s2]","[s3]","[s4]");

    //====================================================================================================
   // [ 사용자 환경 설정 #7 ]
   //====================================================================================================
   // 시트에 포함될 문자열 중 STX(\u0002), ETX(\u0003) 이 포함된 경우에만 설정해주세요.
   // 설정을 원하지 않는 경우 주석처리해주세요.
   // 0 : 시트 구분자로 STX, ETX 문자를 사용합니다. (기본값)
   // 1 : 시트 구분자로 변형된 문자열을 사용합니다. (시트에 설정이 되어 있어야 합니다.)
   //====================================================================================================
	//	IBPacketParser.setDelimMode(0);    

    //20180508
    LoadExcelCallbackInterface callback = new IBSheetLoadExcelCallback(ibExcel);     
    
    boolean bToken = false;
    
	try {

        // 서버에서 병행처리를 허용할 최대 동시 작업 갯수를 설정한다.
        Synchronizer.init(5);
        
        // 싱크 처리 객체로 부터 처리권한을 확인한다.
        // 인자를 true로 설정하는 경우 : 싱크 처리 객체에서 자원을 사용가능해질때까지 최대 30초 동안 기다렸다가 자원 사용이 가능해졌을때 권한을 할당 후 true를 반환한다.
        // 인자를 false로 설정하는 경우 : 자원 사용여부를 확인후 즉시 반환. 사용 가능하면 할당 후 true를 반환하고, 사용이 불가능한 경우 false를 반환한다.
        bToken = Synchronizer.use(false);
        
        // 싱크 객체로 부터 권한을 정상 할당 받은 경우에만 엑셀 작업을 진행한다.
        if (bToken) {

            ibExcel.EventRegistration(callback);
	    
			//엑셀파일 로드
			ibExcel.setData();
	
		    // setData(); 호출 이후 ExtendParam 사용 가능
		    //String exParam = ibExcel.getExtendParam();
	        //System.out.println("exParam [" + exParam + "]");
	        //System.out.println("exParam [" + ibExcel.getExtendParam("TestParam") + "]");
			
			// 서버에 저장된 파일명
			String uploadFileName = ibExcel.getUploadFileName();
			// System.out.println("uploadFileName : " + uploadFileName);

			// TODO
			// 업로드된 엑셀 파일을 가공함 (예, 엑셀문서를 DRM 처리함)
			boolean bret = false;
			boolean nret = false;
			boolean iret = false; 
			int retVal = 0;
			
			//DRM Config Information
			String strFsdinitPath = "";
			
			if( ip.equals("172.20.31.51") || ip.equals("172.20.31.52") ) {
				//운영
				strFsdinitPath = "/app/fsdinit";
			} else {
				//나머지
				strFsdinitPath = "C:/fsdinit";
			}
			
			
			String strCPID = "0000000000011372";
			String strEncFilePath = uploadFileName;
			String strDecFilePath = uploadFileName;
			
			WorkPackager objWorkPackager = new WorkPackager();
			//objWorkPackager.setCharset("eucKR");

			//복호화 된문서가 암호화된 문서를 덮어쓰지 않음
			objWorkPackager.setOverWriteFlag(false);

			retVal = objWorkPackager.GetFileType(strEncFilePath);
			
			System.out.println("파일형태는 " + FileTypeStr(retVal) + "["+retVal+"]"+" 입니다.");

			//대상 문서가 FSN로 암호화 되었을 때만 복호화 실행
			if (retVal == 103) {

				//파일 확장자 체크( IsSupportFile() ) 로직
				iret = objWorkPackager.IsSupportFile(strFsdinitPath,
								strCPID,
								strEncFilePath);
				System.out.println("지원 확장자 체크  : "+ iret );
				
				//지원 확장자의 경우 복호화 진행
				if (iret == true) {
					// 암호화 된 파일 복호화
					bret = objWorkPackager.DoExtract(
											strFsdinitPath,			//fsdinit 폴더 FullPath 설정
											strCPID,				//고객사 Key(default) 
											strEncFilePath,			//복호화 대상 문서 FullPath + FileName
											strDecFilePath			//복호화 된 문서 FullPath + FileName
											);
					
					System.out.println("복호화 결과값 : " + iret);
					System.out.println("복호화 문서 : " + objWorkPackager.getContainerFilePathName());
					System.out.println("오류코드 : " + objWorkPackager.getLastErrorNum());
					System.out.println("오류값 : " + objWorkPackager.getLastErrorStr());
				} else {
					System.out.println("지원 확장자가 아닌경우 복호화 불가능 합니다.["+ iret +"]" + objWorkPackager.getLastErrorStr() + "[" + objWorkPackager.getLastErrorNum() + "[");
					System.out.println("[errCode]errorStr: "+ "[" + objWorkPackager.getLastErrorNum() + "]" + objWorkPackager.getLastErrorStr());
				}
			} else {
				System.out.println("FSN 파일이 아닌경우 복호화 불가능 합니다.["+ retVal + "]");
				System.out.println("[errCode]errorStr: "+ "[" + objWorkPackager.getLastErrorNum() + "]" + objWorkPackager.getLastErrorStr());
			}
			
			// 사용자가 업로드한 파일명
			//String uploadFileNameOrg = ibExcel.getUploadFileNameOrg();

			//IBSheet에 전달할 Json 데이터 출력
			ibExcel.writeToBrowser();
			//엑셀파일의 빈 행을 생략하려면
			//ibExcel.writeToBrowser(true); //형식을 사용한다
			
			
            // 엑셀 업로드 완료 후 싱크 객체로 할당받은 권한을 반환한다.
            Synchronizer.release();
            bToken = false;
        }
        else {
            //LoadExcelError({Code:-4,Msg:'엑셀 다운로드중 에러...'}와 같이, 
            //사용자 정의 에러코드 & 메시지를 정의하면, 
            //Client OnLoadExcel 이벤트 통해서 확인 가능
            out.println("<script>var targetWnd = null; if(opener!=null) {targetWnd = opener;} else {targetWnd = parent;} targetWnd.Grids[0].LoadExcelError({Code:-4,Msg:'엑셀 다운로드중 에러가 발생하였습니다.[Server Busy]'}); </script>");
        }
		
	} catch(Exception e) {
		out.println("<script>var targetWnd = null; if(opener!=null) {targetWnd = opener;} else {targetWnd = parent;} targetWnd.Grids[0].LoadExcelError(); </script>");

		e.printStackTrace();
	} catch (Error e) {
		out.println("<script>try{var targetWnd = null; if(opener!=null) {targetWnd = opener;} else {targetWnd = parent;} targetWnd.Grids[0].LoadExcelError(); }catch(e){}</script>");

		e.printStackTrace();
    } finally {
        //공유자원 반환이 되지 않은 상태라면, 반환 처리한다.
        if (bToken) {
            Synchronizer.release();
            bToken = false;
        }
        
        //Exception 발생 시, response 헤더 별도 설정하도록 한다. 
        response.setContentType("text/html;charset=UTF-8");
        response.setCharacterEncoding("UTF-8");
    }
%>
