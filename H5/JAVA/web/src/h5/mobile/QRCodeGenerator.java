package h5.mobile;

import h5.security.SeedCipher;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
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
import java.text.SimpleDateFormat;
import java.util.Date;

public class QRCodeGenerator extends HttpServlet{


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
		HttpSession session = request.getSession();
		String sessionEmpNo = (String)session.getAttribute("session_emp_no");
		String sessionCompanyCd = (String)session.getAttribute("session_company_cd");
		String sessionOrgNm = (String)session.getAttribute("session_org_nm");
		
		//현재날짜
		Date now = new Date();
		SimpleDateFormat formatDate = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		String nowDate = formatDate.format(now);
		
		try{
			//암호화 
			SeedCipher sc = new SeedCipher();
			
			// 바코드내부에 들어갈 내용
			StringBuffer sb = new StringBuffer();
			sb.append("BEGIN:VCARD\r\n");
			sb.append("VERSION:4.0\r\n");
			sb.append("N:"+sessionEmpNo+";\r\n");
//			sb.append("N:"+sessionOrgNm+";\r\n");
			sb.append("N:"+sessionCompanyCd+";\r\n");
			sb.append("REV:"+nowDate+";\r\n");
			sb.append("END:VCARD");
			
			//내부 바코드 내용 전체 암호화 처리
			StringBuffer sb2 = new StringBuffer();
			//암호화 사용할경우 아래 코드 주석풀어서 사용하면 됨.
			//sb2.append(sc.encryptAsString( sb.toString(), QR_ENC_KEY.getBytes(), "UTF-8"));
			sb2.append( sb.toString());
			response.setContentType("image/jpeg");
			
			//QR Code 생성
			QRCodeWriter qrCodeWriter = new QRCodeWriter();
			//암호화 사용할경우 아래 코드 주석풀어서 사용하면 됨.
			//BitMatrix bitMatrix = qrCodeWriter.encode(new String(sb2.toString().getBytes("UTF-8"), "ISO-8859-1")
			//				, BarcodeFormat.QR_CODE, Integer.parseInt(width), Integer.parseInt(height));
			BitMatrix bitMatrix = qrCodeWriter.encode(sb2.toString(), BarcodeFormat.QR_CODE, Integer.parseInt(width), Integer.parseInt(height));
			
			ServletOutputStream outputStream = response.getOutputStream();
			MatrixToImageWriter.writeToStream(bitMatrix, "png", outputStream);
			outputStream.flush();
			outputStream.close();
			
		}catch(Exception e){
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
