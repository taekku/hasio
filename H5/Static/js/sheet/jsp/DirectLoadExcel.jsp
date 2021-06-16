<%@ page language="java" contentType="text/html;charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.io.*" %>
<%@ page import="com.ibleaders.ibsheet7.ibsheet.excel.DirectLoadExcel" %>
<%@ page import="com.ibleaders.ibsheet7.util.Synchronizer" %>
<%@ page import="com.ibleaders.ibsheet7.util.IBPacketParser" %>
<%

	out.clear();
    out = pageContext.pushBody();

	DirectLoadExcel ibExcel = new DirectLoadExcel();
	ibExcel.setService(request, response);

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
	ibExcel.setTempFolder("d:/");

    //====================================================================================================
    // [ 사용자 환경 설정 #3 ]
	//====================================================================================================
	// 값이 없는 컬럼인 경우 List 의 Map 에 Key 값을 포함할지를 설정한다
	// true 인경우 Key 가 포함되며, false(기본값) 인경우 Key 를 포함하지 않는다.
	//====================================================================================================
	ibExcel.setNull2Blank(false);

    //====================================================================================================
    // [ 사용자 환경 설정 #4 ]
    //====================================================================================================
    // 엑셀 전문의 MarkupTag Delimiter 사용자 정의 시 설정하세요.
    // 설정 값은 IBSheet7 환경설정(ibsheet.cfg)의 MarkupTagDelimiter 설정 값과 동일해야 합니다. 
    //====================================================================================================
    //IBPacketParser.setMarkupTagDelimiter("[s1]","[s2]","[s3]","[s4]");

    //====================================================================================================
    // [ 사용자 환경 설정 #5 ]
    //====================================================================================================
    // LoadExcel 처리를 허용할 최대 행 수를 설정한다.
    // 엑셀 데이터가 지정한 행 수보다 많은 경우 메시지를 출력하고 처리가 종료된다.
    //====================================================================================================
    // ibExcel.setMaxRows(100);

    //====================================================================================================
    // [ 사용자 환경 설정 #6 ]
    //====================================================================================================
    // 시트에 포함될 문자열 중 STX(\u0002), ETX(\u0003) 이 포함된 경우에만 설정해주세요.
    // 설정을 원하지 않는 경우 주석처리해주세요.
    // 0 : 시트 구분자로 STX, ETX 문자를 사용합니다. (기본값)
    // 1 : 시트 구분자로 변형된 문자열을 사용합니다. (시트에 설정이 되어 있어야 합니다.)
    //====================================================================================================
	//	ibExcel.setDelimMode(0);
	
	//====================================================================================================
	// [ 사용자 환경 설정 #7 ]
	//====================================================================================================
	// 엑셀의 비어있는 행도 로드하도록 설정합니다.
	// false로 설정하는 경우 비어있는 행을 로드하고, true인 경우에는 비어있는 행을 건너뜁니다.
	// 시트의 DirectLoadExcel({ SkipEmptyRow  : false }); 옵션과 동일하게 작동합니다.
	// DirectLoadExcel에서 StartRow를 설정한 경우, 해당 행은 검사하지 않습니다.
	//====================================================================================================
	//ibExcel.setSkipEmptyRow(false);
    
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
			
			//엑셀파일 로드
			ibExcel.setData();
	
			// 서버에 저장된 파일명
			//String uploadFileName = ibExcel.getUploadFileName();
			// System.out.println("uploadFileName : " + uploadFileName);

			// TODO
			// 업로드된 엑셀 파일을 가공함 (예, 엑셀문서를 DRM 처리함)

			// 사용자가 업로드한 파일명
			//String uploadFileNameOrg = ibExcel.getUploadFileNameOrg();
			
			//데이터를 Json 형태로 사용하려면 String 형식으로 리턴받아 사용한다.
			//String excelData = ibExcel.directLoadExcelFile();

			//엑셀의 데이터를 Json 형태로 ExtendParam의 FP로 설정된 URL에 전달
			// sheet.DirectLoadExcel({ExtendParam:"FP=./fp_load.jsp"}) 형식으로 FP를 설정한다.
			// 전달된 데이터는 해당 URL 에서 request.getAttribute("SHEETDATA") 로 확인할 수 있다.
			ibExcel.directLoad();
			
            // 엑셀 업로드 완료 후 싱크 객체로 할당받은 권한을 반환한다.
            Synchronizer.release();
            bToken = false;
        } else {
            //LoadExcelError({Code:-4,Msg:'엑셀 다운로드중 에러...'}와 같이, 
            //사용자 정의 에러코드 & 메시지를 정의하면, 
            //Client OnLoadExcel 이벤트 통해서 확인 가능
            //out.println("<script>var targetWnd = null; if(opener!=null) {targetWnd = opener;} else {targetWnd = parent;} targetWnd.Grids[0].LoadExcelError({Code:-4,Msg:'엑셀 다운로드중 에러가 발생하였습니다.[Server Busy]'}); </script>");
            OutputStream out2 = response.getOutputStream();
            out2.write(("<script>var targetWnd = null; if(opener!=null) {targetWnd = opener;} else {targetWnd = parent;} targetWnd.Grids[0].LoadExcelError({Code:-4,Msg:'엑셀 다운로드중 에러가 발생하였습니다.[Server Busy]'}); </script>").getBytes("UTF-8"));
            out2.flush();
        }
        
    } catch(Exception e) {
        //out.println("<script>var targetWnd = null; if(opener!=null) {targetWnd = opener;} else {targetWnd = parent;} targetWnd.Grids[0].LoadExcelError(); </script>");

        //e.printStackTrace();

         //out.print()out.println() 방식으로 메시지가 정상적으로 출력되지 않는다면 다음과 같은 방식을 사용한다.
        OutputStream out2 = response.getOutputStream();
        out2.write(("<script>var targetWnd = null; if(opener!=null) {targetWnd = opener;} else {targetWnd = parent;} targetWnd.Grids[0].LoadExcelError(); </script>").getBytes());
        out2.flush();
        

    } catch (Error e) {
        //out.println("<script>try{var targetWnd = null; if(opener!=null) {targetWnd = opener;} else {targetWnd = parent;} targetWnd.Grids[0].LoadExcelError(); }catch(e){}</script>");
        OutputStream out2 = response.getOutputStream();
        out2.write(("<script>var targetWnd = null; if(opener!=null) {targetWnd = opener;} else {targetWnd = parent;} targetWnd.Grids[0].LoadExcelError(); </script>").getBytes());
        out2.flush();

        //e.printStackTrace();
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
