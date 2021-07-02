package h5.servlet;

import java.io.ByteArrayOutputStream;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;

import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.WriterException;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;

import h5.security.SeedCipher;

// 2020.10.23 상진 메모 : 추후에 수정 예정
// appl_id 가 들어오면 정상적인 문서인지 DB에서 검사하고
// 안에 QR코드를 만들어주는 내용들이 변경 될 예정이다.

public class QRCTFCert extends HttpServlet  {


	private static final String QR_ENC_KEY = "DWehrQRCode20200914";
	
	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp)
			throws ServletException, IOException {
		doPost(req , resp);
	}
	
	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		String width = (String)request.getParameter("width");
		String height = (String)request.getParameter("height");
		
		//세션정보
		String issue_no = request.getParameter("issue_no");
		
		//세션정보
		HttpSession session = request.getSession();
		String sessionEmpNo = (String)session.getAttribute("session_emp_no");
		String sessionCompanyCd = (String)session.getAttribute("session_company_cd");
		
		//현재날짜 
		Date now = new Date();
		SimpleDateFormat formatDate = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		String nowDate = formatDate.format(now);
		
		try{
			//암호화 
			SeedCipher sc = new SeedCipher();
			 
			// 바코드내부에 들어갈 내용
			StringBuffer sb = new StringBuffer();
			
			//2021.04.16 상진 : 운영 도메인 나와 반영  
			//운영 서버 API URL 
			String apiURL = "https://hrapi.dongwon.com/api/cert/checkYourDoc?req_issue_no="+issue_no;
			//개발 서버 API URL  
			//String apiURL = "http://172.20.16.40:11081/api/cert/checkYourCert?appl_id="+reqApplId;
			//로컬 테스트 
			//String apiURL = "http://localhost:8080/api/cert/checkYourCert?appl_id="+reqApplId;
			
			System.out.println("issue_no" + issue_no);
			
			sb.append("BEGIN:VCARD\r\n");
			sb.append("VERSION:4.0\r\n");
			sb.append("URL:" + apiURL + ";\r\n");
			sb.append("END:VCARD");
			
			//내부 바코드 내용 전체 암호화 처리
			StringBuffer sb2 = new StringBuffer();
			sb2.append(sc.encryptAsString( sb.toString(), QR_ENC_KEY.getBytes(), "UTF-8"));
			
			response.setContentType("image/jpeg");
			
			//QR Code 생성
			QRCodeWriter qrCodeWriter = new QRCodeWriter();
			//BitMatrix bitMatrix = qrCodeWriter.encode(new String(sb2.toString().getBytes("UTF-8"), "ISO-8859-1"), BarcodeFormat.QR_CODE, Integer.parseInt(width), Integer.parseInt(height));
			//테스트용으로 할때 
			BitMatrix bitMatrix = qrCodeWriter.encode(apiURL, BarcodeFormat.QR_CODE, Integer.parseInt(width), Integer.parseInt(height));
			
			ServletOutputStream outputStream = response.getOutputStream();
			MatrixToImageWriter.writeToStream(bitMatrix, "png", outputStream);
			outputStream.flush();
			outputStream.close();
			
		}catch(Exception e){
			e.printStackTrace();
			System.out.println(e.getMessage());
			writeNoImage(response);
		}
		
	}
	
	/**
	 * 이미지 없음에 대한 이미지를 출력함.
	 * @param response
	 */
	public void writeNoImage(HttpServletResponse response){
		try{
			response.sendRedirect("/noImage.png");
		}catch(IOException e){
			e.printStackTrace();
		}
	}
	
	
	private static void generateQRCodeImage(String bs, int width, int height) throws WriterException, IOException{
		QRCodeWriter qrCodeWriter = new QRCodeWriter();
		try{
			BitMatrix bitMatrix = qrCodeWriter.encode(new String(bs.getBytes("UTF-8"),"ISO-8859-1"), BarcodeFormat.QR_CODE, width, height);
			MatrixToImageWriter.writeToStream(bitMatrix, "png", new FileOutputStream(new File("qrcode.png")));
			
		}catch(Exception e){
			e.printStackTrace();
		}
	}
	
	private byte[] getQRCodeImageByteArray(String text, int width, int height) throws WriterException, IOException{
		QRCodeWriter qrCodeWriter = new QRCodeWriter();
		BitMatrix bitMatrix = qrCodeWriter.encode(text, BarcodeFormat.QR_CODE, width, height);
		
		ByteArrayOutputStream pngOutputStream  = new ByteArrayOutputStream();
		MatrixToImageWriter.writeToStream(bitMatrix, "PNG", pngOutputStream);
		byte[] pngData = pngOutputStream.toByteArray();
		return pngData;
	}
}
