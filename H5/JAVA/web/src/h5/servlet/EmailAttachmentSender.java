package h5.servlet;

import java.io.IOException;
import java.util.Date;
import java.util.Properties;

import javax.activation.DataHandler;
import javax.activation.FileDataSource;
import javax.mail.Address;
import javax.mail.BodyPart;
import javax.mail.Message;
import javax.mail.Multipart;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeBodyPart;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeMultipart;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class EmailAttachmentSender extends HttpServlet {

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp)
			throws ServletException, IOException {
		doPost(req , resp);
	}
	
	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		
//		String fileName = (String)request.getAttribute("fileName");
//		String filePath = (String)request.getAttribute("filePath");
//		String send_emp_id = (String)request.getAttribute("send_emp_id");
//		String send_emp_nm = (String)request.getAttribute("send_emp_nm");
//		String title = (String)request.getAttribute("title");
//		String recv_emp_id = (String)request.getAttribute("recv_emp_id");
		
//		String to = null;
//		String from = null;
//		String content = null;
//		
//		System.out.println("fileName : " + fileName );
//		System.out.println("filePath : " + filePath );
//		System.out.println("send_emp_id : " + send_emp_id );
//		System.out.println("send_emp_nm : " + send_emp_nm );
//		System.out.println("title : " + title );
//		System.out.println("fileName : " + fileName );
//		System.out.println("recv_emp_id : " + recv_emp_id );
		
//		Connection con = null;
//	    PreparedStatement ps = null;
//	    ResultSet rs = null;
//	    
//	    try {
//	    	
//	    	
//	    } catch (Exception e) {
//	    	e.printStackTrace();
//			throw e;
//	    } finally{
//			
//			
//			if(rs != null) rs.close();
//			if(ps != null) ps.close();
//			if(con != null) con.close();
//		}
		
		
		String to = "sjoh@win.co.kr";
		String from = "ehr@dongwon.com";
		String content = "내용";
		String title = "타이틀";
	    
	    // 이메일 전송 로직 
		Properties properties = System.getProperties();
		properties.put("mail.smtp.host", "172.20.18.13");
		properties.put("mail.smtp.port", "25");
		properties.put("mail.smtp.auth", "false");
		System.out.println(properties);
		Session session = Session.getInstance(properties);
		
		try{
	        MimeMessage message = new MimeMessage(session);
	        message.setFrom((Address) new InternetAddress(from));
			message.addRecipient(Message.RecipientType.TO, (Address) new InternetAddress(to));
			message.setSubject(title); 
			message.setSentDate(new Date());					
								
			BodyPart messageBodyPart = new MimeBodyPart();
			messageBodyPart.setContent("<html>"
					+ "<header>"
					+ 	 "<meta charset='utf-8'>"
					+ "</header>"
					+ "<body>"
					+ "		<center>"
					+ "		<div style='width:500px;margin-top:5px;margin-bottom:5px;border-top:1px solid grey;border-bottom : 1px solid grey;'>"
					+ "			<div style='text-align:center; width:100%;border-bottom: 1px solid lightgrey;padding-top:20px;'>"
					+ "             <div style='text-align:left;'>"
					+ " 				<img style='width: 165px;' src='https://hrapp.dongwon.com/common/images/common/main_logo.png'></img> "		
					+ " 			</div>	"
					+ "             <br/> "
					+ "             <br/> "
					+ "             <br/> "
					+ " 			<br/> "		
					+ " 			<br/> "		
					+ " 			<br/> "		
					+ " 			<div style='min-height: 300px; padding: 1px; margin-top:50px;'>"
					+ 					content
					+ " 			</div> "
					+ " 			<div style='background-color:#F8F8FF; text-align:center; padding:4px; color:grey; font-size: 10px;'> "
					+ "					&nbsp;본 메일은 발신전용이며, 문의에 대한 회신은 처리되지 않습니다. <br/> "
					+ "                 Copyright ⓒ Dongwon Enterprise Corp. All rights reserved.  "
					+ "   			</div> "
					+ " 		</div>"		
					+ "		</div>"
					+ "		</center>"
					+ "</body>"
				+ "</html> ", "text/html; charset=UTF-8"
					);
			
			
			messageBodyPart.setContent("test", "text/html; charset=UTF-8");
			
			Multipart multipart = new MimeMultipart();
			multipart.addBodyPart(messageBodyPart);
			
			message.setContent(multipart);	
			
			Transport.send((Message) message);
		} catch(Exception e){
			e.printStackTrace();
		}
	}
	
	/*
	 * //host, port, mailFrom, mailTo, subject, message public static void
	 * sendEmailWithAttachments() {
	 * 
	 * }
	 * 
	 * public static void main(String[] args) { // SMTP info
	 * sendEmailWithAttachments(); }
	 */
}