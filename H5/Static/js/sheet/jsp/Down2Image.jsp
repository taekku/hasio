<%@ page language="java" contentType="text/html;charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.ibleaders.ibsheet7.ibchart.image.*"%>
<%
    out.clear();
    Down2Image ibChart = new Down2Image(request, response);

    //====================================================================================================
    // [ 사용자 환경 설정 #1 ]
    //====================================================================================================
    // 서버의 임시폴더 설정 : 서버로 IBChart의 이미지 문서를 임시 저장할 경로를 작성합니다.
    //====================================================================================================
    ibChart.setPath("G:");

    //====================================================================================================
    // [ 사용자 환경 설정 #2 ]
    //====================================================================================================
    // Html 페이지의 인코딩이 UTF-8 로 구성되어 있으면 "ibChart.setPageEncoding("UTF-8");" 로 설정합니다.
    // 다운로드 받는 이미지에 한글이 깨지면 이 값을 공백("")으로 바꿔 보십시오.
    // 웹페이지의 charset 과 동일해야 한글이 깨지지 않습니다.
    //====================================================================================================
    ibChart.setPageEncoding("UTF-8");

  	//====================================================================================================
    // [ 사용자 환경 설정 #3 ]
    //====================================================================================================
    // Hml 파일 다운로드의 경우에 용지 방향을 가로/세로로 설정합니다.
    // true : 가로, false : 세로
    //====================================================================================================
    ibChart.setLandscape(false);
    
    /*
        처리방법 #1
        - 이미지 다운로드에 대한 일련의 작업 처리
    */
    ibChart.down2Image();

    /*
        처리방법 #2
        - 서버에 이미지 파일 저장과 다운로드들 위한 Response 처리에 대한 절차 분기 처리 

            @method     makeImage
            @param      {string}    fileName    저장할 이미지 파일명 (빈값인 경우 request에서 지정한 파일명으로 사용)
            @returns    {string}                이미지 Full Path
    */

    //String path = ibChart.makeImage("");
    //ibChart.sendImage(path);

    /*
        처리방법 #3
        - svg 마크업 문자열을 이미지로 변환하여 서버에 저장 처리

            @method     svg2Image
            @param      {string}    svg         svg 마크업 문자열
            @param      {string}    path        임시경로
            @param      {string}    fileName    파일명
            @param      {string}    imageType   이미지타입 (PNG:"image/png", JPEG:"image/jpeg", PDF:"application/pdf")
            @param      {float}     imageWidth  이미지너비
            @returns    {string}                이미지 Full Path
    */
    //ibChart.svg2Image(arSVG[i], "G:", fileName, "image/jpeg", 800f);

    // 파일 정상 다운로드시 아래 구문을 실행하지 않으면 서버 Servlet에서  java.lang.IllegalStateException 이 발생한다.
    // 파일 최 하단에서 호출하도록 하면 다운로드 에러로 인한 Exception 메시지가 출력되지 않으므로 정상 다운시에만 처리하도록 한다.
    // out.flush();
    // out = pageContext.pushBody();

%>