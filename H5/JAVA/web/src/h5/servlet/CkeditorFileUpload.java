package h5.servlet;

import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.sql.DataSource;

import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;
import org.apache.commons.fileupload.servlet.ServletFileUpload;
import org.json.simple.JSONObject;

import com.win.frame.server.ServerConfig;
import com.win.frame.server.ServerConfigFactory;
import com.win.rf.config.ConfigurationManager;
import com.win.rf.config.IConfigurationInfoProvider;

import h5.security.SeedCipher;
import h5.servlet.util.DWFileUtil;

public class CkeditorFileUpload extends HttpServlet {

	
	private static final int BYTE = 1024;

	private static final int KILOBYTE = 1024;

	private static final int MEMORY_THRESHOLD = BYTE * KILOBYTE * 3; // 3MB memory buffer

	private static final int MAX_FILE_SIZE = BYTE * KILOBYTE * 40; // 40MB 가장 큰 파일 용량
	
	private static final int MAX_REQUEST_SIZE = BYTE * KILOBYTE * 50; // client에서 server로 전송 되는 request의 총 용량

	private static final String TEMP_STROAGE = "C:\\FILEUPLOAD";

	
	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		doPost(request, response);
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		
		response.setCharacterEncoding("utf-8");
		response.setContentType("text/html;charset=utf-8");
		
		if( !ServletFileUpload.isMultipartContent(request) ) { //TODO // 클라이언트에서 서버로 전송하는 방식이 multipart type 이 아니다. 
		
		}
		
		DiskFileItemFactory factory = new DiskFileItemFactory();
		
		factory.setSizeThreshold(MEMORY_THRESHOLD);
		factory.setRepository(new File(TEMP_STROAGE));


		ServletFileUpload upload = new ServletFileUpload(factory);
		upload.setFileSizeMax(MAX_FILE_SIZE); // 가장 큰 파일 사이즈 설정

		upload.setSizeMax(MAX_REQUEST_SIZE); // 총 request의 사이즈 설정
		
		try {
			
			HttpSession session = request.getSession();

			String session_emp_id = (String) session.getAttribute("session_emp_id");
			
			SeedCipher s_sc = new SeedCipher();
			String s_session_id = (String)session.getAttribute("session_id");
			session_emp_id = s_sc.decryptAsString(session_emp_id, s_session_id.getBytes(), "UTF-8");  // 복호화 해서 문자로 받기

			
			List formItems = upload.parseRequest(request);

			if (formItems != null && formItems.size() > 0) {

				for ( int i = 0 ; i < formItems.size(); i++ ) {

					FileItem item = (FileItem) formItems.get(i);
					
					if (!item.isFormField()) {
						String fileName = item.getName();
						
						//System.out.println("fileName : " + fileName );
						
						DWFileUtil dwFileUtil = new DWFileUtil();
						PrintWriter writer = response.getWriter();
						JSONObject obj = new JSONObject();
						try {
							ServerConfig sConfig = ServerConfigFactory.getServerConfig();
							IConfigurationInfoProvider config = ConfigurationManager.getConfigurationInfoProvider();
						
							String jdbcJndiPrefix = sConfig.getConfigValue("jdbcJndiPrefix");
							String jdbcJndiName = jdbcJndiPrefix + config.getItem("h5prd.jdbc.jndi").getValue();
						
							Context ctx = new InitialContext();
							DataSource ds = (DataSource) ctx.lookup(jdbcJndiName);
							dwFileUtil.conn = ds.getConnection();
							dwFileUtil.conn.setAutoCommit(false);
							String fileId = dwFileUtil.uploadFile(item , session_emp_id);
							dwFileUtil.conn.commit();
							
							obj.put("filename", fileName);
							obj.put("uploaded", 1);
							obj.put("url","/ImageViewer?store_type=db&file_id=" + fileId);
							
							writer.println(obj);
							writer.flush();
						} catch( Exception e1 ) {
							
							try {
								
								dwFileUtil.conn.rollback();
							} catch(Exception e2) {}
							
							obj.put("filename", fileName);
							obj.put("uploaded", 0);
							obj.put("url","");
							
							writer.println(obj);
							writer.flush();
						} finally {
							
							if ( dwFileUtil.conn != null ) {
								
								dwFileUtil.conn.close();
							}
							
						}
						//item.write(storeFile);
					}
				}

					
			}
			
		} catch( Exception e ) {
			
		}


	}
}
